---
name: dialog-command
description: >
  Writes S3Dx Dialog Commands in C# using BaseFrameworkCommand with CommandUILayout.Dialog.
  Use this skill whenever the user asks to create a dialog command, modal dialog command, dialog-based command,
  command with a dialog window, or any command that shows a dialog UI.
  Also trigger when they mention CommandUILayout.Dialog, DialogContent, CommandDialogContentViewModel,
  OnDialogCompletion, dialog command pattern, ShowModal, modal command with dialog,
  or S3Dx dialog-based client command development. Even if the user just says "create a command with a dialog"
  or "I need a command that opens a dialog", use this skill.
---
# S3Dx Dialog Command Writing Skill

This skill writes Dialog Commands — commands that present a dialog window to the user for focused tasks like batch operations, configuration, repair utilities, revision management, and settings dialogs.

## Workflow

### Step 1: Determine the Dialog Pattern

Ask the user these questions (skip any already answered):

1. **Is the dialog simple and self-contained (user fills form, clicks OK)?**
   → **Pattern A: Simple Modal Dialog** — stop here
2. **Does the dialog need an Apply button (apply without closing)?**
   → **Pattern B: Non-Modal Dialog with Apply** — continue to 3
3. **Does the dialog need to suspend for other commands (e.g., graphic selection while dialog stays open)?**
   → **Pattern C: Suspendable Dialog** (includes continuation support)
4. **Is this a base class for a family of similar commands (e.g., Revisions vs Issues)?**
   → **Pattern D: Abstract Base Dialog**
5. **Does a non-modal dialog need to save/restore state when externally stopped?**
   → **Pattern E: Non-Modal with Continuation** (Pattern B + continuation events)

If unsure, default to **Pattern A** for simple tasks or **Pattern B** for anything with Apply.

### Step 2: Gather Command Details

