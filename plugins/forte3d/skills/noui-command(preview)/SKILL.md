---
name: noui-command
description: Writes S3Dx NoUI (no user interface) commands in C# using BaseFrameworkCommand with CommandUILayout.NoUI. Use when the user asks to create a NoUI command, background command, fire-and-forget command, batch operation command, or any command that runs without a ribbon/dialog UI. Also trigger when they mention CommandUILayout.NoUI, or non-interactive command patterns.
---
# S3Dx NoUI Command Writing Skill

This skill writes NoUI commands — commands that execute without a user interface (no ribbon, no dialog). These range from simple clipboard operations to complex graphic-view interactions and batch processing with progress bars.

## When to Use This Skill

Use this skill when the user:

- Asks to create a command with no UI / NoUI / background command
- Needs a fire-and-forget operation (copy, clipboard, delete)
- Wants a transactional command that commits without user interaction
- Needs batch processing with a progress bar
- Wants view manipulation (pan, rotate, zoom) commands
- Needs interactive graphical selection without a ribbon
- Mentions command continuation / chaining commands
- Asks for a delete command, undo command, or utility command

## Quick Decision: Which NoUI Pattern?

Ask these questions to determine the right pattern: (Must if you dont have proper context)

1. **Does it interact with the graphic view via mouse?**

   - View manipulation (pan/rotate/zoom) → **Category 4: Graphic View Interaction**
   - Object/point picking → **Category 5: Interactive Selection**
   - No → continue to 2
2. **Does it modify the database?**

   - NO → **Category 1: Fire-and-Forget**
   - YES → continue to 3
3. **Does it process many objects and need a progress bar?**

   - YES → **Category 6: Batch with Progress**
   - NO → continue to 4
4. **Does it need to chain to another command afterward?**

   - YES → **Category 3: Command Continuation**
   - NO → continue to 5
5. **Does it show a dialog for user input?**

   - YES → **Category 7: ViewModel/Dialog-Based**
   - NO → **Category 2: Transactional with Commit**

## Constructor Selection

**Most commands** (no graphic interaction):

```csharp
public MyCommand()
    : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }
```

**Graphic view commands** (mouse events or selection):

```csharp
public MyCommand()
    : base(uiLayout: CommandUILayout.NoUI,
           supportFlags: CommandSupportFlags.Graphic,
           suspendable: false)
{
    CanSuspendActiveCommand = true;
}
```

> Modal commands cannot have `CommandSupportFlags.Graphic` — modal blocks graphic events.

## Writing a NoUI Command

### Step 1: Determine the Category

Use the decision flow above.

### Step 2: Clarify Business Logic

If the user's input does not clearly describe what the command should do, ask clarifying questions before writing code. Examples:

- What objects does this command operate on? (selected objects, all objects in a workspace, specific type?)
- What should happen to those objects? (delete, modify a property, copy data, navigate the view?)
- Should the operation be undoable (transactional) or not?
- Does it need a progress bar for large sets?
- Should it work on the current selection or prompt the user to pick something graphically?
- Are there any validation rules or error conditions to handle?

Do not guess business logic. Get clarity first, then proceed.

### Step 3: Choose Constructor

Two choices cover almost all cases:

- **Modal + non-suspendable** — Categories 1, 2, 3, 6, 7
- **Graphic + CanSuspendActiveCommand** — Categories 4, 5

### Step 4: Implement Using the Category Pattern

Read **[noui-command-patterns.md](references/noui-command-patterns.md)** for the full pattern code for each category. Here is the general structure all NoUI commands follow:

```csharp
public class MyNoUICommand : BaseFrameworkCommand
{
    public MyNoUICommand()
        : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);

        // For transactional commands:
        CommitUndoMarker = "My Operation";
        CommitSuccessMessage = "Success.";
        CommitFailureMessage = "Failed.";

        using (BOCollection selectedObjects = ClientServiceProvider.SelectSet.SelectedObjects)
        {
            if (selectedObjects.Count == 0)
            {
                AbortUnsavedChanges();
                return;
            }

            foreach (BusinessObject bo in selectedObjects)
            {
                // Modify objects
            }
        }

        CommitUnsavedChanges();
        // Framework auto-stops the command when OnStart returns
    }

    public override void OnStop()
    {
        // Unsubscribe from events, clean up resources
        base.OnStop();
    }
}
```

> For non-transactional commands (Category 1), omit the commit markers and `CommitUnsavedChanges()`.

## Common Services

```csharp
// Selected objects (always dispose with 'using')
using (BOCollection selected = ClientServiceProvider.SelectSet.SelectedObjects) { }

// Toast notifications
ClientServiceProvider.MessageService.ShowMessage("Message", UxtMessageType.Information);

// Clipboard
ClientServiceProvider.ClipboardService.SetText(text);
Clipboard.SetDataObject(text);  // System.Windows.Clipboard — used by CopyPartNumberCommand

// Graphic view
ClientServiceProvider.GraphicViewMgr.ActiveGraphicView;

// Preferences
ClientServiceProvider.Preferences.GetBooleanValue("PrefKey", defaultValue);
ClientServiceProvider.Preferences.SetValue("PrefKey", newValue);

// Site/Plant model
MiddleServiceProvider.SiteMgr.ActiveSite.ActivePlant;
```

## Commit Patterns

```csharp
// Standard commit
CommitUnsavedChanges();

// Suppress notification, show custom message
CommitUnsavedChanges(suppressNotification: true);
ClientServiceProvider.MessageService.ShowMessage("Custom msg", UxtMessageType.Information);

// Per-item commit in batch loop (empty undo marker for subsequent commits)
ClientCommandExtensions.CommitChangesWithEmptyUndoMarker(this);

// Abort (rollback) when nothing changed or on error
AbortUnsavedChanges();
```

## Coding Guidelines

All generated code must follow **[csharp-coding-guidelines.md](../../../shared/coding-guidelines/csharp-coding-guidelines.md)** — covers file header, naming conventions, `var` usage, braces/formatting, expression style, modifiers, usings, and the single exit point rule.

## Key Rules

1. **Always dispose `BOCollection`** with `using` statements
2. **Always unsubscribe events** in OnStop
3. **Set `CommitUndoMarker` before calling `CommitUnsavedChanges()`** — it is required
4. **Do NOT call `StopCommand()`** in most NoUI commands — the framework auto-stops modal commands when `OnStart` returns. Only call it in Category 5 (interactive selection) and Category 7 (non-modal dialog) where the command stays alive waiting for user input
5. **Modal commands cannot have `CommandSupportFlags.Graphic`** — graphic events won't fire on modal commands
6. **Set `CanSuspendActiveCommand = true`** for view manipulation and selection commands

## Reference Files

- **[noui-command-patterns.md](references/noui-command-patterns.md)** — Complete reference with all 7 category patterns, constructor variations, decision flowchart, ProgressListener API, StopCommand() guidance, and common patterns. Always load this.
- **[list-of-services.md](../shared/common/list-of-services.md)** — Load when the command uses framework services beyond what the pattern template shows (SelectSet, WaitCursor, MessageService, GraphicViewMgr, Preferences, etc.).
