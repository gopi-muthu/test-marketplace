---
name: mcat-sanity-check(preview)
description: 'Generate or refresh an MCAT automation report. Trigger on "MCATs report", "automation report", "automation coverage", "non-automated test cases", or "files with no test case links".'
---
# MCAT Report Skill

Generate a comprehensive MCAT automation status report by scanning the codebase, cross-referencing with Azure DevOps, and producing a formatted report file.

## Execution Model — CRITICAL

**Scripts are self-contained `.ps1` files** that accept `-param` arguments and persist all state to JSON files on disk. The agent:

1. Resolves the absolute path to each script in `./scripts/`
2. Invokes it via `pwsh -File <script> -Param1 value1 -Param2 value2` with a generous timeout (120-300s)
3. Reads the script's console output for progress/summary
4. Reads the JSON state file for structured data needed in subsequent steps

**Why this matters**: Running inline PowerShell code in the terminal causes variables to be lost across sessions, commands to time out and get backgrounded, and output to be truncated. The scripts-on-disk approach eliminates all of these problems.

**State directory**: Create a temp state directory at the start (e.g., `$env:TEMP\mcat-report-state`). All scripts read/write JSON files there. This directory survives terminal restarts.

### Script invocation pattern

```
# Step 1 — always use pwsh -File with explicit params
pwsh -File "g:\.github\skills\get-mcat-automation-report\scripts\step1-scan-mcat-files.ps1" `
  -McatRoot "g:\MRoot\...\CommonAppMCATs" `
  -TeamName "Trekkers" `
  -StateDir "$env:TEMP\mcat-report-state"
