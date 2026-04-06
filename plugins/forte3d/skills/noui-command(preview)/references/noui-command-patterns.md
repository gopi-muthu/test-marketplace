# NoUI Command Patterns Reference

## Overview

NoUI commands (`CommandUILayout.NoUI`) execute without a user interface. They range from simple clipboard operations to complex graphic-view interactions and batch processing. This reference documents all patterns extracted from 47 production NoUI commands.

> **Key fact**: The framework automatically stops modal NoUI commands when `OnStart` returns. You do NOT need to call `StopCommand()` in most cases. See the "When to Call StopCommand()" section for the rare exceptions.

## Constructor Variations

### Variation 1: Simple NoUI (Minimal)
```csharp
public MyCommand() : base(uiLayout: CommandUILayout.NoUI) { }
```
**When to use**: Simple commands with default behavior (non-modal, suspendable). Rare in production.
**Examples**: HelloWorldCommand, TransactionalCommand, NonTransactionalCommand

### Variation 2: Modal + Non-Suspendable (Most Common)
```csharp
public MyCommand() : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }
```
**When to use**: Most NoUI commands. Modal prevents interruption. Non-suspendable prevents pause/resume.
**Examples**: DeleteCommand, UndoCommand, CopyPartNumberCommand, ModifyInterferenceStatusCommand, CreateDrawingsCommand, DrawingsRefreshCommand, AddSelectedObjectsToWorkspaceCommand, CopyObjectIdentifiersCommand, RefreshAppliedStyleRulesCommand, ActiveWBSItemChangeCommand, ReferenceCoordinateSystemCommand, DrawingsDefaultCopyCommand, DrawingsEditCommand, DrawingsUpdateCommand, RunQueryCommand, ModifyInterferenceRemarksCommand, AddAllAllowedSpecificationsCommand, ReplaceTeeWithElbowCommand, QuickCopyCommand, ModalCommand

### Variation 3: With Graphic SupportFlags
```csharp
public MyCommand()
    : base(uiLayout: CommandUILayout.NoUI, supportFlags: CommandSupportFlags.Graphic, suspendable: false)
{
    CanSuspendActiveCommand = true;
}
```
**When to use**: Commands that interact with the graphic view (mouse events). NOT modal — modal blocks graphic events.
**Examples**: PanCommand, RotateCommand, ZoomCommand, ZoomAreaCommand, LookAtSurfaceCommand, SelectCoordinateSystemGraphicallyCommand

### Variation 4: With Full Flags (None + Modal)
```csharp
public MyCommand() : base(CommandUILayout.NoUI, CommandSupportFlags.None, modal: true, suspendable: false) { }
```
**When to use**: Explicitly specifying no graphic support while being modal. Used for transactional batch operations.
**Examples**: BaseWBSCommand, ConvertToMemberSystemCommand, ConvertWBSItemToWorkPackageCommand, CreateSpaceFolderCommand

---

## NoUI Command Categories

### Category 1: Fire-and-Forget

Non-transactional operation in OnStart. No commit needed.

```csharp
public class CopyDataCommand : BaseFrameworkCommand
{
    public CopyDataCommand()
        : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);

        using (BOCollection selectedObjects = ClientServiceProvider.SelectSet.SelectedObjects)
        {
            if (selectedObjects.Count == 0) return;

            // Perform non-transactional operation (clipboard, workspace, etc.)
            var result = BuildOutput(selectedObjects);
            ClientServiceProvider.ClipboardService.SetText(result);

            ClientServiceProvider.MessageService.ShowMessage(
                "Data copied to clipboard.", UxtMessageType.Information);
        }
    }
}
```

**Real examples**: CopyPartNumberCommand, CopyObjectIdentifiersCommand, AddSelectedObjectsToWorkspaceCommand, AddInterferingObjectsToWorkspaceCommand, DrawingsDefaultCopyCommand, DrawingsPasteUnsupportedCommand, QuickCopyCommand

**Key characteristics**:
- Work happens entirely in `OnStart`
- No commit — operations are non-transactional (clipboard, workspace, navigation)
- Framework auto-stops when `OnStart` returns

---

### Category 2: Transactional with Commit

Database-modifying operation with commit/abort.

