# Step 4: Retry Bad / Not-Found IDs
# Self-contained script. Reads step1+step2 state, retries not-found IDs, writes updated state JSON.
# Usage: .\step4-retry-ids.ps1 -StateDir "path\state" -DevOpsOrg "org" -DevOpsProject "proj"
param(
    [Parameter(Mandatory)] [string] $StateDir,
    [Parameter(Mandatory)] [string] $DevOpsOrg,
    [Parameter(Mandatory)] [string] $DevOpsProject
)

$ErrorActionPreference = 'Stop'

# Read previous state
$step1File = Join-Path $StateDir "step1-scan.json"
$step2File = Join-Path $StateDir "step2-devops.json"
if (-not (Test-Path $step1File)) { Write-Error "step1-scan.json not found."; exit 1 }
if (-not (Test-Path $step2File)) { Write-Error "step2-devops.json not found."; exit 1 }
$step1 = Get-Content $step1File -Raw | ConvertFrom-Json
$step2 = Get-Content $step2File -Raw | ConvertFrom-Json

$notFoundIDs = @($step2.notFoundIDs)
$results = @($step1.results)

if ($notFoundIDs.Count -eq 0) {
    Write-Host "Step 4: No IDs to retry. Skipping."
    # Write pass-through state (copy step2 as step4 + stillNotFound=[])
    $state = @{
        automated      = @($step2.automated)
        nonAutomated   = @($step2.nonAutomated)
        nonAutoEntries = @($step2.nonAutoEntries)
        manualItems    = @($step2.manualItems)
        mismatchItems  = @($step2.mismatchItems)
        notTestCase    = @($step2.notTestCase)
        stillNotFound  = @()
    }
    $outFile = Join-Path $StateDir "step4-retry.json"
    $state | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $outFile -Encoding UTF8
    exit 0
}

Write-Host "Step 4: Retrying $($notFoundIDs.Count) not-found IDs..."

# Get fresh token
$token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# Batch retry
$retryBatches = [System.Collections.Generic.List[int[]]]::new()
for ($i = 0; $i -lt $notFoundIDs.Count; $i += 200) {
    $end = [math]::Min($i + 199, $notFoundIDs.Count - 1)
    $retryBatches.Add([int[]]$notFoundIDs[$i..$end])
}

$retryResults = [System.Collections.Generic.List[object]]::new()
$batchNum = 0

foreach ($batch in $retryBatches) {
    $batchNum++
    Write-Host "  Retry batch $batchNum/$($retryBatches.Count) ($($batch.Count) IDs)..."
    $body = @{ ids = $batch; fields = @(
        "System.Id", "System.Title", "System.State",
        "Microsoft.VSTS.TCM.AutomationStatus", "Custom.AutomationStatus", "System.WorkItemType"
    )} | ConvertTo-Json -Depth 3
    $url = "https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_apis/wit/workitemsbatch?api-version=7.1"

    try {
        $batchResult = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $body -ErrorAction Stop
        foreach ($item in $batchResult.value) { $retryResults.Add($item) }
        Write-Host "    Got $($batchResult.value.Count) items"
    } catch {
        Write-Host "    Batch failed: $($_.Exception.Message). Sub-splitting into chunks of 25..."
        # Sub-split failed batch into smaller chunks instead of individual calls
        for ($s = 0; $s -lt $batch.Count; $s += 25) {
            $subEnd = [math]::Min($s + 24, $batch.Count - 1)
            $subBatch = [int[]]$batch[$s..$subEnd]
            $subBody = @{ ids = $subBatch; fields = @(
                "System.Id", "System.Title", "System.State",
                "Microsoft.VSTS.TCM.AutomationStatus", "Custom.AutomationStatus", "System.WorkItemType"
            )} | ConvertTo-Json -Depth 3
            try {
                $subResult = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $subBody -ErrorAction Stop
                if ($subResult.value) {
                    foreach ($item in $subResult.value) { $retryResults.Add($item) }
                    Write-Host "      Sub-batch ($($subBatch.Count) IDs): got $($subResult.value.Count) items"
                }
            } catch {
                Write-Host "      Sub-batch ($($subBatch.Count) IDs) failed — trying individually..."
                foreach ($id in $subBatch) {
                    try {
                        $singleBody = @{ ids = @([int]$id); fields = @(
                            "System.Id", "System.Title", "System.State",
                            "Microsoft.VSTS.TCM.AutomationStatus", "Custom.AutomationStatus", "System.WorkItemType"
                        )} | ConvertTo-Json -Depth 3
                        $singleResult = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body $singleBody -ErrorAction Stop
                        if ($singleResult.value) { foreach ($item in $singleResult.value) { $retryResults.Add($item) } }
                    } catch { }
                }
            }
        }
    }
}

Write-Host "  Retry returned: $($retryResults.Count) items"

# Reconcile into existing arrays (deep copy from step2)
$automated = [System.Collections.Generic.List[object]]::new(@($step2.automated))
$nonAutomated = [System.Collections.Generic.List[object]]::new(@($step2.nonAutomated))
$nonAutoEntries = [System.Collections.Generic.List[object]]::new(@($step2.nonAutoEntries))
$manualItems = [System.Collections.Generic.List[object]]::new(@($step2.manualItems))
$mismatchItems = [System.Collections.Generic.List[object]]::new(@($step2.mismatchItems))
$notTestCase = [System.Collections.Generic.List[object]]::new(@($step2.notTestCase))

foreach ($wi in $retryResults) {
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
        $matchFiles = @($results | Where-Object { $_.ID -eq [string]$id } | ForEach-Object { $_.File } | Sort-Object -Unique)
        foreach ($f in $matchFiles) {
            $nonAutoEntries.Add(@{
                File=$f; ID=$id; Title=$title; AutomationStatus="Mismatch: TCM=$tcmStatus, Custom=$customStatus"; State=$state; Remarks="Fields out of sync"
            })
        }
    } else {
        $entry.Remarks = ""
        $nonAutomated.Add($entry)
        $matchFiles = @($results | Where-Object { $_.ID -eq [string]$id } | ForEach-Object { $_.File } | Sort-Object -Unique)
        foreach ($f in $matchFiles) {
            $nonAutoEntries.Add(@{
                File=$f; ID=$id; Title=$title; AutomationStatus="TCM=$tcmStatus, Custom=$customStatus"; State=$state; Remarks=""
            })
        }
    }
}

$retryReturnedIDs = @($retryResults | ForEach-Object { $_.id })
$stillNotFound = @($notFoundIDs | Where-Object { $_ -notin $retryReturnedIDs })

# Write state
$state = @{
    automated      = @($automated)
    nonAutomated   = @($nonAutomated)
    nonAutoEntries = @($nonAutoEntries)
    manualItems    = @($manualItems)
    mismatchItems  = @($mismatchItems)
    notTestCase    = @($notTestCase)
    stillNotFound  = $stillNotFound
}
$outFile = Join-Path $StateDir "step4-retry.json"
$state | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $outFile -Encoding UTF8

Write-Host "`nStep 4 complete. State saved to: $outFile"
Write-Host "  Resolved:       $($retryResults.Count) of $($notFoundIDs.Count)"
Write-Host "  Still not found: $($stillNotFound.Count)"
Write-Host "  Automated:       $($automated.Count)"
Write-Host "  Non-automated:   $($nonAutomated.Count)"
Write-Host "  Manual:          $($manualItems.Count)"
