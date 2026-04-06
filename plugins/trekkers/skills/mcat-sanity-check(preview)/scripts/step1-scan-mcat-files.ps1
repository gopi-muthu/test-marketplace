# Step 1: Scan MCAT Files
# Self-contained script. Accepts parameters, writes output to JSON state file.
# Usage: .\step1-scan-mcat-files.ps1 -McatRoot "path" -TeamName "Trekkers" -StateDir "path\state"
param(
    [Parameter(Mandatory)] [string] $McatRoot,
    [Parameter(Mandatory)] [string] $TeamName,
    [Parameter(Mandatory)] [string] $StateDir
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }

Write-Host "Step 1: Scanning MCAT files in $McatRoot for team '$TeamName'..."

# 1a. Find all MCAT .cs files (scoped to McatRoot only, NOT workspace-wide)
$allFiles = Get-ChildItem -Path $McatRoot -Recurse -Filter "*.cs" |
    Where-Object { $_.Name -match "MCAT" -and $_.Name -notmatch "\.g\.cs$" }
Write-Host "  Found $($allFiles.Count) total MCAT .cs files"

# 1b. Filter by team name using Select-String (fast: short-circuits on first match)
$escapedTeam = [regex]::Escape($TeamName)
$teamPattern = '\[TestInfo\s*\([^)]*"' + $escapedTeam + '"'
$teamFiles = $allFiles | Where-Object {
    (Select-String -Path $_.FullName -Pattern $teamPattern -Quiet)
}

# Zero-match guard
if ($null -eq $teamFiles -or $teamFiles.Count -eq 0) {
    Write-Error "No MCAT files found for team '$TeamName'. Check spelling - must match [TestInfo] exactly (case-sensitive)."
    exit 1
}
Write-Host "  $($teamFiles.Count) files belong to team '$TeamName'"

# 1c. Extract test case IDs and metadata
$results = [System.Collections.Generic.List[object]]::new()
foreach ($file in $teamFiles) {
    $content = Get-Content $file.FullName -Raw
    # CRITICAL: Extract IDs from URLs only, not from comment text
    $ids = [regex]::Matches($content, 'workitems/edit/(\d+)') | ForEach-Object { $_.Groups[1].Value }
    # Staging: check positional true, named staging: true, or Staging in category name
    $isStaging = [bool]($content -match '\[TestInfo\s*\([^)]*(,\s*true\s*\)|staging:\s*true|"[^"]*Staging[^"]*")')

    if ($ids.Count -eq 0) {
        $results.Add(@{ File = $file.Name; ID = $null; Staging = $isStaging; FullPath = $file.FullName })
    } else {
        foreach ($id in $ids) {
            $results.Add(@{ File = $file.Name; ID = $id; Staging = $isStaging; FullPath = $file.FullName })
        }
    }
}

# 1d. Build derived collections
$uniqueIDs = @($results | Where-Object { $null -ne $_.ID } |
    ForEach-Object { [int]$_.ID } | Sort-Object -Unique)

$noIdFiles = @($results | Where-Object { $null -eq $_.ID } |
    ForEach-Object { $_.File } | Sort-Object -Unique)

$stagingFilesList = @($results | Where-Object { $_.Staging } |
    ForEach-Object { $_.File } | Sort-Object -Unique)

$totalPairs = ($results | Where-Object { $null -ne $_.ID }).Count
$teamFileCount = $teamFiles.Count

# Write state to JSON
$state = @{
    teamName      = $TeamName
    mcatRoot      = $McatRoot
    teamFileCount = $teamFileCount
    totalPairs    = $totalPairs
    uniqueIDs     = $uniqueIDs
    noIdFiles     = $noIdFiles
    stagingFiles  = $stagingFilesList
    results       = @($results)
}
$outFile = Join-Path $StateDir "step1-scan.json"
$state | ConvertTo-Json -Depth 4 -Compress | Out-File -FilePath $outFile -Encoding UTF8

Write-Host "`nStep 1 complete. State saved to: $outFile"
Write-Host "  Team files scanned:       $teamFileCount"
Write-Host "  File+testcase pairs:      $totalPairs"
Write-Host "  Unique test case IDs:     $($uniqueIDs.Count)"
Write-Host "  Files with no test case:  $($noIdFiles.Count)"
Write-Host "  Staging files:            $($stagingFilesList.Count)"