```

Each script writes its output to `<StateDir>/stepN-*.json`. The next script reads the previous step's JSON. No shell variables are shared between steps.

### State file chain

```
step1-scan-mcat-files.ps1  → state\step1-scan.json
step2-query-devops.ps1     → state\step2-devops.json  (reads step1-scan.json)    ┐ concurrent
step3-tfvc-lookup.ps1      → state\step3-tfvc.json    (reads step1-scan.json)    ┘
step4-retry-ids.ps1        → state\step4-retry.json   (reads step1-scan.json + step2-devops.json)
step5-generate-report.ps1  → state\summary.json + report .txt  (reads step1 + step4 + optional step3)
```

## Overview

1. Scan all MCAT `.cs` files in the workspace for a target team
2. Extract test case IDs from **URLs** in file headers (NOT from comment text) — see [critical-rules.md](./references/critical-rules.md#1-extract-ids-from-urls-only--never-from-comments)
3. Query Azure DevOps for automation status — checking **BOTH** fields — see [critical-rules.md](./references/critical-rules.md#2-two-automation-status-fields--check-both)
4. Identify non-automated test cases (skipping Manual items), staging files, and files with no test case links
5. Look up original file creators from TFVC history (optional)
6. Retry bad/not-found IDs one more time to catch transient errors
7. Generate a formatted text report — see [report-format.md](./references/report-format.md)

## Critical Rules Summary

Read [references/critical-rules.md](./references/critical-rules.md) for detailed explanations behind each rule:

1. **Extract IDs from URLs ONLY** — pattern `workitems/edit/(\d+)`, never from comment text
2. **Check BOTH automation fields** — `Microsoft.VSTS.TCM.AutomationStatus` AND `Custom.AutomationStatus`; skip Manual entirely
3. **Staging detection uses `[TestInfo]`-scoped regex** — three patterns, no bare `\bStaging\b`
4. **Automation updates set BOTH fields** in one `patchDocument`; Manual blocks updates with `TF401320`
5. **New report file on regeneration** — include `(regenerated)` in date line
6. **Load deferred tools first** — `vscode_askQuestions` must be loaded via `tool_search_tool_regex` before use

## When to Use

- Generate or regenerate an MCATs report
- Check team's automation coverage
- Find which test cases are not automated
- Find MCAT files with no test case links

## Prerequisites

- **Load deferred tools first**: Run `tool_search_tool_regex` with pattern `askQuestions` to load `vscode_askQuestions` — do this in Step 0a
- Access to Azure DevOps (org and project provided in Step 0)
- Azure CLI authenticated (`az login`)
- TFVC access for creator attribution (optional)

## User Experience Guidelines

1. **Step headers**: Print a brief status at each phase: `"🔍 Step 1/7: Scanning MCAT files..."`
2. **No silent waits**: Each script prints its own progress — the agent just needs to invoke with sufficient timeout
3. **Error recovery**: If a script fails, check its console output. The state files from previous steps remain intact — fix the issue and re-run just the failed step
4. **Completion summary**: Read `state\summary.json` and display the visual box from [report-format.md](./references/report-format.md#completion-summary-box)

## Workflow Steps

### Step 0: Gather Parameters (Auto-Detect + Confirm)

#### 0a. Auto-detect from workspace

**First action**: Run `tool_search_tool_regex` with pattern `askQuestions` to load the deferred tool.

Then silently detect:

- **MCAT root (`$mcatRoot`) and test assembly (`$testAssembly`)**: Find `.csproj` files ending with `MCATs.csproj` or `MCAT.csproj`. The directory is the root; basename + `.dll` is the assembly. If multiple found, present multi-select in Step 0b. Exclude non-qualifying projects (e.g., `AutomationUtilities.csproj`).
- **User profile path**: Extract username from VS Code extension paths visible in workspace info. Construct `C:\Users\<username>` silently — never prompt or run terminal commands for this.
- **Script directory**: Resolve path to `./scripts/` relative to this SKILL.md file. All scripts are invoked by absolute path.
- **State directory**: Create `$env:TEMP\mcat-report-state` (or unique subfolder). Pass as `-StateDir` to every script.

#### 0b. Ask user for required inputs

Use `vscode_askQuestions` — each question with `options` needs **at least 2 options**.

If multiple MCAT projects detected, add a multi-select question first (all pre-selected).

Ask four questions in one call:

1. **Team name**: Free text — matches `[TestInfo]` second parameter
2. **Azure DevOps organization**: Free text (e.g., "hexagonPPMCOL")
3. **Azure DevOps project**: Free text (e.g., "PPM")
4. **Report location**: Options — Desktop (recommended), Temp folder, Project folder, Custom path

#### Confirmation

Print all parameters as a formatted table, then ask `"Are these parameters correct?"` via separate `vscode_askQuestions` with options `["Yes, all correct", "No, I need to change something"]`.

If "No" → multi-select which parameters to change, then ask free text for each selected one.

**Do NOT proceed to Step 1 until confirmed.**

### Step 1: Scan MCAT Files

```powershell
pwsh -File "<scriptDir>\step1-scan-mcat-files.ps1" -McatRoot "<mcatRoot>" -TeamName "<teamName>" -StateDir "<stateDir>"
```

Timeout: 120s. Scans `.cs` files **only inside `$mcatRoot`**, filters by team name, extracts IDs from URLs, detects staging.

**Zero-match guard**: If exit code is 1 (no files match team name), stop and inform the user.

State output: `<stateDir>\step1-scan.json`

### Step 2: Ask About TFVC + Query DevOps (Concurrent)

After Step 1, read `step1-scan.json` to check `noIdFiles.Count`. If there are no-ID files, ask the user via `vscode_askQuestions`:

1. `"Look for Created By in Repo?"` → Yes/No

**MANDATORY**: If user selects **No**, do NOT ask the follow-up repo path question — skip TFVC entirely and proceed to Step 2a only. Only ask the follow-up question if user selects **Yes**:
2. (Only if Yes) `"Which Repo to look into?"` → free text (e.g., `"$/PPM/S3D/Current"`)

If no no-ID files, skip the TFVC question entirely — do not ask it.

**Run DevOps query and TFVC lookup concurrently** to save time. Both depend only on Step 1 output and are independent of each other.

#### 2a. Query Azure DevOps for Automation Status

```powershell
pwsh -File "<scriptDir>\step2-query-devops.ps1" -StateDir "<stateDir>" -DevOpsOrg "<org>" -DevOpsProject "<project>"
```

Timeout: 180s. Authenticates via Azure CLI, fetches bearer token, queries all unique IDs via batch REST API (200/batch). **On batch failure (404)**, auto-sub-splits into 50-ID chunks to recover IDs immediately instead of deferring to retry.

State output: `<stateDir>\step2-devops.json`

#### 2b. TFVC Creator Lookup (Conditional — run concurrently with 2a)

Only if user opted in and `noIdFiles.Count > 0`:

```powershell
pwsh -File "<scriptDir>\step3-tfvc-lookup.ps1" -StateDir "<stateDir>" -DevOpsOrg "<org>" -DevOpsProject "<project>" -TfvcPathRoot "<path>"
```

Timeout: 300s. Validates TFVC path with first 3 files sequentially, then runs remaining lookups **in parallel** (10 concurrent HTTP calls via `ForEach-Object -Parallel -ThrottleLimit 10`).

State output: `<stateDir>\step3-tfvc.json`

**How to run concurrently**: Launch Step 2a as a background terminal (`isBackground: true`), then ask the TFVC question, then run Step 2b in the foreground. After 2b completes, check the background terminal output for 2a. If user declines TFVC, just run 2a in the foreground normally.

### Step 3: Retry Bad/Not-Found IDs

```powershell
pwsh -File "<scriptDir>\step4-retry-ids.ps1" -StateDir "<stateDir>" -DevOpsOrg "<org>" -DevOpsProject "<project>"
```

Timeout: 300s. Re-queries failed IDs using **25-ID sub-batches** on failure (not individual calls). Only falls back to individual calls if a 25-ID sub-batch also fails. Merges results into step2 arrays.

State output: `<stateDir>\step4-retry.json`

### Step 4: Generate Report

```powershell
pwsh -File "<scriptDir>\step5-generate-report.ps1" -StateDir "<stateDir>" -ReportPath "<reportPath>" -TeamName "<teamName>" -DevOpsOrg "<org>" -DevOpsProject "<project>" [-IncludeTfvc]
```

Timeout: 60s. Builds the report following [report-format.md](./references/report-format.md) and writes to `$reportPath`.

State output: `<stateDir>\summary.json` (for the agent to display the visual summary)

### Step 5: Present Summary and Follow-Up

Read `<stateDir>\summary.json` and display:

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

Then use `vscode_askQuestions` with multi-select for follow-up:

- `"Open the report file"` (recommended)
- `"Update automation status for specific test cases"`
- `"Show non-automated test cases in detail"`
- `"Nothing — I'm done"`

### Step 6: Post-Report Actions (Optional)

If user requests updates, use MCP tools — see [critical-rules.md](./references/critical-rules.md#4-automation-updates-via-mcp-azure-devops) for payload examples.

## Additional Reference

- [API &amp; configuration details](./references/api-and-config.md) — DevOps config, MCAT file structure, common pitfalls, performance tips
- [Critical rules](./references/critical-rules.md) — Detailed lessons learned
- [Report format](./references/report-format.md) — Mandatory section layout and formatting rules