```csharp
public class ModifyObjectCommand : BaseFrameworkCommand
{
    public ModifyObjectCommand()
        : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);

        CommitUndoMarker = "Modify Object";
        CommitSuccessMessage = "Object modified successfully.";
        CommitFailureMessage = "Failed to modify object.";

        using (BOCollection selectedObjects = ClientServiceProvider.SelectSet.SelectedObjects)
        {
            if (selectedObjects.Count == 0)
            {
                AbortUnsavedChanges();
                return;
            }

            foreach (BusinessObject bo in selectedObjects)
            {
                ModifyBusinessObject(bo);
            }
        }

        CommitUnsavedChanges();
    }
}
```

> For error handling, wrap the modification + commit in try/catch and call `AbortUnsavedChanges()` in the catch block.

**Real examples**: DeleteCommand, CreateSpaceFolderCommand, ConvertToMemberSystemCommand, AddAllAllowedSpecificationsCommand, ReplaceTeeWithElbowCommand, ConvertWBSItemToWorkPackageCommand, ModifyInterferenceStatusCommand, ModifyInterferenceRemarksCommand

**Key characteristics**:
- Set `CommitUndoMarker`, `CommitSuccessMessage`, `CommitFailureMessage` before commit
- Call `CommitUnsavedChanges()` after modifications
- Call `AbortUnsavedChanges()` on failure or when nothing changed

**Commit variations**:
```csharp
// Standard commit
CommitUnsavedChanges();

// Suppress default notification, show custom one
CommitUnsavedChanges(suppressNotification: true);
ClientServiceProvider.MessageService.ShowMessage("Custom message", UxtMessageType.Information);

// Commit with empty undo marker (for subsequent commits in a batch loop)
ClientCommandExtensions.CommitChangesWithEmptyUndoMarker(this);

// Abort when nothing changed
AbortUnsavedChanges();
```

---

### Category 3: Command Continuation

Save/restore state across command boundaries for chaining commands.

```csharp
public class ContinuationCommand : BaseFrameworkCommand
{
    private readonly SubscriptionToken _subscriptionToken;
    private object _restoredData;

    public ContinuationCommand()
        : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false)
    {
        _subscriptionToken = EventAccumulator.Instance
            .GetEvent<CommandContinuationRestoreEvent>()
            .Subscribe(OnCommandStateRestore);
    }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);
        CommitUndoMarker = "My Operation";

        // Use restored data if available, otherwise process normally
        if (_restoredData != null)
            ProcessWithRestoredState(_restoredData);
        else
            ProcessNormally();

        CommitUnsavedChanges();
    }

    public override void OnStop()
    {
        // Save state for continuation (only if not finishing via a completion button)
        if (CommandCompletionInitiated == CompletionFlags.None)
        {
            EventAccumulator.Instance.GetEvent<CommandContinuationSaveEvent>()
                .Publish(new MyContinuationEventArgs { SavedData = _restoredData });
        }

        _subscriptionToken?.Unsubscribe();
    }

    private void OnCommandStateRestore(CommandContinuationEventArgs args)
    {
        if (args is MyContinuationEventArgs myArgs)
            _restoredData = myArgs.SavedData;
    }
}
```

> Note: Subscribe in the constructor via `SubscriptionToken` and unsubscribe in `OnStop`.

**Real examples**: ActiveWBSItemChangeCommand, UndoCommand, RefreshAppliedStyleRulesCommand, DeleteCommand, ReferenceCoordinateSystemCommand, CreateDrawingsCommand

**Key characteristics**:
- Subscribe to `CommandContinuationRestoreEvent` (constructor)
- Publish `CommandContinuationSaveEvent` in `OnStop`
- Always unsubscribe in `OnStop`
- Custom event args class extends `CommandContinuationEventArgs`

---

### Category 4: Graphic View Interaction

Mouse-based view manipulation (pan, rotate, zoom).

