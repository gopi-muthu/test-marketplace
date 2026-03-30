---
name: write-mcat
description: Generate MCAT (Modern Client Automated Test) files from test case IDs, and manage automation details on Azure DevOps test case work items. Use this skill whenever the user asks to create, write, or generate an MCAT, automated test, or test code from a test case ID. Also trigger when user mentions test automation, test case implementation, MCATRunner, or converting manual test cases to automated tests. Also trigger when the user asks to get, check, update, set, clear, or reset the automation status or automation details (AutomatedTestName, AutomatedTestStorage, AutomatedTestType, AutomatedTestId, AutomationStatus) of a test case work item. This skill handles the complete workflow from retrieving test steps to generating and building the test code, with optional validation and debugging, as well as reading and writing automation fields on work items via MCP tools.
---
# Write MCAT Skill

This skill automates the creation of MCAT (Modern Client Automated Test) files from test case IDs. It follows project-specific coding standards, searches for reference patterns in the workspace, and includes a complete build-test-debug cycle.

## Overview

MCAT generation is a multi-step process that requires:

- Retrieving test case details from the test management system
- Searching the workspace for existing patterns and utilities
- Generating test code that follows project conventions
- Building the project
- Optionally running the test, debugging, and iterating until it passes

This skill ensures consistency with existing code by mandating workspace searches before code generation.

## When to Use This Skill

Use this skill when the user:

- Provides a test case ID and asks to create an MCAT
- Wants to automate a manual test case
- Needs to generate test code following project standards
- Mentions MCATRunner or test automation
- Asks to **get** or **check** the automation details/status of a test case work item
- Asks to **update** or **set** automation fields (test name, storage, type, ID, status) on a work item
- Asks to **reset**, **clear**, or **un-automate** a test case work item
- Mentions `AutomationStatus`, `AutomatedTestName`, `AutomatedTestStorage`, `AutomatedTestType`, or `AutomatedTestId` in the context of a work item

## Workflow Steps

Follow these steps **in order**. Do not skip any mandatory step or proceed to the next until the current one is complete. Steps 7, 8, and 9 are optional and should only be performed if the user wants to run and validate the test.

### Step 1: Retrieve Test Steps

The user can provide test case information in one of two ways:

#### Option A: DevOps Test Case ID

If the user provides a DevOps test case ID (often in the format like "12345" or similar), use the `mcp_azure_devops_wit_get_work_item` tool with the following parameters to fetch the test steps:

```json
{
  "id": <test_case_id>,
  "project": "PPM",
  "fields": ["Microsoft.VSTS.TCM.Steps"]
}
```

The `Microsoft.VSTS.TCM.Steps` field contains the steps as XML. Parse the XML to extract each `<step>` element:

- The first `<parameterizedString>` inside a step is the **Action**
- The second `<parameterizedString>` is the **Expected Result**
- `type="ValidateStep"` means the step has both action and expected result
- `type="ActionStep"` means the step is an action only with no expected result

#### Option B: Manually Provided Test Case

If the user manually provides the test steps and expected results directly (instead of a test case ID), accept them as-is and use them for MCAT generation. There is no need to call `mcp_azure_devops_wit_get_work_item` in this case.

#### If Neither Is Provided

If the user has not provided a test case ID or manual test steps, use the `vscode_askQuestions` tool to ask the user whether they want to provide a DevOps test case ID or manually describe the test steps. **Do not attempt to generate any code without valid test case information.**

#### After Obtaining Test Steps

Regardless of the method used:

1. List down all the steps clearly
2. List down all expected results
3. Confirm with the user that you have the correct test case information

### Step 2: Search Workspace for Reference Files

**This step is MANDATORY.** You MUST search the current workspace for reference files and code patterns before generating any MCAT code.

Search for:

- **Existing MCAT files**: Look for test files with similar patterns, typically with `.cs` extensions in test-related directories
- **Helper methods and utilities**: Search for common test utilities, setup methods, assertion helpers
- **Coding patterns**: Identify how existing tests are structured, what namespaces are used, what base classes are inherited
- **Project structure**: Understand where test files are located, what dependencies they use

Search strategies:

```
1. Use semantic_search to find: "MCAT test files", "test helper methods", "test utilities"
2. Use file_search to find patterns like: "**/*MCAT*.cs"
3. Read examples of existing test files to understand:
   - Namespace conventions
   - Using statements and references
   - Base class inheritance
   - Test method attributes and structure
   - Common assertion patterns
   - Setup and teardown patterns
```

**Why this matters:** The generated MCAT must follow existing patterns in the workspace. Generating code without checking workspace patterns typically results in compilation errors, missing references, or inconsistent code style.

### Step 3: Review Coding Standards

Read the `.editorconfig` file to understand the project's coding standards:

