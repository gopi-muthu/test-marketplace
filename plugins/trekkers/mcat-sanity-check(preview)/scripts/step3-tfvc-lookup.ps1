# Step 3: TFVC Creator Lookup (Conditional)
# Self-contained script. Reads step1 state, queries TFVC for original file authors, writes output JSON.
# Usage: .\step3-tfvc-lookup.ps1 -StateDir "path\state" -DevOpsOrg "org" -DevOpsProject "proj" -TfvcPathRoot "$/PPM/S3D/Current"
param(
    [Parameter(Mandatory)] [string] $StateDir,
    [Parameter(Mandatory)] [string] $DevOpsOrg,
    [Parameter(Mandatory)] [string] $DevOpsProject,
    [Parameter(Mandatory)] [string] $TfvcPathRoot
)

$ErrorActionPreference = 'Stop'

# Read step1 state
$step1File = Join-Path $StateDir "step1-scan.json"
if (-not (Test-Path $step1File)) { Write-Error "step1-scan.json not found. Run step1 first."; exit 1 }
$step1 = Get-Content $step1File -Raw | ConvertFrom-Json
$noIdFiles = @($step1.noIdFiles)
$mcatRoot = $step1.mcatRoot

Write-Host "Step 3: TFVC creator lookup for $($noIdFiles.Count) no-ID files..."

# Get bearer token
$token = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$headers = @{ Authorization = "Bearer $token" }

# Construct TFVC base path
$driveLetter = (Split-Path $mcatRoot -Qualifier) + "\"
$relativeMcatPath = $mcatRoot.Substring($driveLetter.Length).TrimEnd('\') -replace '\\','/'
$tfvcBase = "$TfvcPathRoot/$relativeMcatPath"
Write-Host "  TFVC base: $tfvcBase"

# Pre-build filename -> relative path map
$filePathMap = @{}
foreach ($fileName in $noIdFiles) {
    $localFile = Get-ChildItem -Path $mcatRoot -Recurse -Filter $fileName | Select-Object -First 1
    if ($localFile) {
        $rel = $localFile.FullName.Substring($mcatRoot.Length).TrimStart('\') -replace '\\','/'
        $filePathMap[$fileName] = $rel
    }
}

# Query TFVC — parallel with throttle limit
$tfvcAuthors = @{}
$tfvcMisses = 0
$processedCount = 0

# Validate path with first 3 files sequentially before going parallel
$validationEntries = @($filePathMap.GetEnumerator() | Select-Object -First 3)
$validationHits = 0
foreach ($entry in $validationEntries) {
    $processedCount++
    $tfvcPath = "$tfvcBase/$($entry.Value)"
    $encodedPath = [Uri]::EscapeDataString($tfvcPath)
    $url = "https://dev.azure.com/$DevOpsOrg/$DevOpsProject/_apis/tfvc/changesets?searchCriteria.itemPath=$encodedPath&`$orderby=id asc&`$top=1&api-version=7.1"
    try {
        $result = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        if ($result.count -gt 0) {
            $author = $result.value[0].author.displayName
            $date = $result.value[0].createdDate
            $tfvcAuthors[$entry.Key] = "$author|$date"
            $validationHits++
        } else { $tfvcMisses++ }
    } catch { $tfvcMisses++ }
}

if ($validationHits -eq 0 -and $processedCount -ge 3) {
    Write-Warning "All first 3 TFVC lookups returned empty. Path '$tfvcBase' may be incorrect."
    Write-Warning "Stopping TFVC lookup early."
} else {
    # Path validated — process remaining files in parallel
    $remainingEntries = @($filePathMap.GetEnumerator() | Select-Object -Skip 3)
    if ($remainingEntries.Count -gt 0) {
        Write-Host "  Path validated ($validationHits/3 hits). Running $($remainingEntries.Count) remaining lookups in parallel (throttle: 10)..."
        $parallelResults = $remainingEntries | ForEach-Object -ThrottleLimit 10 -Parallel {
            $entry = $_
            $tfvcPath = "$using:tfvcBase/$($entry.Value)"
            $encodedPath = [Uri]::EscapeDataString($tfvcPath)
            $url = "https://dev.azure.com/$using:DevOpsOrg/$using:DevOpsProject/_apis/tfvc/changesets?searchCriteria.itemPath=$encodedPath&`$orderby=id asc&`$top=1&api-version=7.1"
            $hdrs = @{ Authorization = "Bearer $using:token" }
            try {
                $result = Invoke-RestMethod -Uri $url -Headers $hdrs -Method Get
                if ($result.count -gt 0) {
                    [PSCustomObject]@{ Key=$entry.Key; Author=$result.value[0].author.displayName; Date=$result.value[0].createdDate; Hit=$true }
                } else {
                    [PSCustomObject]@{ Key=$entry.Key; Hit=$false }
                }
            } catch {
                [PSCustomObject]@{ Key=$entry.Key; Hit=$false }
            }
        }
        foreach ($pr in $parallelResults) {
            $processedCount++
            if ($pr.Hit) {
                $tfvcAuthors[$pr.Key] = "$($pr.Author)|$($pr.Date)"
            } else {
                $tfvcMisses++
            }
        }
        Write-Host "  TFVC lookup complete: $processedCount/$($filePathMap.Count) files processed."
    }
}

# Summarize creators
$creatorSummary = @()
if ($tfvcAuthors.Count -gt 0) {
    $creatorSummary = @($tfvcAuthors.Values | ForEach-Object { ($_ -split '\|')[0] } |
        Group-Object | Sort-Object Count -Descending |
        ForEach-Object { "$($_.Name) ($($_.Count))" })
}

# Write state
$state = @{
    tfvcAuthors    = $tfvcAuthors
    tfvcMisses     = $tfvcMisses
    tfvcPathRoot   = $TfvcPathRoot
    tfvcBase       = $tfvcBase
    creatorSummary = $creatorSummary
}
$outFile = Join-Path $StateDir "step3-tfvc.json"
$state | ConvertTo-Json -Depth 4 -Compress | Out-File -FilePath $outFile -Encoding UTF8

Write-Host "`nStep 3 complete. State saved to: $outFile"
Write-Host "  Authors found:  $($tfvcAuthors.Count)"
Write-Host "  Misses:         $tfvcMisses"
Write-Host "  Creator summary: $($creatorSummary -join ', ')"
