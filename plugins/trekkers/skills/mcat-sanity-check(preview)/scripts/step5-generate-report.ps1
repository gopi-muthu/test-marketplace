# Step 5: Generate Report
# Self-contained script. Reads all state files, builds formatted report, writes to disk.
# Usage: .\step5-generate-report.ps1 -StateDir "path\state" -ReportPath "path\report.txt" -TeamName "Trekkers" -DevOpsOrg "org" -DevOpsProject "proj" [-IncludeTfvc]
param(
    [Parameter(Mandatory)] [string] $StateDir,
    [Parameter(Mandatory)] [string] $ReportPath,
    [Parameter(Mandatory)] [string] $TeamName,
    [Parameter(Mandatory)] [string] $DevOpsOrg,
    [Parameter(Mandatory)] [string] $DevOpsProject,
    [switch] $IncludeTfvc
)

$ErrorActionPreference = 'Stop'

# Read state files
$step1File = Join-Path $StateDir "step1-scan.json"
$step4File = Join-Path $StateDir "step4-retry.json"
if (-not (Test-Path $step1File)) { Write-Error "step1-scan.json not found."; exit 1 }
if (-not (Test-Path $step4File)) { Write-Error "step4-retry.json not found."; exit 1 }

$step1 = Get-Content $step1File -Raw | ConvertFrom-Json
$step4 = Get-Content $step4File -Raw | ConvertFrom-Json

$teamFileCount  = $step1.teamFileCount
$totalPairs     = $step1.totalPairs
$uniqueIDs      = @($step1.uniqueIDs)
$noIdFiles      = @($step1.noIdFiles)
$stagingFiles   = @($step1.stagingFiles)
$results        = @($step1.results)

$automated      = @($step4.automated)
$nonAutomated   = @($step4.nonAutomated)
$nonAutoEntries = @($step4.nonAutoEntries)
$manualItems    = @($step4.manualItems)
$mismatchItems  = @($step4.mismatchItems)
$notTestCase    = @($step4.notTestCase)
$stillNotFound  = @($step4.stillNotFound)

# Optional TFVC state
$tfvcAuthors = @{}
$creatorSummary = @()
$tfvcPathRoot = ""
if ($IncludeTfvc) {
    $step3File = Join-Path $StateDir "step3-tfvc.json"
    if (Test-Path $step3File) {
        $step3 = Get-Content $step3File -Raw | ConvertFrom-Json
        $step3.tfvcAuthors.PSObject.Properties | ForEach-Object { $tfvcAuthors[$_.Name] = $_.Value }
        $creatorSummary = @($step3.creatorSummary)
        $tfvcPathRoot = $step3.tfvcPathRoot
    }
}

Write-Host "Step 5: Generating report..."

# See references/report-format.md for section layout
$date = Get-Date -Format "yyyy-MM-dd"
$autoCount = $automated.Count
$nonAutoUniqueIDs = @($nonAutomated | ForEach-Object { $_.ID } | Sort-Object -Unique).Count
$nonAutoUniqueFiles = @($nonAutoEntries | ForEach-Object { $_.File } | Sort-Object -Unique).Count
$totalWithStatus = $autoCount + $nonAutoUniqueIDs
$autoPercent = if ($totalWithStatus -gt 0) { [math]::Round(($autoCount / $totalWithStatus) * 100, 1) } else { 0 }

$sb = [System.Text.StringBuilder]::new()

# Header
[void]$sb.AppendLine("$TeamName NON-AUTOMATED TEST CASES REPORT")
[void]$sb.AppendLine("Generated: $date")
[void]$sb.AppendLine("=" * 120)
[void]$sb.AppendLine()

