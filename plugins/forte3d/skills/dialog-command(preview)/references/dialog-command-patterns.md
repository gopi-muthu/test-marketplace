# Dialog Command Patterns — Reference

> This file contains full pattern implementations. SKILL.md covers constructor selection, decision trees, OnDialogCompletion variants, and lifecycle methods. This file provides copy-paste-ready templates and the command-to-pattern mapping table.

---

## Command-to-Pattern Mapping

| #  | Command                                         | Pattern     | File Path                                                                                                                                               |
| -- | ----------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | SelectByFiltersCommand                          | A           | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/SelectByFiltersCommand.cs                                                     |
| 2  | ApplySurfaceStyleRulesCommand                   | B+E         | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/SurfaceStyle/ApplySurfaceStyleRulesCommand.cs                                 |
| 3  | BaseModelDataCommand (abstract)                 | D (base)    | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/BaseModelDataCommand.cs                                                       |
| 4  | ModelDataReuseCommand                           | D (derived) | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ModelDataReuseCommand.cs                                                      |
| 5  | ModelDataTransformCommand                       | D (derived) | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ModelDataTransformCommand.cs                                                  |
| 6  | ClaimCommand                                    | A           | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AsBuiltCommands/ClaimCommand.cs                                               |
| 7  | ReleaseCommand                                  | A           | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AsBuiltCommands/ReleaseCommand.cs                                             |
| 8  | ShowClaimedItems                                | A           | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AsBuiltCommands/ShowClaimedItems.cs                                           |
| 9  | SetDesignReviewStatusCommand                    | A           | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AsBuiltCommands/SetDesignReviewStatusCommand.cs                               |
| 10 | ProjectOperationsCommand                        | A           | MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AsBuiltCommands/ProjectOperationsCommand.cs                                   |
| 11 | DefineAllowedSpecificationsCommand              | B           | MRoot/SystemsAndSpecs/Client/SystemClientCommands/SystemClientCommands/DefineAllowedSpecificationsCommand.cs                                            |
| 12 | NozzleTableCommand                              | C+E         | MRoot/Equipment/Client/Commands/EquipmentClientCommands/EquipmentClientCommands/NozzleTableCommand.cs                                                   |
| 13 | DrawingsBatchCommand                            | B           | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsBatchCommand.cs                                           |
| 14 | DrawingsPrintCommand                            | A           | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsPrintCommand.cs                                           |
| 15 | DrawingsSaveAsCommand                           | A           | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsSaveAsCommand.cs                                          |
| 16 | DrawingsSwitchBorderCommand                     | A           | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsSwitchBorderCommand.cs                                    |
| 17 | DrawingsValidateAndRepairCommand                | B           | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsValidateAndRepairCommand.cs                               |
| 18 | DeliverableComponentRevisionAndIssueCommandBase | D (base)    | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DeliverableComponentRevisionAndIssueCommand.cs                    |
| 19 | DeliverableComponentIssuesCommand               | D (derived) | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DeliverableComponentRevisionAndIssueCommand.cs                    |
| 20 | DeliverableComponentRevisionsCommand            | D (derived) | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DeliverableComponentRevisionAndIssueCommand.cs                    |
| 21 | DeliverableRevisionAndIssueCommandBase          | D (base)    | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DeliverableRevisionAndIssueCommand.cs                             |
| 22 | DeliverableRevisionsCommand                     | D (derived) | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DeliverableRevisionAndIssueCommand.cs                             |
| 23 | DeliverableIssuesCommand                        | D (derived) | MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DeliverableRevisionAndIssueCommand.cs                             |
| 24 | GridSystemCommand                               | C+E         | SRoot/GridSystem/Client/Commands/GridSystemClientCommands/GridSystemClientCommands/GridSystemCommand.cs                                                 |
| 25 | RepairSmartInteropSlabsAndWallsCommand          | C+E         | SRoot/SmartPlantStructure/Client/Commands/SmartPlantStructureClientCommands/SmartPlantStructureClientCommands/RepairSmartInteropSlabsAndWallsCommand.cs |
| 26 | InterferenceManagerCommand                      | B           | Kroot/FoulCheck/Client/Commands/InterferenceClientCommands/InterferenceClientCommands/Command/InterferenceManagerCommand.cs                             |
| 27 | BaseGenerateSpoolsCommand (abstract)            | D (base)    | Kroot/CommonRoute/Client/Commands/CommonRouteClientCommands/CommonRouteClientCommands/CommonRoute/Commands/BaseGenerateSpoolsCommand.cs                 |
| 28 | GeneratePipeSpoolsCommand                       | D (derived) | Kroot/CommonRoute/Client/Commands/CommonRouteClientCommands/CommonRouteClientCommands/Piping/Commands/GeneratePipeSpoolsCommand.cs                      |
| 29 | GenerateDuctSpoolsCommand                       | D (derived) | Kroot/CommonRoute/Client/Commands/CommonRouteClientCommands/CommonRouteClientCommands/Ducting/Commands/GenerateDuctSpoolsCommand.cs                     |
| 30 | ConnectRacewaysCommand                          | B           | Kroot/CommonRoute/Client/Commands/CommonRouteClientCommands/CommonRouteClientCommands/Electrical/Commands/ConnectRacewaysCommand.cs                     |

