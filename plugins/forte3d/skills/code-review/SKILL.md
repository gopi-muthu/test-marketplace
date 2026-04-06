---
name: code-review
description: 'Perform local code review or Azure DevOps PR review for the 3D repository (org: hexagonppmcol, project: PPM, repo: 3D). Use this skill whenever the user asks to review code, review a PR, review a pull request, check a PR, give feedback on code, or audit changes. Also trigger when user mentions a PR number, pull request ID, code quality check, or asks for inline PR comments. For PR reviews, this skill fetches the changes, analyzes them, presents findings to the user for approval, and posts ONLY approved comments directly onto the PR at the exact file and line number with a "Code Review Agent:" tag.'
---
# Code Review Skill

This skill performs two modes of code review:

1. **Local Code Review** — Reviews code files or git diffs present in the workspace.
2. **PR Review** — Fetches a pull request from Azure DevOps, analyzes the changes, and posts approved comments inline on the PR.

**Azure DevOps configuration (always use these):**

- Organization: `hexagonppmcol`
- Project: `PPM`
- Repository: `3D` (ID: `5f2cc9d4-db38-48b6-bffd-fc2bacc55856`)

---

## Mode 1: Local Code Review

When the user asks to review files or code in the workspace (no PR number given):

1. **Read the target files** using `read_file`, or get the diff using:
   ```powershell
   git -C g:\ diff [options]
   ```
2. **Analyze the code** following the review criteria below.
3. **Present findings** clearly with file path and line numbers.
4. No posting to Azure DevOps — output is shown in the chat only.

---

## Mode 2: PR Review

### Step 1: Fetch PR Details

Use `mcp_azure_devops_repo_get_pull_request_by_id` with:

- `pullRequestId`: the PR number given by the user
- `repositoryId`: `5f2cc9d4-db38-48b6-bffd-fc2bacc55856`

Read the result file to extract: title, description, author, source branch, target branch, reviewers, and merge status.

### Step 2: Fetch the Changed Files and Diff

Extract the `sourceRefName` and `targetRefName` from the PR data. Strip the `refs/heads/` prefix from each to get the branch names:

- e.g. `refs/heads/teams/trekkers/foo/MyBranch` → `teams/trekkers/foo/MyBranch` (`<sourceBranch>`)
- e.g. `refs/heads/master` or `refs/heads/releases/2026.1` → `master` or `releases/2026.1` (`<targetBranch>`)

> **Note:** The target branch is not always `master`. During hardening phases, PRs are commonly raised against `releases/<branch>`. Always derive `<targetBranch>` from the PR's `targetRefName`.

**Always fetch using the full ref first** — do NOT use raw commit SHAs directly (they are typically not available locally):

```powershell
# Step 1: Fetch both the source and target branches by full ref (most reliable)
git -C g:\ fetch origin "refs/heads/<sourceBranch>" "refs/heads/<targetBranch>" 2>&1

# Step 2: Use triple-dot diff with origin/ tracking refs — NOT raw commit SHAs
# Triple-dot finds the merge base automatically, giving only the PR's own changes
git -C g:\ diff --name-only origin/<targetBranch>...origin/<sourceBranch> 2>&1

# Get full diff for a specific file
git -C g:\ diff origin/<targetBranch>...origin/<sourceBranch> -- "<filePath>" 2>&1 | Select-Object -First 150

# Show file content at the PR branch tip with line numbers
git -C g:\ show "origin/<sourceBranch>:<filePath>" 2>&1 | ForEach-Object -Begin { $i=0 } -Process { $i++; "$i`: $_" }
```

> **Why not raw commit SHAs?** The commits from `lastMergeSourceCommit.commitId` and `lastMergeTargetCommit.commitId` in the PR data are usually not present in a shallow/partial local clone. Using `origin/<branchName>` after fetching is always reliable.

Also fetch existing PR threads to avoid duplicating already-raised comments:

```
mcp_azure_devops_repo_list_pull_request_threads
  pullRequestId: <id>
  repositoryId: 5f2cc9d4-db38-48b6-bffd-fc2bacc55856
```

### Step 3: Analyze the Changes

Apply the review criteria below to every changed file. For each concern found, record:

- **File path** (repo-relative, e.g., `MRoot/CommonApp/SOM/Client/xxxxxxx`)
- **Exact line number(s)** in the new version of the file
- **Category** (see below)
- **Comment text** — clear, actionable, specific

### Step 4: Present Findings to User

Show ALL findings in a structured list before doing anything else. For each finding, include:

```
[N] <Category> — <FilePath> line <LineNumber>
    <Comment text>
```

Always ask the user which comments to post using `vscode_askQuestions` tool:

- Show each finding as a selectable option (multi-select enabled)
- Include an option "Post all" and "Post none"
- Ask: "Which of these comments would you like me to post on the PR?"

**Do not post anything until the user confirms.**

### Step 5: Post Approved Comments

For each comment the user approves, call `mcp_azure_devops_repo_create_pull_request_thread` with:

```
content:        "**Code Review Agent:** <your comment text>"
filePath:       "<repo-relative path starting with />"
rightFileStartLine: <line number>
rightFileEndLine:   <line number>  (same as start for single-line)
rightFileStartOffset: 1
rightFileEndOffset:   1
pullRequestId:  <PR id>
repositoryId:   5f2cc9d4-db38-48b6-bffd-fc2bacc55856
status:         Active
```

Confirm to the user which comments were posted successfully.

---

## Reference Files

Load the appropriate guidelines file with `read_file` **before analyzing** any changed files:

- **[csharp-coding-guidelines.md](../../../shared/coding-guidelines/csharp-coding-guidelines.md)** — Project C# coding standards (naming, formatting, patterns, best practices). Load it **only** when the review includes `.cs` files.

---

## Review Criteria

Apply these checks to all changed code:

### Correctness & Logic

- Logic errors, off-by-one errors, incorrect conditions
- Null/empty checks missing at public API boundaries
- Resource leaks (handles, COM objects, memory)

### Consistency & Patterns

- Does the change follow the same patterns as surrounding code?
- Are markers, annotations, or instrumentation applied uniformly across all methods/classes that should have them? Flag any method that is skipped when peers are covered.
- Are base class / template methods treated consistently with derived class overrides?

### Security (OWASP Top 10)

- No injection risks, no hardcoded credentials, no insecure data exposure

### Code Quality

- Dead code or unreachable paths introduced
- Redundant or duplicate logic compared to existing helpers
- Naming inconsistencies — for C# files, validate against ` ../../../shared/coding-guidelines/csharp-coding-guidelines.md`;

---

### Tips

- Use `Select-Object -First N` in PowerShell instead of `| head` (Windows terminal).
- Use `ForEach-Object -Begin { $i=0 } -Process { $i++; "$i\`: $_" }` to add line numbers to file output.
- When fetching large diffs, focus on the files most relevant to the PR title/description first.
- Don't post comments that are already covered by existing PR threads.
- Always prefix posted comments with `**Code Review Agent:**` — never omit this tag.