Ask for (skip what's already known):

- Command class name (must end with `Command`)
- Namespace
- What the dialog does (business logic summary)
- Whether it modifies the database (needs CommitUndoMarker)
- For Pattern D: what variants are needed (e.g., "Revisions and Issues")

### Step 3: Generate the Command

Use the reference files below **only as needed** — load them when the relevant aspect is required for the command being generated:

- **[dialog-command-patterns.md](references/dialog-command-patterns.md)** — Load when you need the full copy-paste template for the chosen pattern (A–E). Always load this.
- **[base-framework-command.md](../shared/common/base-framework-command.md)** — Load when you need details on lifecycle methods, property management, or commit/compute workflows that are not covered by the pattern template.
- **[list-of-group-view-models.md](../shared/common/list-of-group-view-models.md)** — Load when the command needs selection, point picking, sketching, or specialized GroupViewModel behavior.
- **[list-of-command-controls.md](../shared/common/list-of-command-controls.md)** — Load when the dialog content ViewModel needs UI controls (grids, combos, text boxes, buttons, list boxes, etc.) **and** when the dialog ribbon needs specific UI controls.
- **[list-of-services.md](../shared/common/list-of-services.md)** — Load when the command uses framework services (SelectSet, WaitCursor, MessageService, TransactionMgr, etc.).
- **[csharp-coding-guidelines.md](../shared/coding-guidelines/csharp-coding-guidelines.md)** — Load when generating or reviewing C# code to enforce naming, formatting, and style rules.

Adapt the chosen pattern template to the user's requirements.

### Step 4: Remind About Command Registration

After writing the command, remind the user to register it using the `s3dx-command-entry` skill (Commands.xml + Ribbon.xml).

## Constructor Rules

| Pattern | Constructor                                                    | ShowModal()            |
| ------- | -------------------------------------------------------------- | ---------------------- |
| A       | `modal: true, suspendable: false`                            | YES — call in OnStart |
| B       | `CommandUILayout.Dialog, CommandSupportFlags.None`           | NO                     |
| C       | `modal: false, suspendable: true`                            | NO                     |
| D       | base sets `CommandUILayout.Dialog`; derived calls `base()` | NO                     |
| E       | `CommandUILayout.Dialog, CommandSupportFlags.None`           | NO                     |

**Constraints enforced by the framework:**

- `modal: true` requires `suspendable: false` — throws `ArgumentException` otherwise
- `modal: true` cannot have `CommandSupportFlags.Graphic` — modal blocks graphic events
- `modal: true` cannot have `CommandUILayout.Floating` — throws if both set

## DialogContent — Set Once Only

`DialogContent` is of type `CommandDialogContentViewModel`. It can only be set ONCE per command lifetime — setting it again throws `CmnInvalidArgumentException`, setting to null throws `CmnArgumentNullException`.

The ViewModel controls:

- `HasPendingChangesToApply` — enables/disables Apply/OK buttons
- `DialogButtons` — which buttons appear (OKCancel, ApplyAndCloseApplyCancel, etc.)
- `DialogTitle` — auto-set from `DisplayName` if set after assigning DialogContent
- `IsApplyOrOkEnabled` — controls whether Apply/OK buttons are enabled

**Modal (Pattern A):** assign DialogContent then call `ShowModal()` — blocks until dialog closes.
**Non-modal (B/C/D/E):** assign DialogContent only — framework shows it automatically.

## OnDialogCompletion Patterns

Called by the framework when the user clicks a dialog button:

| User Action     | applyChanges | closeDialog |
| --------------- | ------------ | ----------- |
| OK              | true         | true        |
| Apply           | true         | false       |
| Apply and Close | true         | true        |
| Cancel / X      | false        | true        |

Return `true` to allow close, `false` to keep dialog open. See **[dialog-command-patterns.md](references/dialog-command-patterns.md)** for full code examples.

## Dialog Content ViewModel Structure

The dialog content ViewModel (the class that derives from `CommandDialogContentViewModel`) defines **both the business logic and the content structure** of the dialog. The preferred approach for building the dialog UI is:

### Preferred: Common Controls ViewModels as Properties

Use common controls ViewModels from `Ingr.SP3D.Common.Client.ViewModels` as **properties** on the dialog content ViewModel. The XAML DataTemplate renders them via `<ContentControl Content="{Binding SomeControlViewModel}"/>`. The framework's built-in DataTemplates handle the visual rendering automatically — no custom WPF `UserControl` is needed.

```csharp
using Ingr.SP3D.Common.Client;
using Ingr.SP3D.Common.Client.ViewModels;
using System.Diagnostics.CodeAnalysis;

namespace Your.Namespace
{
    internal class MyOperationViewModel : CommandDialogContentViewModel
    {
        // Expose common controls ViewModels as properties
        [ExcludeFromCodeCoverage]
        public CommandComboBoxViewModel OperationTypeComboBoxViewModel { get; private set; }

        [ExcludeFromCodeCoverage]
        public CommandTextBoxViewModel NameTextBoxViewModel { get; private set; }

        [ExcludeFromCodeCoverage]
        public CommandGridViewModel<MyRowItem> ResultsGridViewModel { get; private set; }

        [ExcludeFromCodeCoverage]
        public CommandButtonViewModel RunButtonViewModel { get; private set; }

        public MyOperationViewModel(BaseFrameworkCommand parentCommand) : base(parentCommand)
        {
            DialogButtons = CommandDialogButtons.ApplyAndCloseCancel;
            CanResize = true;
            Width = 600;
            Height = 400;

            OperationTypeComboBoxViewModel = new CommandComboBoxViewModel(this, CommandComboBoxViewModel.CommandComboBoxType.StandardText)
            {
                ShowLabel = true,
                LabelText = MyLocalizer.GetInstance().OperationTypeLabel
            };
            new CommandComboBoxItem(OperationTypeComboBoxViewModel, MyLocalizer.GetInstance().OptionA);
            new CommandComboBoxItem(OperationTypeComboBoxViewModel, MyLocalizer.GetInstance().OptionB);

            NameTextBoxViewModel = new CommandTextBoxViewModel(this)
            {
                ShowLabel = true,
                LabelText = MyLocalizer.GetInstance().NameLabel
            };

            ResultsGridViewModel = new CommandGridViewModel<MyRowItem>(this);

            RunButtonViewModel = new CommandButtonViewModel(this, CommandButtonViewModel.CommandButtonType.Standard)
            {
                DisplayName = MyLocalizer.GetInstance().RunButtonLabel,
                IsEnabled = false
            };
        }

        internal void ApplyChanges()
        {
            // Business logic using NameTextBoxViewModel.Text, OperationTypeComboBoxViewModel.SelectedItem, etc.
        }
    }
}
```

The corresponding DataTemplate in a `ResourceDictionary` XAML file binds to these properties using `ContentControl`:

```xml
<DataTemplate DataType="{x:Type vm:MyOperationViewModel}">
    <StackPanel Margin="8">
        <ContentControl Content="{Binding OperationTypeComboBoxViewModel}"/>
        <ContentControl Content="{Binding NameTextBoxViewModel}"/>
        <ContentControl Content="{Binding ResultsGridViewModel}"/>
        <ContentControl HorizontalAlignment="Right" Content="{Binding RunButtonViewModel}"/>
    </StackPanel>
</DataTemplate>
```

### Fallback: WPF UserControl

Only use a custom WPF `UserControl` when the required UI layout **cannot** be expressed with the available common controls ViewModels (e.g., complex custom-drawn visuals, third-party controls not wrapped by a ViewModel, or intricate layout that has no ViewModel equivalent). In this case, expose the UserControl directly from the DataTemplate, binding to the ViewModel's data properties as normal.

### Common Controls ViewModel Decision Guide

| UI need                | Common controls ViewModel to use      |
| ---------------------- | ------------------------------------- |
| Text input             | `CommandTextBoxViewModel`           |
| Numeric input          | `CommandNumericInputViewModel`      |
| Drop-down selection    | `CommandComboBoxViewModel`          |
| Multi-select checklist | `CommandInputChecklistViewModel`    |
| Check box              | `CommandCheckBoxViewModel`          |
| Radio buttons          | `CommandDialogRadioButtonViewModel` |
| Tabular data           | `CommandGridViewModel<T>`           |
| List of items          | `CommandListBoxViewModel`           |
| Action button          | `CommandButtonViewModel`            |
| Toggle button          | `CommandToggleButtonViewModel`      |
| Static text            | `CommandTextBlockViewModel`         |
| Date/time picker       | `CommandDateTimePickerViewModel`    |
| Color picker           | `CommandColorPickerViewModel`       |

**Always load [list-of-command-controls.md](../s3dx-shared/common/list-of-command-controls.md) before choosing controls** — it lists every available ViewModel with descriptions and file paths.

## Key Rules

1. **DialogContent can only be set ONCE** — setting it twice throws an exception
2. **Call ShowModal() only for Pattern A (modal: true)** — non-modal dialogs are shown automatically
3. **Always call base.OnStart() and base.OnStop()** — the framework manages critical lifecycle state
4. **Return true from OnDialogCompletion to allow close** — return false to keep dialog open
5. **Set CommitUndoMarker before CommitUnsavedChanges()** — required, throws if null
6. **Check DialogCompletionInitiated in OnStop** — distinguishes user close from external stop
7. **Use [ExcludeFromCodeCoverage]** on constructors and simple property accessors
8. **Wrap exception-prone code in try/catch in OnStart** — show error and abort gracefully
9. **Prefer common controls ViewModels over WPF UserControls** — use `CommandGridViewModel<T>`, `CommandComboBoxViewModel`, `CommandTextBoxViewModel` etc. as properties on the dialog content ViewModel; only fall back to a custom WPF `UserControl` when no suitable ViewModel exists