# Summary
[void]$sb.AppendLine("SUMMARY")
[void]$sb.AppendLine("-" * 40)
[void]$sb.AppendLine("  Total $TeamName MCAT files scanned:    $teamFileCount")
[void]$sb.AppendLine("  Total file+testcase pairs found:    $totalPairs")
[void]$sb.AppendLine("  Unique test case IDs:               $($uniqueIDs.Count)")
[void]$sb.AppendLine("  Automated (both fields):            $autoCount ($autoPercent%)")
[void]$sb.AppendLine("  Non-automated entries:              $($nonAutoEntries.Count) ($nonAutoUniqueIDs unique IDs, $nonAutoUniqueFiles unique files)")
[void]$sb.AppendLine("  Manual (skipped):                   $($manualItems.Count)")
[void]$sb.AppendLine("  Staging files found:                $($stagingFiles.Count)")
[void]$sb.AppendLine("  Files with no test case link:       $($noIdFiles.Count)")
if ($stillNotFound.Count -gt 0 -and $stillNotFound.Count -le 10) {
    $nfIdList = ($stillNotFound | ForEach-Object { $_.ToString() }) -join ', '
    [void]$sb.AppendLine("  IDs not found in DevOps:            $($stillNotFound.Count) (IDs: $nfIdList)")
} else {
    [void]$sb.AppendLine("  IDs not found in DevOps:            $($stillNotFound.Count)")
}
[void]$sb.AppendLine()

# Non-automated table
$sep = "-" * 62 + "+" + "-" * 10 + "+" + "-" * 56 + "+" + "-" * 16 + "+" + "-" * 19 + "+" + "-" * 45
[void]$sb.AppendLine("REMAINING NON-AUTOMATED TEST CASES (excluding Manual, resolved mismatches, and newly automated)")
[void]$sb.AppendLine($sep)
$hdr = "{0,-62}| {1,-9}| {2,-55}| {3,-15}| {4,-18}| {5}" -f "FileName", "ID", "Title", "Status", "State", "Remarks"
[void]$sb.AppendLine($hdr)
[void]$sb.AppendLine($sep)
foreach ($entry in $nonAutoEntries) {
    $titleStr = if ($entry.Title.Length -gt 55) { $entry.Title.Substring(0, 52) + "..." } else { $entry.Title }
    $row = "{0,-62}| {1,-9}| {2,-55}| {3,-15}| {4,-18}| {5}" -f $entry.File, $entry.ID, $titleStr, $entry.AutomationStatus, $entry.State, $entry.Remarks
    [void]$sb.AppendLine($row)
}
[void]$sb.AppendLine($sep)
[void]$sb.AppendLine()

# Remaining test case links
[void]$sb.AppendLine("REMAINING TEST CASE LINKS")
[void]$sb.AppendLine("-" * 40)
$nonAutoIDs = @($nonAutomated | ForEach-Object { $_.ID } | Sort-Object -Unique)
foreach ($id in $nonAutoIDs) {
    $item = $nonAutomated | Where-Object { $_.ID -eq $id } | Select-Object -First 1
    $note = if ($item.Remarks) { $item.Remarks } else { $item.Title }
    [void]$sb.AppendLine("  ${id}: https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_workitems/edit/$id - $note")
}
[void]$sb.AppendLine()

# Manual test cases
[void]$sb.AppendLine("MANUAL TEST CASES (skipped - not counted)")
[void]$sb.AppendLine("-" * 40)
if ($manualItems.Count -eq 0) {
    [void]$sb.AppendLine("  (none)")
} else {
    foreach ($m in $manualItems) {
        [void]$sb.AppendLine("  $($m.ID): https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_workitems/edit/$($m.ID) - $($m.Title) (Custom.AutomationStatus=$($m.Custom))")
    }
}
[void]$sb.AppendLine()

# Staging files
[void]$sb.AppendLine("STAGING FILES ($($stagingFiles.Count) total)")
[void]$sb.AppendLine("-" * 40)
if ($stagingFiles.Count -eq 0) {
    [void]$sb.AppendLine("  (none)")
} else {
    $i = 0
    foreach ($sf in $stagingFiles) {
        $i++
        $sfResult = $results | Where-Object { $_.File -eq $sf } | Select-Object -First 1
        $sfID = if ($sfResult.ID) { $sfResult.ID } else { "no ID" }
        $isAuto = if ($sfResult.ID -and ($automated | Where-Object { $_.ID -eq [int]$sfResult.ID })) { "Automated" } else { "Non-automated" }
        [void]$sb.AppendLine("  $i. $sf  [staging: true]  ($isAuto, ID: $sfID)")
    }
}
[void]$sb.AppendLine()