---

## Pattern A: Simple Modal Dialog

```csharp
using System;
using System.Diagnostics.CodeAnalysis;
using Ingr.SP3D.Common.Client;
using Ingr.SP3D.Common.Client.Services;
using Ingr.SP3D.Common.Middle;
using Intergraph.UX.WPF.Toolkit;

namespace Your.Namespace
{
    /// <summary>
    /// Description of what this command does.
    /// </summary>
    public class MyModalDialogCommand : BaseFrameworkCommand
    {
        [ExcludeFromCodeCoverage]
        public MyModalDialogCommand()
            : base(uiLayout: CommandUILayout.Dialog, modal: true, suspendable: false)
        {
        }

        [ExcludeFromCodeCoverage]
        public override void OnStart(int instanceId, object argument)
        {
            base.OnStart(instanceId, argument);

            // Optional: capture selected objects
            // var selectedObjects = GetSelectedObjects(argument);

            DialogContent = new MyModalDialogViewModel(this);
            DialogContent.ShowModal();

            // Code here runs AFTER the dialog closes
            // e.g., SelectByFiltersCommand processes filter results here
        }

        [ExcludeFromCodeCoverage]
        protected override bool OnDialogCompletion(bool applyChanges, bool closeDialog)
        {
            if (applyChanges)
            {
                ((MyModalDialogViewModel)DialogContent).ExecuteOperation();
            }
            return true;
        }

        [ExcludeFromCodeCoverage]
        protected override void OnViewLoaded()
        {
            ((MyModalDialogViewModel)DialogContent).InitializeUI();
        }
    }
}
```

**Pattern A notes:**

- `ShowModal()` blocks OnStart until the user closes the dialog
- Code after `ShowModal()` runs post-close — use for result processing
- The framework auto-stops the command when the modal dialog closes
- For result-flag pattern: set `ViewModel.Result = true` in OnDialogCompletion, check it after ShowModal()

---

## Pattern B: Non-Modal Dialog with Apply

```csharp
using System;
using System.Diagnostics.CodeAnalysis;
using Ingr.SP3D.Common.Client;
using Ingr.SP3D.Common.Client.Services;
using Intergraph.UX.WPF.Toolkit;

namespace Your.Namespace
{
    /// <summary>
    /// Description of what this command does.
    /// </summary>
    internal class MyApplyDialogCommand : BaseFrameworkCommand
    {
        private MyApplyDialogViewModel _viewModel;

        [ExcludeFromCodeCoverage]
        public MyApplyDialogCommand()
            : base(CommandUILayout.Dialog, CommandSupportFlags.None)
        {
        }

        public override void OnStart(int instanceId, object argument)
        {
            base.OnStart(instanceId, argument);

            CommitUndoMarker = MyLocalizer.GetInstance().MyOperationUndoMarker;
            CommitSuccessMessage = MyLocalizer.GetInstance().MyOperationSuccessMessage;

            _viewModel = new MyApplyDialogViewModel(this);
            DialogContent = _viewModel;

            ClientServiceProvider.SelectSet.Clear();
        }

        public override void OnStop()
        {
            base.OnStop();
            _viewModel.Cleanup();
        }

        protected override bool OnDialogCompletion(bool applyChanges, bool closeDialog)
        {
            if (applyChanges)
            {
                try
                {
                    _viewModel.ApplyChanges();
                    _viewModel.IsApplyOrOkEnabled = false;
                }
                catch (Exception ex)
                {
                    ClientServiceProvider.ErrHandler.LogError(
                        "OnDialogCompletion", ex.HResult, ex.StackTrace);
                    ShowMessage("ApplyFailed", UxtMessageType.Error, "Operation failed.");
                }
            }
            return true;
        }
    }
}
```

**Pattern B notes:**

- Do NOT call `ShowModal()` — the framework shows the dialog automatically
- The command stays alive after OnStart returns
- Set `CommitUndoMarker` in OnStart if the command modifies the database
- Use `IsApplyOrOkEnabled = false` to disable Apply after successful apply

---

## Pattern C: Suspendable Dialog (with Continuation)

Pattern C commands are always combined with continuation logic (Pattern E) in the real codebase. This template includes both.

