# Forte3D Plugin

GitHub Copilot skills for **Forte3D / S3Dx** client development workflows. Includes C# command
generation (dialog and NoUI patterns), S3Dx XML command registration, automated test (MCAT)
creation and management, and Azure DevOps pull request code review.

## What's Included

### Skills

| Skill              | Description                                                                                                                                                                           |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `code-review`                 | Perform local code review or Azure DevOps PR review for the PPM/3D repository. Fetches PR changes, analyzes them, and posts approved inline comments with a "Code Review Agent:" tag. |
| `write-mcat`                  | Generate MCAT (Modern Client Automated Test) files from Azure DevOps test case IDs and manage automation details on test case work items.                                             |
| `command-entry` *(preview)*   | Add new S3Dx command entries to `Commands.xml`, `DevelopmentCommands.xml`, `Ribbon.xml`, and `DevelopmentRibbon.xml`.                                                                |
| `dialog-command` *(preview)*  | Generate S3Dx Dialog Commands in C# using `BaseFrameworkCommand` with `CommandUILayout.Dialog` for modal dialog workflows.                                                           |
| `noui-command` *(preview)*    | Generate S3Dx NoUI Commands in C# using `BaseFrameworkCommand` with `CommandUILayout.NoUI` for background, fire-and-forget, and batch operations.                                    |
