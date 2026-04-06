# Step 2: Query Azure DevOps for Automation Status
# Self-contained script. Reads step1 state, queries DevOps, writes output JSON.
# Usage: .\step2-query-devops.ps1 -StateDir "path\state" -DevOpsOrg "org" -DevOpsProject "proj"
param(
    [Parameter(Mandatory)] [string] $StateDir,
    [Parameter(Mandatory)] [string] $DevOpsOrg,
    [Parameter(Mandatory)] [string] $DevOpsProject
)

$ErrorActionPreference = 'Stop'

# Read step1 state
$step1File = Join-Path $StateDir "step1-scan.json"
if (-not (Test-Path $step1File)) { Write-Error "step1-scan.json not found in $StateDir. Run step1 first."; exit 1 }
$step1 = Get-Content $step1File -Raw | ConvertFrom-Json
$uniqueIDs = @($step1.uniqueIDs)
$results = @($step1.results)

Write-Host "Step 2: Querying Azure DevOps ($DevOpsOrg/$DevOpsProject) for $($uniqueIDs.Count) unique IDs..."

# 2a. Verify Azure CLI authentication
$authCheck = az account show 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "Azure CLI not authenticated. Run 'az login' first."; exit 1 }
Write-Host "  Azure CLI authenticated."

# 2b. Fetch bearer token
$token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$tokenFetchedAt = Get-Date
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
Write-Host "  Token acquired."

# Batch query (up to 200 IDs per call)
$batches = [System.Collections.Generic.List[int[]]]::new()
for ($i = 0; $i -lt $uniqueIDs.Count; $i += 200) {
    $end = [math]::Min($i + 199, $uniqueIDs.Count - 1)
    $batches.Add([int[]]$uniqueIDs[$i..$end])
}

$allWorkItems = [System.Collections.Generic.List[object]]::new()
$batchNum = 0

# Helper: sub-split a failed batch into smaller chunks and retry
function Invoke-SubBatches {
    param([int[]]$Ids, [int]$ChunkSize, [string]$Url, [hashtable]$Hdrs)
    $subResults = [System.Collections.Generic.List[object]]::new()
    for ($s = 0; $s -lt $Ids.Count; $s += $ChunkSize) {
        $subEnd = [math]::Min($s + $ChunkSize - 1, $Ids.Count - 1)
        $subBatch = [int[]]$Ids[$s..$subEnd]
        $subBody = @{ ids = $subBatch; fields = @(
            "System.Id", "System.Title", "System.State",
            "Microsoft.VSTS.TCM.AutomationStatus", "Custom.AutomationStatus", "System.WorkItemType"
        )} | ConvertTo-Json -Depth 3
        try {
            $subResult = Invoke-RestMethod -Uri $Url -Headers $Hdrs -Method Post -Body $subBody -ErrorAction Stop
            foreach ($item in $subResult.value) { $subResults.Add($item) }
            Write-Host "      Sub-batch ($($subBatch.Count) IDs): got $($subResult.value.Count) items"
        } catch {
            Write-Host "      Sub-batch ($($subBatch.Count) IDs) failed: $($_.Exception.Message)"
        }
    }
    return $subResults
}

foreach ($batch in $batches) {
    $batchNum++
    Write-Host "  Querying batch $batchNum/$($batches.Count) ($($batch.Count) IDs)..."
    $body = @{ ids = $batch; fields = @(
        "System.Id", "System.Title", "System.State",
        "Microsoft.VSTS.TCM.AutomationStatus", "Custom.AutomationStatus", "System.WorkItemType"
    )} | ConvertTo-Json -Depth 3
    $url = "https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_apis/wit/workitemsbatch?api-version=7.1"

    try {
        $batchResult = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body -ErrorAction Stop
        foreach ($item in $batchResult.value) { $allWorkItems.Add($item) }
        Write-Host "    Got $($batchResult.value.Count) items"
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "    Token expired, refreshing..."
            $token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
            $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
            $batchResult = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body -ErrorAction Stop
            foreach ($item in $batchResult.value) { $allWorkItems.Add($item) }
            Write-Host "    Got $($batchResult.value.Count) items (after refresh)"
        } elseif ($statusCode -eq 404) {
            Write-Host "    Batch returned 404 — sub-splitting into chunks of 50..."
            $subResults = Invoke-SubBatches -Ids $batch -ChunkSize 50 -Url $url -Hdrs $headers
            foreach ($item in $subResults) { $allWorkItems.Add($item) }
            Write-Host "    Recovered $($subResults.Count) items from sub-batches"
        } else {
            Write-Host "    Batch API error (HTTP $statusCode) — sub-splitting into chunks of 50..."
            $subResults = Invoke-SubBatches -Ids $batch -ChunkSize 50 -Url $url -Hdrs $headers
            foreach ($item in $subResults) { $allWorkItems.Add($item) }
            Write-Host "    Recovered $($subResults.Count) items from sub-batches"
        }
    }
}