```csharp
using System;
using System.Diagnostics.CodeAnalysis;
using Ingr.SP3D.Common.Client;
using Ingr.SP3D.Common.Client.Services;
using Ingr.SP3D.Common.Middle;
using Intergraph.CommonToolkit.Client.Events;
using Intergraph.UX.WPF.Toolkit;

namespace Your.Namespace
{
    /// <summary>
    /// A suspendable dialog command with continuation support.
    /// </summary>
    public class MySuspendableDialogCommand : BaseFrameworkCommand
    {
        private BusinessObject _selectedObject = null;

        [ExcludeFromCodeCoverage]
        private MySuspendableViewModel ViewModel { get; set; }

        [ExcludeFromCodeCoverage]
        public MySuspendableDialogCommand()
            : base(CommandUILayout.Dialog, CommandSupportFlags.None,
                   modal: false, suspendable: true)
        {
        }

        public override void OnStart(int instanceId, object argument)
        {
            base.OnStart(instanceId, argument);
            ClientServiceProvider.SelectSet.Clear();

            // Subscribe to continuation restore event
            EventAccumulator.Instance.GetEvent<CommandContinuationRestoreEvent>()
                .Subscribe(OnCommandStateRestore);

            ViewModel = new MySuspendableViewModel(this);
            DialogContent = ViewModel;

            CommitUndoMarker = MyLocalizer.GetInstance().UndoMarker;
            CommitSuccessMessage = MyLocalizer.GetInstance().SuccessMessage;
        }

        protected override bool OnDialogCompletion(bool applyChanges, bool closeDialog)
        {
            if (applyChanges)
            {
                try
                {
                    bool isSuccess = ViewModel.ExecuteOperation();
                    if (isSuccess)
                    {
                        CommitUnsavedChanges();
                    }
                }
                catch (Exception exception)
                {
                    ClientServiceProvider.ErrHandler.LogError(
                        "OnDialogCompletion", exception.HResult, exception.StackTrace);
                    ShowMessage("OperationFailed", UxtMessageType.Error,
                        MyLocalizer.GetInstance().OperationFailedMessage);
                }
            }
            ViewModel.Cleanup();
            return true;
        }

        [ExcludeFromCodeCoverage]
        public override void OnStop()
        {
            base.OnStop();
            ViewModel.ClearHighlights();

            if (DialogCompletionInitiated)
            {
                ClientServiceProvider.SelectSet.Clear();
            }
            else
            {
                // Externally stopped — publish continuation save
                var continuationArgs = new MyContinuationEventArguments(
                    nameof(MySuspendableDialogCommand), null);
                EventAccumulator.Instance.GetEvent<CommandContinuationSaveEvent>()
                    .Publish(continuationArgs);
            }
        }

        protected void OnCommandStateRestore(CommandContinuationEventArgs args)
        {
            if (args is MyContinuationEventArguments myArgs)
            {
                ViewModel.RestoreState(myArgs);
            }
        }

        [ExcludeFromCodeCoverage]
        public override void OnSuspend()
        {
            base.OnSuspend();
            _selectedObject = ViewModel.ClearSelectionOnSuspend();
        }

        [ExcludeFromCodeCoverage]
        public override void OnResume()
        {
            base.OnResume();
            ClientServiceProvider.WorkingSet.Refresh(WorkingSet.UpdateQuery.DefaultUpdate);
            if (_selectedObject != null)
            {
                ViewModel.HighlightObject(_selectedObject);
            }
        }
    }
}
```

**Pattern C notes:**

- `OnSuspend` saves state before another command takes over
- `OnResume` restores state and refreshes data
- `DialogCompletionInitiated` in OnStop distinguishes user close from external stop
- Continuation events allow state restore when the command is restarted after external stop

---

## Pattern D: Abstract Base Dialog

**Base class:**

```csharp
using System;
using System.Diagnostics.CodeAnalysis;
using Ingr.SP3D.Common.Client;
using Intergraph.UX.WPF.Toolkit;

namespace Your.Namespace
{
    /// <summary>
    /// Base command for a family of related dialog commands.
    /// </summary>
    internal abstract class BaseMyFamilyCommand : BaseFrameworkCommand
    {
        [ExcludeFromCodeCoverage]
        public BaseMyFamilyCommand()
            : base(uiLayout: CommandUILayout.Dialog, supportFlags: CommandSupportFlags.None)
        {
        }

        public abstract MyHelper Helper { get; internal set; }
        public abstract BaseMyFamilyViewModel ViewModel { get; }
        protected abstract string ErrorKey { get; }
        protected abstract string ErrorMessage { get; }
        protected abstract void SetCommandStrings();

        public override void OnStart(int commandID, object argument)
        {
            base.OnStart(commandID, argument);
            try
            {
                SetCommandStrings();
                DialogContent = ViewModel;
            }
            catch (Exception e)
            {
                e.Log();
                ShowMessage(ErrorKey, UxtMessageType.Error, ErrorMessage);
            }
        }

        public override void OnStop()
        {
            base.OnStop();
            ViewModel.Cleanup();
            Helper.Dispose();
            Helper = null;
        }
    }
}
```