```csharp
public class ViewManipulationCommand : BaseFrameworkCommand
{
    private GraphicView _view;
    private Point _previousScreenPoint;

    public ViewManipulationCommand()
        : base(uiLayout: CommandUILayout.NoUI,
               supportFlags: CommandSupportFlags.Graphic,
               suspendable: false)
    {
        CanSuspendActiveCommand = true;
    }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);
        // Initialize cursors, hiliters, etc.
    }

    public override void OnStop()
    {
        base.OnStop();
        // Dispose hiliters, restore cursors, clean up
    }

    protected override void OnMouseDown(
        GraphicView view,
        GraphicViewManager.GraphicViewEventArgs e,
        Position position)
    {
        if (e.Button == GraphicViewManager.GraphicViewEventArgs.MouseButtons.Left)
        {
            _view = view;
            _previousScreenPoint = new Point((int)e.X, (int)e.Y);
        }
    }

    protected override void OnMouseMove(
        GraphicView view,
        GraphicViewManager.GraphicViewEventArgs e,
        Position position)
    {
        if (e.Button == GraphicViewManager.GraphicViewEventArgs.MouseButtons.Left && _view == view)
        {
            // Perform view manipulation
            Camera camera = _view.Camera;
            camera.BeginModify();
            camera.ScreenPan((int)(e.X - _previousScreenPoint.X), (int)(e.Y - _previousScreenPoint.Y));
            camera.EndModify(false);

            _previousScreenPoint = new Point((int)e.X, (int)e.Y);
        }
    }

    protected override void OnMouseUp(
        GraphicView view,
        GraphicViewManager.GraphicViewEventArgs e,
        Position position)
    {
        if (e.Button == GraphicViewManager.GraphicViewEventArgs.MouseButtons.Left && _view == view)
        {
            _view.ManipulationStack.StoreViewState("My Manipulation");
        }
    }
}
```

**Real examples**: PanCommand, RotateCommand, ZoomCommand, ZoomAreaCommand

**Key characteristics**:
- Use `CommandSupportFlags.Graphic` — NOT modal (modal blocks graphic events)
- Set `CanSuspendActiveCommand = true` to temporarily suspend the current command
- Mouse event signature: `OnMouseDown(GraphicView view, GraphicViewManager.GraphicViewEventArgs e, Position position)`
- Check `e.Button` for left/middle/right mouse button
- Use `Camera.BeginModify()` / `Camera.EndModify(false)` for view changes
- Call `view.ManipulationStack.StoreViewState()` to enable Previous/Next view
- ZoomAreaCommand uses `view.CreateRectangularFence()` for rubber-band selection

---

### Category 5: Interactive Selection

User picks an object/point graphically, then the command acts on it and stops.

```csharp
public class SelectAndActCommand : BaseFrameworkCommand
{
    private GroupViewModel _selectGroup;

    public SelectAndActCommand()
        : base(uiLayout: CommandUILayout.NoUI,
               supportFlags: CommandSupportFlags.Graphic,
               suspendable: false)
    {
        CanSuspendActiveCommand = true;
    }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);

        _selectGroup = new GroupViewModel(Groups, "SelectGroup")
        {
            LocateBehavior = GroupLocateBehaviorType.LocateSelect, // or SmartSketch
            MaximumSelectable = 1
        };
        _selectGroup.SelectionChanged += OnSelectionChanged;
        _selectGroup.SetAsActiveGroup();
    }

    private void OnSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (e.SelectedObjects.Count > 0)
        {
            ProcessSelection(e.SelectedObjects[0]);
            StopCommand(); // Required — command stays alive waiting for input
        }
    }

    public override void OnStop()
    {
        if (_selectGroup != null)
            _selectGroup.SelectionChanged -= OnSelectionChanged;
        base.OnStop();
    }
}
```

> `StopCommand()` IS required here — this is one of the few cases. The command stays alive waiting for asynchronous user input, so it must explicitly stop itself.

**Real examples**: LookAtSurfaceCommand, SelectCoordinateSystemGraphicallyCommand, PointAlongSetReferenceElementCommand

**Key characteristics**:
- Use `CommandSupportFlags.Graphic` with `CanSuspendActiveCommand = true`
- Create `GroupViewModel` with `LocateBehavior` (LocateSelect or SmartSketch)
- Subscribe to `SelectionChanged` or `SmartSketchPositioningComplete`
- Call `StopCommand()` after processing the selection
- Some use `StepFilter` to restrict selectable object types
- Always unsubscribe events in `OnStop`

---

### Category 6: Progress-Based Batch Operations

Process multiple objects with a progress indicator.