Write-Host "  Total work items returned: $($allWorkItems.Count)"

# 2c. Categorize results
$automated = [System.Collections.Generic.List[object]]::new()
$nonAutomated = [System.Collections.Generic.List[object]]::new()
$manualItems = [System.Collections.Generic.List[object]]::new()
$mismatchItems = [System.Collections.Generic.List[object]]::new()
$notTestCase = [System.Collections.Generic.List[object]]::new()

foreach ($wi in $allWorkItems) {
    $id = $wi.id
    $title = $wi.fields.'System.Title'
    $state = $wi.fields.'System.State'
    $tcmStatus = $wi.fields.'Microsoft.VSTS.TCM.AutomationStatus'
    $customStatus = $wi.fields.'Custom.AutomationStatus'
    $wiType = $wi.fields.'System.WorkItemType'
    $entry = @{ ID=$id; Title=$title; State=$state; TCM=$tcmStatus; Custom=$customStatus; Type=$wiType }

    if ($tcmStatus -eq 'Manual' -or $customStatus -eq 'Manual') {
        $manualItems.Add($entry); continue
    }
    if ($wiType -ne 'Test Case') { $notTestCase.Add($entry) }

    if ($tcmStatus -eq 'Automated' -and $customStatus -eq 'Automated') {
        $automated.Add($entry)
    } elseif (($tcmStatus -eq 'Automated' -and $customStatus -ne 'Automated') -or ($customStatus -eq 'Automated' -and $tcmStatus -ne 'Automated')) {
        $entry.Remarks = "Mismatch: TCM=$tcmStatus, Custom=$customStatus"
        $mismatchItems.Add($entry)
        $nonAutomated.Add($entry)
    } else {
        $entry.Remarks = ""
        $nonAutomated.Add($entry)
    }
}

# 2d. Cross-reference non-automated items with MCAT files
$nonAutoEntries = [System.Collections.Generic.List[object]]::new()
foreach ($na in $nonAutomated) {
    $matchFiles = @($results | Where-Object { $_.ID -eq [string]$na.ID } | ForEach-Object { $_.File } | Sort-Object -Unique)
    foreach ($f in $matchFiles) {
        $remarks = $na.Remarks
        if ($na.Type -ne 'Test Case') { $remarks = if ($remarks) { "$remarks; PBI not test case" } else { "PBI not test case" } }
        $nonAutoEntries.Add(@{
            File=$f; ID=$na.ID; Title=$na.Title;
            AutomationStatus="TCM=$($na.TCM), Custom=$($na.Custom)"; State=$na.State; Remarks=$remarks
        })
    }
}

# 2e. Find IDs not returned by DevOps
$returnedIDs = @($allWorkItems | ForEach-Object { $_.id })
$notFoundIDs = @($uniqueIDs | Where-Object { $_ -notin $returnedIDs })

# Write state
$state = @{
    automated       = @($automated)
    nonAutomated    = @($nonAutomated)
    nonAutoEntries  = @($nonAutoEntries)
    manualItems     = @($manualItems)
    mismatchItems   = @($mismatchItems)
    notTestCase     = @($notTestCase)
    notFoundIDs     = $notFoundIDs
    tokenFetchedAt  = $tokenFetchedAt.ToString("o")
}
$outFile = Join-Path $StateDir "step2-devops.json"
$state | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $outFile -Encoding UTF8

Write-Host "`nStep 2 complete. State saved to: $outFile"
Write-Host "  Automated (both fields):  $($automated.Count)"
Write-Host "  Non-automated:            $($nonAutomated.Count)"
Write-Host "  Manual (skipped):         $($manualItems.Count)"
Write-Host "  Mismatch:                 $($mismatchItems.Count)"
Write-Host "  Not Test Case:            $($notTestCase.Count)"
Write-Host "  Not found in DevOps:      $($notFoundIDs.Count)"