**Derived class:**

```csharp
using System.Diagnostics.CodeAnalysis;

namespace Your.Namespace
{
    /// <summary>
    /// Concrete implementation for a specific variant.
    /// </summary>
    [ExcludeFromCodeCoverage]
    internal class MySpecificCommand : BaseMyFamilyCommand
    {
        private MySpecificHelper _helper = null;
        private MySpecificViewModel _viewModel = null;

        public MySpecificCommand() : base() { }

        public override MyHelper Helper
        {
            get => _helper ??= new MySpecificHelper();
            internal set => _helper = (MySpecificHelper)value;
        }

        public override BaseMyFamilyViewModel ViewModel
            => _viewModel ??= new MySpecificViewModel(this);

        protected override string ErrorKey => "FailedToStartMySpecific";
        protected override string ErrorMessage => MyLocalizer.GetInstance().StartError;

        protected override void SetCommandStrings()
        {
            DisplayName = MyLocalizer.GetInstance().CommandTitle;
            CommitUndoMarker = MyLocalizer.GetInstance().CommitMarker;
        }
    }
}
```

**Pattern D notes:**

- Base class handles common lifecycle (OnStart, OnStop, error handling)
- Derived classes provide ViewModel, Helper, and localized strings via abstract members
- Use lazy initialization (`??=`) for ViewModel and Helper properties
- Derived constructors call `base()` — the base constructor sets `CommandUILayout.Dialog`
- If the derived class needs additional OnStart logic, override and call `base.OnStart()` first

---

## Pattern E: Continuation-Only (Non-Suspendable)

Use this when a non-modal, non-suspendable command (Pattern B) also needs continuation support. For suspendable commands, use Pattern C which already includes continuation.

```csharp
using System;
using System.Diagnostics.CodeAnalysis;
using Ingr.SP3D.Common.Client;
using Intergraph.CommonToolkit.Client.Events;

namespace Your.Namespace
{
    /// <summary>
    /// Non-modal dialog with continuation support for external stop recovery.
    /// </summary>
    internal class MyContinuationDialogCommand : BaseFrameworkCommand
    {
        private MyContinuationViewModel _viewModel;

        [ExcludeFromCodeCoverage]
        public MyContinuationDialogCommand()
            : base(CommandUILayout.Dialog, CommandSupportFlags.None)
        {
        }

        public override void OnStart(int instanceId, object argument)
        {
            base.OnStart(instanceId, argument);

            EventAccumulator.Instance.GetEvent<CommandContinuationRestoreEvent>()
                .Subscribe(OnCommandStateRestore);

            _viewModel = new MyContinuationViewModel(this);
            DialogContent = _viewModel;

            ClientServiceProvider.SelectSet.Clear();
        }

        public override void OnStop()
        {
            base.OnStop();

            if (DialogCompletionInitiated != true)
            {
                var args = new MyContinuationEventArguments(
                    nameof(MyContinuationDialogCommand));
                EventAccumulator.Instance.GetEvent<CommandContinuationSaveEvent>()
                    .Publish(args);
            }
        }

        protected void OnCommandStateRestore(CommandContinuationEventArgs args)
        {
            if (args is MyContinuationEventArguments myArgs)
            {
                _viewModel.RestoreState(myArgs);
            }
        }

        protected override bool OnDialogCompletion(bool applyChanges, bool closeDialog)
        {
            if (applyChanges)
            {
                _viewModel.ApplyChanges();
            }
            return true;
        }
    }
}
```

**Pattern E notes:**

- This is Pattern B + continuation events
- Subscribe to `CommandContinuationRestoreEvent` in OnStart
- Publish `CommandContinuationSaveEvent` in OnStop when `DialogCompletionInitiated != true`
- Real example: `ApplySurfaceStyleRulesCommand`

---

## Constructor Quick Reference

| Pattern            | Constructor                                          | ShowModal() |
| ------------------ | ---------------------------------------------------- | ----------- |
| A: Modal           | `modal: true, suspendable: false`                  | YES         |
| B: Non-Modal Apply | default or `suspendable: false`                    | NO          |
| C: Suspendable     | `modal: false, suspendable: true`                  | NO          |
| D: Abstract Base   | `CommandUILayout.Dialog, CommandSupportFlags.None` | NO          |
| E: Continuation    | `CommandUILayout.Dialog, CommandSupportFlags.None` | NO          |