```csharp
public class BatchOperationCommand : BaseFrameworkCommand
{
    private readonly IProgressListener _progressListener =
        new ProgressListener(useActiveWindowAsParent: true);

    public BatchOperationCommand()
        : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);

        CommitUndoMarker = "Batch Operation";
        CommitSuccessMessage = "Batch operation completed.";
        CommitFailureMessage = "Batch operation failed.";

        using (BOCollection selectedObjects = ClientServiceProvider.SelectSet.SelectedObjects)
        {
            if (selectedObjects.Count == 0)
            {
                AbortUnsavedChanges();
                return;
            }

            int total = selectedObjects.Count;
            _progressListener.Start();

            int current = 0;
            foreach (BusinessObject bo in selectedObjects)
            {
                current++;
                var stepArgs = new UpdateStepArguments(
                    current, total,
                    $"Processing {current} of {total}...");
                _progressListener.UpdateStep(stepArgs);

                ProcessObject(bo);
            }

            _progressListener.StepComplete(new StepCompleteArguments(isInterrupted: false));
        }

        CommitUnsavedChanges();
    }
}
```

> For cancellable progress, use `new ProgressListener(useActiveWindowAsParent: true, canUserStop: true)` — but note that cancellation checking is not built into `IProgressListener`. You manage cancellation logic yourself.

**Real examples**: DrawingsRefreshCommand, HideInterferenceCommand, ShowInterferenceCommand, ShowR3DClashesCommand, ConvertWBSItemToWorkPackageCommand, DrawingsUpdateCommand

**Key characteristics**:
- `ProgressListener` API: `Start()` → `UpdateStep(UpdateStepArguments)` → `StepComplete(StepCompleteArguments)`
- `UpdateStepArguments(currentStep, totalSteps, message)` updates the progress bar
- `StepCompleteArguments(isInterrupted)` signals completion
- Use `canUserStop: false` in constructor to hide the stop button
- For large batches, commit per-item with `CommitChangesWithEmptyUndoMarker()` for subsequent commits

---

### Category 7: ViewModel/Dialog-Based

Show a dialog for user input, then act on the result.

```csharp
public class DialogNoUICommand : BaseFrameworkCommand
{
    public DialogNoUICommand()
        : base(uiLayout: CommandUILayout.NoUI, modal: true, suspendable: false) { }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);

        var viewModel = new MyDialogViewModel();
        var result = ClientServiceProvider.DialogService.ShowDialog(viewModel);

        if (result == true)
        {
            CommitUndoMarker = "My Operation";
            PerformOperation(viewModel.SelectedOption);
            CommitUnsavedChanges();
        }
        else
        {
            AbortUnsavedChanges();
        }
    }
}
```

> For non-modal dialogs that stay open (like `CreateMissingSIOSystemHierarchyRelationsCommand`), the command must call `StopCommand()` when the dialog closes. Subscribe to the dialog's close event and call `StopCommand()` there.

**Real examples**: CreateMissingSIOSystemHierarchyRelationsCommand, SyncWorkspaceCommand

---

## When to Call StopCommand()

The framework automatically stops modal NoUI commands when `OnStart` returns. You do NOT need to call `StopCommand()` in most cases.

**Do NOT call StopCommand()** for:
- Fire-and-forget commands (Category 1)
- Transactional commands (Category 2)
- Command continuation commands (Category 3)
- Batch operations (Category 6)
- View manipulation commands — Pan, Rotate, Zoom, ZoomArea (Category 4)

**DO call StopCommand()** only when the command stays alive after `OnStart` returns:
- Interactive selection commands (Category 5) — call `StopCommand()` in the selection callback
- Non-modal dialog commands (Category 7) — call `StopCommand()` when the dialog closes

**Real commands that call StopCommand()**:
- `LookAtSurfaceCommand` — after user selects a surface and the view is oriented
- `SelectCoordinateSystemGraphicallyCommand` — after graphical selection completes
- `PointAlongSetReferenceElementCommand` — after element selection
- `CreateMissingSIOSystemHierarchyRelationsCommand` — when its non-modal dialog closes

---

## Common Patterns

### Accessing Selected Objects
```csharp
using (BOCollection selectedObjects = ClientServiceProvider.SelectSet.SelectedObjects)
{
    if (selectedObjects.Count == 0) return;
    foreach (BusinessObject bo in selectedObjects) { /* process */ }
}
```
> Always wrap `BOCollection` in `using` to dispose properly.

### Toast Notifications
```csharp
ClientServiceProvider.MessageService.ShowMessage("Message", UxtMessageType.Information);
ClientServiceProvider.MessageService.ShowMessage("Warning", UxtMessageType.Warning);
ClientServiceProvider.MessageService.ShowMessage("Error", UxtMessageType.Error);
```

