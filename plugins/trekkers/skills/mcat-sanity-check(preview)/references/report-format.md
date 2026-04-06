# Report Format Reference

The report MUST contain these exact sections in this exact order. Do NOT add, remove, rename, or reorder sections.

## Section Layout — MANDATORY FORMAT

```
[TeamName] NON-AUTOMATED TEST CASES REPORT
Generated: YYYY-MM-DD
========================================================================================================================

SUMMARY
----------------------------------------
  Total [Team] MCAT files scanned:    X
  Total file+testcase pairs found:    Y
  Unique test case IDs:               Z
  Automated (both fields):            A (XX.X%)
  Non-automated entries:              B (C unique IDs, D unique files)
  Manual (skipped):                   M
  Staging files found:                S
  Files with no test case link:       N
  IDs not found in DevOps:            F (list IDs if few, or count)

REMAINING NON-AUTOMATED TEST CASES (excluding Manual, resolved mismatches, and newly automated)
--------------------------------------------------------------+----------+--------------------------------------------------------+----------------+-------------------+---------------------------------------------
FileName                                                      | ID       | Title                                                  | Status         | State             | Remarks
--------------------------------------------------------------+----------+--------------------------------------------------------+----------------+-------------------+---------------------------------------------
[rows here — one row per file, wrap long titles to continuation line with blank FileName/ID]
--------------------------------------------------------------+----------+--------------------------------------------------------+----------------+-------------------+---------------------------------------------

REMAINING TEST CASE LINKS
----------------------------------------
  [ID]: https://dev.azure.com/$devOpsOrg/$devOpsProject/_workitems/edit/[ID] - [brief note]

MANUAL TEST CASES (skipped - not counted)
----------------------------------------
  [ID]: https://dev.azure.com/$devOpsOrg/$devOpsProject/_workitems/edit/[ID] - [Title] (Custom.AutomationStatus=Manual)

STAGING FILES (X total)
----------------------------------------
  1. [FileName]  [staging: true]  ([Automated/Non-automated], ID: [XXXXX])
  ...

FILES WITH NO TEST CASE ID (X total)
----------------------------------------
  Creator Summary: [Author1 (count), Author2 (count), ...]
  Source: $tfvcPathRoot (TFVC)

  #                             File                                             Created By               Date
  -----------------------------------------------------------------------------------------------------------------
  1.    [FileName]                                                           [Author Name]              YYYY-MM-DD
  ...

OPEN ISSUES
----------------------------------------
  1. X test case ID(s) not found in Azure DevOps (may be deleted or in another project):
     - ID NNNNNN: https://dev.azure.com/$devOpsOrg/$devOpsProject/_workitems/edit/NNNNNN
  2. X MCAT files have no test case link - need URL added to file header
  3. X item(s) have mismatched automation status fields - need sync:
     - ID NNNNNN: https://dev.azure.com/$devOpsOrg/$devOpsProject/_workitems/edit/NNNNNN (TCM=value, Custom=value)
  4. X linked ID(s) are not Test Cases - need correct test case IDs:
     - ID NNNNNN: https://dev.azure.com/$devOpsOrg/$devOpsProject/_workitems/edit/NNNNNN (Type: Bug) - [Title]
  ...
```

## Formatting Rules

1. **Non-automated table**: Use pipe-delimited columns with consistent widths matching the header separator line. Wrap long titles to a continuation line (blank filename, blank ID, continued title text).
2. **Summary line "Automated (both fields)"**: Always label it this way to clarify both `Microsoft.VSTS.TCM.AutomationStatus` AND `Custom.AutomationStatus` are checked.
3. **Manual section**: List ALL items where either field is "Manual". Include the URL, title, and note which field(s) are Manual. If there's a mismatch (e.g., Custom=Manual but Standard=empty), note it.
4. **No-ID files table**: Use left-aligned fixed-width columns. Sort by date descending (newest first). Include Creator Summary and TFVC source at the top.
5. **Test case links**: Sort by ID numerically. Only list IDs that are still non-automated (not resolved).
6. **Summary percentages**: Calculate as `Automated / (Automated + NonAutomated unique IDs) * 100`, rounded to 1 decimal. Manual items are excluded from both the count and the percentage (they are skipped entirely).
7. **No "Resolved This Session" section**: Do NOT include a section tracking what was resolved during the session. The report should reflect the current state only.
8. **No "IDs Re-fetched" section**: Do NOT include a section about re-fetched IDs. Simply update the "IDs not found" count in the summary.
9. **Open Issues with IDs**: Each issue category that involves specific work item IDs MUST list those IDs with their DevOps URLs as sub-bullets. Only the "no test case link" issue (which refers to files, not IDs) omits sub-bullets. When ≤10 not-found IDs exist, also inline them in the Summary line.

## Column Alignment for No-ID Files Table

Calculate exact column widths dynamically. Guard against empty collections:

```powershell
$maxFile = if ($noIdFiles.Count -gt 0) { ($noIdFiles | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum } else { 40 }
$maxAuthor = if ($tfvcAuthors.Count -gt 0) { ($tfvcAuthors.Values | ForEach-Object { (($_ -split '\|')[0]).Length } | Measure-Object -Maximum).Maximum } else { 20 }
$fmt = "  {0,-4}  {1,-$maxFile}  {2,-$maxAuthor}  {3,-10}"
```

## Completion Summary Box

After writing the report, show this visual summary:

```
✅ Report generated: [filepath]

┌─────────────────────────────────────────────────┐
│ [TeamName] MCAT Automation Summary              │
├─────────────────────────────────────────────────┤
│ Files scanned:          [X]                     │
│ Automation coverage:    [XX.X]% ([A] of [Z])    │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░  (visual bar)            │
│ Non-automated:          [B] entries ([C] IDs)   │
│ Manual (skipped):       [M]                     │
│ Staging:                [S]                     │
│ No test case link:      [N]                     │
│ Not found in DevOps:    [F]                     │
└─────────────────────────────────────────────────┘
```