# Files with no test case ID
[void]$sb.AppendLine("FILES WITH NO TEST CASE ID ($($noIdFiles.Count) total)")
[void]$sb.AppendLine("-" * 40)
if ($creatorSummary.Count -gt 0) {
    [void]$sb.AppendLine("  Creator Summary: $($creatorSummary -join ', ')")
    [void]$sb.AppendLine("  Source: $tfvcPathRoot (TFVC)")
} else {
    [void]$sb.AppendLine("  Creator lookup: skipped")
}
[void]$sb.AppendLine()
$maxFile = if ($noIdFiles.Count -gt 0) { ($noIdFiles | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum } else { 40 }
$maxAuthor = if ($tfvcAuthors.Count -gt 0) { ($tfvcAuthors.Values | ForEach-Object { (($_ -split '\|')[0]).Length } | Measure-Object -Maximum).Maximum } else { 20 }
$fmt = "  {0,-4}  {1,-$maxFile}  {2,-$maxAuthor}  {3,-10}"
[void]$sb.AppendLine(($fmt -f "#", "File", "Created By", "Date"))
[void]$sb.AppendLine("  " + "-" * ($maxFile + $maxAuthor + 24))
$i = 0
foreach ($nf in $noIdFiles) {
    $i++
    $author = "N/A"
    $dateStr = ""
    if ($tfvcAuthors.ContainsKey($nf)) {
        $parts = $tfvcAuthors[$nf] -split '\|'
        $author = $parts[0]
        $dateStr = if ($parts.Count -gt 1) { try { ([datetime]$parts[1]).ToString("yyyy-MM-dd") } catch { "" } } else { "" }
    }
    [void]$sb.AppendLine(($fmt -f "$i.", $nf, $author, $dateStr))
}
[void]$sb.AppendLine()

# Open issues
[void]$sb.AppendLine("OPEN ISSUES")
[void]$sb.AppendLine("-" * 40)
$issueNum = 0
$hasIssues = $false

if ($stillNotFound.Count -gt 0) {
    $hasIssues = $true
    $issueNum++
    [void]$sb.AppendLine("  $issueNum. $($stillNotFound.Count) test case ID(s) not found in Azure DevOps (may be deleted or in another project):")
    foreach ($nfId in $stillNotFound) {
        [void]$sb.AppendLine("     - ID $nfId: https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_workitems/edit/$nfId")
    }
}
if ($noIdFiles.Count -gt 0) {
    $hasIssues = $true
    $issueNum++
    [void]$sb.AppendLine("  $issueNum. $($noIdFiles.Count) MCAT files have no test case link - need URL added to file header")
}
if ($mismatchItems.Count -gt 0) {
    $hasIssues = $true
    $issueNum++
    [void]$sb.AppendLine("  $issueNum. $($mismatchItems.Count) item(s) have mismatched automation status fields - need sync:")
    foreach ($mm in $mismatchItems) {
        [void]$sb.AppendLine("     - ID $($mm.ID): https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_workitems/edit/$($mm.ID) (TCM=$($mm.TCM), Custom=$($mm.Custom))")
    }
}
if ($notTestCase.Count -gt 0) {
    $hasIssues = $true
    $issueNum++
    [void]$sb.AppendLine("  $issueNum. $($notTestCase.Count) linked ID(s) are not Test Cases - need correct test case IDs:")
    foreach ($ntc in $notTestCase) {
        [void]$sb.AppendLine("     - ID $($ntc.ID): https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_workitems/edit/$($ntc.ID) (Type: $($ntc.Type)) - $($ntc.Title)")
    }
}
if (-not $hasIssues) {
    $issueNum++
    [void]$sb.AppendLine("  (none)")
}

# Write file
$sb.ToString() | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "`nStep 5 complete. Report written to: $ReportPath"
Write-Host "  Automation coverage: $autoPercent% ($autoCount of $totalWithStatus)"

# Output summary JSON for the agent to display
$summary = @{
    reportPath      = $ReportPath
    teamFileCount   = $teamFileCount
    autoCount       = $autoCount
    autoPercent     = $autoPercent
    totalWithStatus = $totalWithStatus
    nonAutoEntries  = $nonAutoEntries.Count
    nonAutoUniqueIDs= $nonAutoUniqueIDs
    manualCount     = $manualItems.Count
    stagingCount    = $stagingFiles.Count
    noIdCount       = $noIdFiles.Count
    notFoundCount   = $stillNotFound.Count
}
$summaryFile = Join-Path $StateDir "summary.json"
$summary | ConvertTo-Json -Depth 3 -Compress | Out-File -FilePath $summaryFile -Encoding UTF8
Write-Host "  Summary saved to: $summaryFile"