### Clipboard
```csharp
Clipboard.SetDataObject(text);                              // System.Windows.Clipboard (used by CopyPartNumberCommand)
ClientServiceProvider.ClipboardService.SetText(text);       // Framework clipboard service
```

### Event Subscription
```csharp
// Subscribe in OnStart (or constructor)
EventAccumulator.Instance.GetEvent<MyEvent>().Subscribe(OnMyEvent);

// Always unsubscribe in OnStop
public override void OnStop()
{
    EventAccumulator.Instance.GetEvent<MyEvent>().Unsubscribe(OnMyEvent);
    base.OnStop();
}
```

### Preferences
```csharp
var value = ClientServiceProvider.Preferences.GetBooleanValue("PrefKey", defaultValue);
ClientServiceProvider.Preferences.SetValue("PrefKey", newValue);
```

### Site/Plant Model
```csharp
var activePlant = MiddleServiceProvider.SiteMgr.ActiveSite.ActivePlant;
var catalog = activePlant.PlantCatalog;
```

---

## Decision Flowchart

```
NoUI Command needed
│
├─ Interacts with graphic view via mouse?
│  ├─ View manipulation (pan/rotate/zoom) → Category 4
│  └─ Object/point selection → Category 5
│
├─ Modifies the database?
│  ├─ No → Category 1: Fire-and-Forget
│  └─ Yes
│     ├─ Needs user input via dialog? → Category 7
│     ├─ Processes many objects with progress? → Category 6
│     ├─ Chains to another command? → Category 3
│     └─ Otherwise → Category 2: Transactional
```

## Constructor Quick Reference

| Scenario | Constructor |
|----------|------------|
| Most commands (utility, transactional, batch) | `base(CommandUILayout.NoUI, modal: true, suspendable: false)` |
| View manipulation / graphic selection | `base(CommandUILayout.NoUI, CommandSupportFlags.Graphic, suspendable: false)` + `CanSuspendActiveCommand = true` |
| Explicit no-graphic + modal | `base(CommandUILayout.NoUI, CommandSupportFlags.None, modal: true, suspendable: false)` |
| Simple example | `base(CommandUILayout.NoUI)` |


---

## Reference Command File Paths

All 47 NoUI commands analyzed to extract the patterns in this document.

