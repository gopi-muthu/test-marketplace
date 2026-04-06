# Critical Rules (Lessons Learned)

These rules are based on real failures encountered during MCAT report generation. Violating any of them produces incorrect reports.

## 1. Extract IDs from URLs ONLY — NEVER from comments

- **CORRECT**: Extract from URL pattern `workitems/edit/(\d+)` → finds ~430+ unique IDs
- **WRONG**: Extract from comment text `Test Case (\d+):` → only finds ~31 unique IDs (most files don't have the comment pattern)
- Many files have ONLY a URL and no `Test Case NNNNN:` comment line
- The URL is the **authoritative source** of the test case ID
- The comment text may be missing, abbreviated, or contain typos (e.g., `516825` instead of `2516825`)

## 2. Two Automation Status Fields — Check BOTH

- **Standard**: `Microsoft.VSTS.TCM.AutomationStatus` (the TCM field)
- **Custom**: `Custom.AutomationStatus` (custom field added by the team)
- Both must agree. If one is "Automated", the other should also be "Automated" — flag mismatches for correction.
- **Skip Manual entirely**: If **either** field is "Manual", skip the item completely — do NOT list it in the non-automated report. Manual test cases are intentionally manual. Also never attempt to update them (REST API rejects with `TF401320` rule validation error).

## 3. Staging Detection — Three Patterns

The `[TestInfo]` attribute can indicate staging in multiple ways:
- **Positional**: `[TestInfo("Category", "Team", true)]`
- **Named parameter**: `[TestInfo("Category", "Team", staging: true)]`
- **Staging in category name**: The first argument of `[TestInfo]` contains the word `Staging` (e.g., `"CategoryNameStaging"`)
- Use combined regex: `\[TestInfo\s*\([^)]*(,\s*true\s*\)|staging:\s*true|"[^"]*Staging[^"]*")`
- **Do NOT** use a bare `\bStaging\b` regex on the full file — it causes false positives on filenames, comments, folder names, and variable names unrelated to the TestInfo attribute

## 4. Automation Updates via MCP (Azure DevOps)

- Use `mcp_azure_devops_wit_update_work_item` with a `patchDocument` to set all automation fields in a single call — including **both** `Microsoft.VSTS.TCM.AutomationStatus` AND `Custom.AutomationStatus`
- The standard `AutomationStatus` update does **NOT** auto-set `Custom.AutomationStatus` — always include both fields explicitly in the `patchDocument`
- Items with `Custom.AutomationStatus=Manual` will **block** updates with `TF401320: Rule Error`

### Update Payload Example

```json
{
  "id": "<workItemId>",
  "project": "$devOpsProject",
  "patchDocument": [
    { "op": "replace", "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestId", "value": "<MCAT class name>" },
    { "op": "replace", "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestName", "value": "<MCAT class name>" },
    { "op": "replace", "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestStorage", "value": "$testAssembly" },
    { "op": "replace", "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestType", "value": "L2" },
    { "op": "replace", "path": "/fields/Microsoft.VSTS.TCM.AutomationStatus", "value": "Automated" },
    { "op": "replace", "path": "/fields/Custom.AutomationStatus", "value": "Automated" }
  ]
}
```

### Check Payload Example

```json
{
  "id": "<workItemId>",
  "project": "$devOpsProject",
  "fields": [
    "Microsoft.VSTS.TCM.AutomatedTestId",
    "Microsoft.VSTS.TCM.AutomatedTestName",
    "Microsoft.VSTS.TCM.AutomatedTestStorage",
    "Microsoft.VSTS.TCM.AutomatedTestType",
    "Microsoft.VSTS.TCM.AutomationStatus",
    "Custom.AutomationStatus"
  ]
}
```

### Mismatch Fix Payload

For items where standard = "Automated" but custom ≠ "Automated":

```json
{
  "id": "<workItemId>",
  "project": "$devOpsProject",
  "patchDocument": [
    { "op": "replace", "path": "/fields/Custom.AutomationStatus", "value": "Automated" }
  ]
}
```

## 5. Report File Management

- When regenerating, create a NEW report file — do not overwrite the existing one unless user says so
- Include `(regenerated)` in the date line to distinguish from original

## 6. Load Deferred Tools BEFORE Calling Them

- `vscode_askQuestions` is a **deferred tool** — it is NOT available until discovered via `tool_search_tool_regex`
- **MUST** run `tool_search_tool_regex` (pattern: `askQuestions`) BEFORE the first `vscode_askQuestions` call
- Calling a deferred tool without loading it first will crash the agent or silently fail
- This loading only needs to happen **once per session** — after that, the tool stays available
- Do this in Step 0a (during auto-detection), so the tool is ready before Step 0b needs it