```powershell
Get-Content "G:\.editorconfig"
```

Pay attention to:

- Indentation style (tabs vs spaces)
- Naming conventions
- Line ending preferences
- File organization rules

### Step 4: Generate MCAT

Now that you have:

- Test case steps and expected results
- Reference patterns from the workspace
- Coding standards from `.editorconfig`

Generate the MCAT file following these requirements:

#### File Structure

1. **Copyright Header** (at the very top): Use the same copyright header found in reference MCAT files from Step 2
2. **AI Assistance Comment** (immediately after copyright):

```csharp
// <AI Assisted Code>
```

3. **Using Statements**: Follow the patterns found in reference files
4. **Namespace**: Use the namespace convention from similar test files
5. **Class Structure**:

   - Inherit from appropriate base classes (as seen in reference files)
   - Use proper test attributes
   - Include all test steps as test methods or within a single test method

#### Code Quality Requirements

- **No placeholder code**: All code must be complete and functional
- **Use workspace utilities**: Leverage helper methods and utilities found in Step 2
- **Follow patterns**: Match the structure and style of existing MCAT files
- **Proper assertions**: Use the assertion methods available in the test framework
- **Clean code**:
  - Remove unnecessary whitespace
  - Remove TODO comments or placeholder comments
  - Ensure proper indentation and formatting
  - Remove unnecessary references

#### Naming Conventions

- **Filename**: Must not contain numbers and should follow project naming conventions (e.g., `DescriptiveTestName.cs`)
- **Class name**: Must match the filename
- **Test methods**: Use descriptive names that indicate what is being tested
- **Variables**: Follow the naming conventions from .editorconfig

### Step 5: Build the Project

Build the project using:

```powershell
dotnet build .
```

**Do not use any other build command.** Run this command in the Copilot terminal.

Review the build output:

- If there are errors, identify and fix them before proceeding
- Ensure all references are resolved
- Verify the namespace and using statements are correct

### Step 6: User Confirmation for File Naming