| # | Command Name | File Path |
|---|-------------|-----------|
| 1 | ActiveWBSItemChangeCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ActiveWBSItemChangeCommand.cs` |
| 2 | AddInterferingObjectsToWorkspaceCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AddInterferingObjectsToWorkspaceCommand.cs` |
| 3 | AddSelectedObjectsToWorkspaceCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AddSelectedObjectsToWorkspaceCommand.cs` |
| 4 | CopyObjectIdentifiersCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/CopyObjectIdentifiersCommand.cs` |
| 5 | CopyPartNumberCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/CopyPartNumberCommand.cs` |
| 6 | CreateMissingSIOSystemHierarchyRelationsCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/CreateMissingSIOSystemHierarchyRelationsCommand.cs` |
| 7 | DeleteCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/DeleteCommand.cs` |
| 8 | LookAtSurfaceCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/LookAtSurfaceCommand.cs` |
| 9 | PointAlongSetReferenceElementCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/PointAlongSetReferenceElementCommand.cs` |
| 10 | PointAlongSetReferencePointCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/PointAlongSetReferencePointCommand.cs` |
| 11 | QuickCopyCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/CopyCommand.cs` |
| 12 | RefreshAppliedStyleRulesCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/RefreshAppliedStyleRulesCommand.cs` |
| 13 | SelectCoordinateSystemGraphicallyCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/SelectCoordinateSystemGraphicallyCommand.cs` |
| 14 | UndoCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/UndoCommand.cs` |
| 15 | ConvertWBSItemToWorkPackageCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/AsBuiltCommands/ConvertWBSItemToWorkPackageCommand.cs` |
| 16 | PanCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ViewCommands/PanCommand.cs` |
| 17 | RotateCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ViewCommands/RotateCommand.cs` |
| 18 | SyncWorkspaceCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ViewCommands/SyncWorkspaceCommand.cs` |
| 19 | ZoomAreaCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ViewCommands/ZoomAreaCommand.cs` |
| 20 | ZoomCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/ViewCommands/ZoomCommand.cs` |
| 21 | BaseWBSCommand | `MRoot/CommonApp/Client/Commands/CommonClientCommands/CommonClientCommands/WBSCommands/BaseWBSCommand.cs` |
| 22 | CreateDrawingsCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/CreateDrawingsCommand.cs` |
| 23 | DrawingFolderMenuCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingFolderMenuCommand.cs` |
| 24 | DrawingsDefaultCopyCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsDefaultCopyCommand.cs` |
| 25 | DrawingSearchFolderMenuCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingSearchFolderMenuCommand.cs` |
| 26 | DrawingsEditCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsEditCommand.cs` |
| 27 | DrawingsEditTemplateCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsEditTemplateCommand.cs` |
| 28 | DrawingsPasteUnsupportedCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsPasteUnsupportedCommand.cs` |
| 29 | DrawingsRefreshCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsRefreshCommand.cs` |
| 30 | DrawingsUpdateCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsUpdateCommand.cs` |
| 31 | DrawingsViewUpdateLogCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/DrawingsViewUpdateLogCommand.cs` |
| 32 | RunQueryCommand | `MRoot/Drawings/Client/Commands/DrawingsClientCommands/DrawingsClientCommands/Commands/RunQueryCommand.cs` |
| 33 | HideInterferenceCommand | `Kroot/FoulCheck/Client/Commands/InterferenceClientCommands/InterferenceClientCommands/Command/HideInterferenceCommand.cs` |
| 34 | ModifyInterferenceRemarksCommand | `Kroot/FoulCheck/Client/Commands/InterferenceClientCommands/InterferenceClientCommands/Command/ModifyInterferenceRemarksCommand.cs` |
| 35 | ModifyInterferenceStatusCommand | `Kroot/FoulCheck/Client/Commands/InterferenceClientCommands/InterferenceClientCommands/Command/ModifyInterferenceStatusCommand.cs` |
| 36 | ShowInterferenceCommand | `Kroot/FoulCheck/Client/Commands/InterferenceClientCommands/InterferenceClientCommands/Command/ShowInterferenceCommand.cs` |
| 37 | ShowR3DClashesCommand | `Kroot/FoulCheck/Client/Commands/InterferenceClientCommands/InterferenceClientCommands/Command/ShowR3DClashesCommand.cs` |
| 38 | ReferenceCoordinateSystemCommand | `MRoot/Equipment/Client/Commands/EquipmentClientCommands/EquipmentClientCommands/ContextMenuCommands/ReferenceCoordinateSystemCommand.cs` |
| 39 | AddAllAllowedSpecificationsCommand | `MRoot/SystemsAndSpecs/Client/SystemClientCommands/SystemClientCommands/AddAllAllowedSpecificationsCommand.cs` |
| 40 | ConvertToMemberSystemCommand | `SRoot/SmartPlantStructure/Client/Commands/SmartPlantStructureClientCommands/SmartPlantStructureClientCommands/ConvertToMemberSystemCommand.cs` |
| 41 | ReplaceTeeWithElbowCommand | `Kroot/CommonRoute/Client/Commands/CommonRouteClientCommands/CommonRouteClientCommands/Piping/Commands/ReplaceTeeWithElbowCommand.cs` |
| 42 | CreateSpaceFolderCommand | `SRoot/SpaceMgmt/Client/Commands/SpaceManagementClientCommands/SpaceManagementClientCommands/CreateSpaceFolderCommand.cs` |
| 43 | HelloWorldCommand | `MRoot/CommonApp/SOM/Examples/ModernClient/ExampleClientCommands/HelloWorldCommand.cs` |
| 44 | NoActiveGraphicViewCommand | `MRoot/CommonApp/SOM/Examples/ModernClient/ExampleClientCommands/NoActiveGraphicViewCommand.cs` |
| 45 | ModalCommand | `MRoot/CommonApp/SOM/Examples/ModernClient/ExampleClientCommands/StateTransitions/ModalCommand.cs` |
| 46 | NonTransactionalCommand | `MRoot/CommonApp/SOM/Examples/ModernClient/ExampleClientCommands/StateTransitions/NonTransactionalCommand.cs` |
| 47 | TransactionalCommand | `MRoot/CommonApp/SOM/Examples/ModernClient/ExampleClientCommands/StateTransitions/TransactionalCommand.cs` |
