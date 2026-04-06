# API Configuration & Reference

## Azure DevOps Configuration

| Setting | Source | Variable |
|---------|--------|----------|
| Organization | user-provided (Step 0b) | `$devOpsOrg` |
| Project | user-provided (Step 0b) | `$devOpsProject` |
| TFVC Path Root | user-provided (Step 3) | `$tfvcPathRoot` |
| Test Assembly | auto-detect from `.csproj` | `$testAssembly` |
| DevOps URL Pattern | `https://dev.azure.com/{org}/{project}/_workitems/edit/{ID}` | derived |

## Required Tools and APIs

- **Azure CLI** (`az`): For authentication (`az account show`, `az account get-access-token`)
- **Azure DevOps REST API**: For work item batch queries and TFVC changeset queries (via `Invoke-RestMethod`)
- **MCP tools** (Azure DevOps MCP server): `mcp_azure_devops_wit_get_work_item` (get automation details), `mcp_azure_devops_wit_update_work_item` (update/clear automation details) for post-report actions
- **PowerShell**: All scanning and data processing

## MCAT File Structure

MCAT files follow this pattern:

```csharp
// This MCAT provides automation for Test Case 1234567:
// https://dev.azure.com/hexagonPPMCOL/PPM/_workitems/edit/1234567
// Test Case Title Here

[TestInfo("CategoryName", "TeamName")]                    // no staging
[TestInfo("CategoryName", "TeamName", true)]               // staging (positional)
[TestInfo("CategoryName", "TeamName", staging: true)]      // staging (named param)
[TestInfo("CategoryNameStaging", "TeamName")]              // staging (in category name)
public class MyTestMCAT : MCATBase
{
    // test implementation
}
```

- **Team name**: Second parameter in `[TestInfo]` — used to filter files by team
- **Staging flag**: Can appear in three forms (see [critical-rules.md](./critical-rules.md#3-staging-detection--three-patterns))
- **Test case ID**: Extract from the **URL** `workitems/edit/XXXXXXX` — NOT from the comment text

## Common Pitfalls

1. **ID extraction**: Use URLs only (`workitems/edit/(\d+)`), never comment text.
2. **Dual automation fields**: Check both standard and custom.
3. **Skip Manual items**: Do not flag them as non-automated.
4. **Manual blocks updates**: REST API rejects with `TF401320`.
5. **Update sets both fields**: Always include both in the patchDocument.
6. **Unicode in az CLI output**: Use `Invoke-RestMethod` with Bearer token instead of `az rest` when responses contain special Unicode characters (e.g., `\u221e` causes encoding crashes).
7. **TFVC vs Git authors**: The git repo may show a migration user as the author for all files. Always query TFVC at `$tfvcPathRoot` for original creators.
8. **Escape team names in regex**: Use `[regex]::Escape($teamName)` when building the `[TestInfo]` match pattern. Team names with regex-special characters (dots, parentheses) will break unescaped patterns.
9. **File path encoding**: TFVC paths with special characters must be URL-encoded via `[Uri]::EscapeDataString()`.

## Performance Tips

- **Batch REST API**: Fetches all IDs at once (200 per batch) — no separate WIQL pre-filter needed
- **Parallel TFVC queries**: Use `ForEach-Object -Parallel -ThrottleLimit 5` (PowerShell 7+) to query TFVC concurrently. Falls back to sequential for PS <7.
- **Fast file filtering**: Use `Select-String -Quiet` for team name matching instead of `Get-Content -Raw` — short-circuits on first match
- **Pre-built path map**: Build `$filePathMap` once before TFVC loop to avoid repeated `Get-ChildItem -Recurse` calls inside the loop
- **Cache results**: Store all data in PowerShell variables for incremental updates
- **Token reuse**: Reuse bearer tokens across steps; only refresh if >45 minutes have elapsed
- **Early exit**: Stop TFVC loop early if first 3 queries all miss (bad path detection)

## Cancellation and Partial State

If the user says "stop" or "cancel" during the workflow:
- **During scanning (Step 1)**: Safe to stop — no external side effects.
- **During API queries (Step 2)**: Stop after the current batch completes. Report partial results.
- **During TFVC lookup (Step 4)**: Stop and use whatever authors were already found.
- **During report generation (Step 6)**: Offer to generate a partial report with gathered data.
- **Never** discard already-gathered data on cancellation — always offer to save partial results.