Ask the user(use `vscode_askQuestions):`

> "The MCAT file has been created as `[FileName].cs`. Would you like to change the name? If yes, please provide the new name."

If the user provides a new name:

1. Rename both the file and the class name to match
2. Rebuild the project with `dotnet build .`
3. Wait for successful build before proceeding

### Step 7: Run and Validate (Optional)

Run the test using MCATRunner:

```cmd
X:\Container\Bin\Assemblies\Debug\NetCore\MCATRunner.exe -testnames [TestMethodName]
```

Replace `[TestMethodName]` with the actual names from your generated MCAT.

**Note:** Use the class name, not the filename.

After running:

1. Locate the `MCATSummary.log` file in the temp directory
2. Read and analyze the log to determine if the test passed or failed
3. Look for error messages, stack traces, or assertion failures

### Step 8: Debug if Needed (Optional)

Only perform this step if Step 7 was executed and the test fails.

1. **Analyze the failure**:
   - Read the error message and stack trace carefully
   - Identify which step failed
   - Determine if it's a code error, logic error, or environment issue
   - Verify test steps match the test case requirements
   - Check that assertions use correct expected values
2. **Fix the error**:
   - Update the MCAT code based on the failure reason
   - Ensure you're still following workspace patterns
3. **Rebuild and retest**:
   - Run `dotnet build .` again
   - Run MCATRunner again
   - Review the new MCATSummary.log
4. **Iterate**: Repeat until the test passes

### Step 9: Final Report (Optional)

Only perform this step if Step 7 was executed. After the test passes, show the user:

1. The final MCATSummary.log content
2. A summary of the test results
3. The location of the generated MCAT file
4. Any notable observations or recommendations

## Important Notes

### Required Tools

This skill uses the following tools (they will be loaded as needed):

- `mcp_azure_devops_wit_get_work_item` - To retrieve test steps from Azure DevOps using the `Microsoft.VSTS.TCM.Steps` field, and to get automation details
- `mcp_azure_devops_wit_update_work_item` - To update or reset automation details on a work item

### Critical Requirements

- **Never skip Step 2**: Workspace search is mandatory to ensure generated code follows existing patterns
- **Follow .editorconfig**: Coding standards compliance is required
- **No numbers in filenames**: Test file names must be descriptive, not numeric
- **Match class and filename**: The class name must exactly match the filename
- **Build before running**: If running the test (Step 7), always build successfully before attempting to run the test

### Common Pitfalls to Avoid

1. **Generating code without searching workspace**: This almost always results in compilation errors
2. **Skipping the build step**: Running tests without building will fail
3. **Ignoring coding standards**: Results in inconsistent code that may not pass code review
4. **Not reading the full error log**: Missing important error details leads to inefficient debugging
5. **Using wrong MCATRunner path**: Always use the full path specified in Step 7

## Automation Details Operations

Use these MCP tool patterns when the user asks to **get**, **update**, or **reset** the automation details of a test case work item.

### Get Automation Details

Use `mcp_azure_devops_wit_get_work_item` with the automation-related fields:

```json
{
  "id": <workItemId>,
  "project": "PPM",
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

The response fields map to:

| Response Field                              | Meaning                                         |
| ------------------------------------------- | ----------------------------------------------- |
| `Microsoft.VSTS.TCM.AutomatedTestId`      | Unique test identifier (usually the class name) |
| `Microsoft.VSTS.TCM.AutomatedTestName`    | Test class/method name                          |
| `Microsoft.VSTS.TCM.AutomatedTestStorage` | Assembly/namespace containing the test          |
| `Microsoft.VSTS.TCM.AutomatedTestType`    | Test level (e.g.`L2`)                         |
| `Microsoft.VSTS.TCM.AutomationStatus`     | `Automated` or `Not Automated`              |
| `Custom.AutomationStatus`                 | Custom field mirroring automation status        |

### Update Automation Details

Use `mcp_azure_devops_wit_update_work_item` to set automation fields after writing an MCAT. Only include the fields that need to be updated:

```json
{
  "id": <workItemId>,
  "project": "PPM",
  "patchDocument": [
    {
      "op": "replace",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestId",
      "value": "<TestClassName>"
    },
    {
      "op": "replace",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestName",
      "value": "<TestClassName>"
    },
    {
      "op": "replace",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestStorage",
      "value": "<AssemblyName>"
    },
    {
      "op": "replace",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestType",
      "value": "L2"
    },
    {
      "op": "replace",
      "path": "/fields/Microsoft.VSTS.TCM.AutomationStatus",
      "value": "Automated"
    },
    {
      "op": "replace",
      "path": "/fields/Custom.AutomationStatus",
      "value": "Automated"
    }
  ]
}
```

**When to use:** After successfully generating and building an MCAT, offer to update the work item's automation details to reflect the new automation.

### Reset (Clear) Automation Details

Use `mcp_azure_devops_wit_update_work_item` to clear all automation fields and set the status back to `Not Automated`:

```json
{
  "id": <workItemId>,
  "project": "PPM",
  "patchDocument": [
    {
      "op": "remove",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestId"
    },
    {
      "op": "remove",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestName"
    },
    {
      "op": "remove",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestStorage"
    },
    {
      "op": "remove",
      "path": "/fields/Microsoft.VSTS.TCM.AutomatedTestType"
    },
    {
      "op": "replace",
      "path": "/fields/Microsoft.VSTS.TCM.AutomationStatus",
      "value": "Not Automated"
    },
    {
      "op": "remove",
      "path": "/fields/Custom.AutomationStatus"
    }
  ]
}
```

**When to use:** When the user explicitly asks to reset, clear, or un-automate a test case.

---

## Example Workflow

```
User: "Create an MCAT for test case 54321"

You:
1. Call mcp_azure_devops_wit_get_work_item(id=54321, project="PPM", fields=["Microsoft.VSTS.TCM.Steps"])
2. Parse the XML from Microsoft.VSTS.TCM.Steps and list the retrieved steps
3. Search workspace for existing MCAT patterns
4. Read .editorconfig
5. Generate MCAT code with copyright and <AI Assisted Code> comment
6. Build with dotnet build .
7. Ask: "The MCAT file has been created as ValidateUserLogin.cs. Would you like to change the name?"
8. [If user approves or provides new name]
9. (Optional) Run MCATRunner, read MCATSummary.log, debug if needed
```

```
User: "Get automation details for 3763333"

You:
1. Call mcp_azure_devops_wit_get_work_item(id=3763333, project="PPM", fields=[automation fields])
2. Present the automation details in a table
```

```
User: "Reset automation details for 3763333"

You:
1. Call mcp_azure_devops_wit_update_work_item with remove ops for test fields + set AutomationStatus to "Not Automated"
2. Confirm the reset was successful
```

## Success Criteria

### MCAT Generation

- ✅ Test case steps are retrieved and listed
- ✅ Workspace search found relevant reference files
- ✅ MCAT code is generated following workspace patterns
- ✅ Code includes copyright header and AI assistance comment
- ✅ Code follows .editorconfig standards
- ✅ Build succeeds without errors
- ✅ User confirms or updates filename
- ✅ (Optional) Test runs successfully via MCATRunner

### Automation Details Operations

- ✅ Get: All 6 automation fields are retrieved and presented clearly
- ✅ Update: Specified fields are updated and confirmed
- ✅ Reset: All test fields are cleared and AutomationStatus is set to "Not Automated"
