# BaseFrameworkCommand Reference

## Overview

`BaseFrameworkCommand` is the base class for all commands in the S3D client framework. It lives in the `Ingr.SP3D.Common.Client` namespace and provides built-in support for:

- Command lifecycle (start, stop, view loaded, finish, restart)
- Group-based UI management (GroupViewModel, GroupCollection, CompositeGroup)
- Properties management via PropertyManager (class-based and business-object-based)
- Compute and Commit transaction workflows
- Error handling and user messaging
- Keyboard and graphic view event handling
- Modify command pattern (editing existing objects from the select set)
- Overlay pattern for contextual UI
- Command continuation (chaining commands)

## Source Location

```
G:\MRoot\CommonApp\SOM\Client\CommonClient\CommonClient\CommandSupport\BaseFrameworkCommand.cs
```

## Class Signature

```csharp
public class BaseFrameworkCommand : Intergraph.CommonToolkit.Client.BaseCommand,
    IViewModelEventHandler, IInputListener, IGraphicEventHandler
```

---

## 1. Basic Command Structure

### Constructor

The constructor configures the UI layout, support flags, modality, and suspendability.

```csharp
public class MyCommand : BaseFrameworkCommand
{
    public MyCommand()
        : base(
            uiLayout: CommandUILayout.Floating,           // Floating | Dialog | NoUI
            supportFlags: CommandSupportFlags.Graphic      // None | Graphic | Modify | Graphic | Modify
                        | CommandSupportFlags.Modify,
            modal: false,
            suspendable: true)
    {
        // Set class ID for properties when no business object exists yet (placement commands)
        ClassIdForProperties = "CPMyObjectClass";

        // Disable automatic commit on stop if command handles commit explicitly
        DisableAutomaticCommit = false;

        // Define which completion buttons are available
        CompletionButtons = CompletionFlags.CloseCancel
                          | CompletionFlags.Finish
                          | CompletionFlags.FinishModify
                          | CompletionFlags.FinishRestart;
    }
}
```

Key constructor parameters:

- `CommandUILayout.Floating` - standard floating ribbon UI
- `CommandUILayout.Dialog` - dialog-based command UI
- `CommandUILayout.NoUI` - no UI (e.g., delete command)
- `CommandSupportFlags.Graphic` - enables graphic view mouse/keyboard events
- `CommandSupportFlags.Modify` - indicates command also supports modify mode (allows in-place transition from placement to modify)
- `modal: true` - command is modal (cannot be `suspendable`, cannot have `Graphic` or `Floating`)

### OnStart

Called when the command starts. Set up commit markers, display name, create groups, and handle pre-selection.

```csharp
public override void OnStart(int commandID, object argument)
{
    base.OnStart(commandID, argument);

    // Required: set undo marker and messages for commit
    CommitUndoMarker = "My Command";
    CommitFailureMessage = "Failed to save changes.";
    CommitSuccessMessage = "Changes saved successfully.";

    // Set display name shown in the command UI
    DisplayName = "My Command";

    // Create command groups (UI sections)
    CreateCommandGroups();

    // Handle pre-selected objects if applicable
    if (IsModifyCommand)
    {
        // Properties are auto-loaded from select set for modify commands
        InitializeModifyState();
    }
}
```

### OnStop

Called when the command is stopping. Clean up event subscriptions and resources.

```csharp
public override void OnStop()
{
    base.OnStop();

    // Unsubscribe from events
    _myGroup.SelectionChanged -= OnSelectionChanged;

    // Clean up resources
    _myHiliter?.Dispose();
}
```

### OnViewLoaded

Called after the command top-level view is fully loaded. Move the long running activities here to save the command load time

```csharp
protected override void OnViewLoaded()
{
    if (IsModifyCommand)
    {
        // Initialize modify-specific UI state
        SetupModifyView();
    }
    else
    {
        // Activate the first input group for placement
        _selectGroup.SetAsActiveGroup();
    }
}
```

### OnFinish

Called when a completion button (Finish, Finish and Modify, Finish and Restart) is clicked. Return `true` if finish was successful.

```csharp
protected override bool OnFinish(CompletionFlags completionFlags)
{
    if (completionFlags == CompletionFlags.CloseCancel)
    {
        return true; // Nothing to do for cancel
    }

    bool isFinishComplete = false;

    try
    {
        // Commit changes to database
        CanFinish = isFinishComplete = CommitUnsavedChanges();
    }
    catch (Exception)
    {
        return CanFinish = false;
    }

    // Handle Finish and Modify: put created object in select set
    if (isFinishComplete && completionFlags == CompletionFlags.FinishModify)
    {
        using (BOCollection selectedObjects = ClientServiceProvider.SelectSet.SelectedObjects)
        {
            selectedObjects.Add(_createdObject);
        }
    }

    // Handle Finish (close): clear select set
    if (isFinishComplete && completionFlags == CompletionFlags.Finish)
    {
        ClientServiceProvider.SelectSet.Clear();
    }

    return isFinishComplete;
}
```

---

## 2. Group and Command Controls Management

### GroupViewModel

Groups define sections of the command UI (ribbon panels). Each group can contain controls and can be activated/deactivated.

```csharp
private GroupViewModel _generalGroup;
private GroupViewModel _inputGroup;

private void CreateCommandGroups()
{
    // Top-level group
    _generalGroup = new GroupViewModel(Groups, "GeneralGroup")
    {
        DisplayName = "General",
        AutoSetActiveOnFocus = false
    };

    // Group with locate/select behavior
    _inputGroup = new GroupViewModel(Groups, "InputGroup")
    {
        DisplayName = "Select Object",
        LocateBehavior = GroupLocateBehaviorType.LocateSelect
    };
}
```

### GroupCollection

GroupCollections organize groups hierarchically. A GroupCollection can be the child of a GroupViewModel, creating nested group structures.

```csharp
// Create a group collection under a parent group
var parentGroup = new GroupViewModel(Groups, "ParentGroup")
{
    DisplayName = "Parent"
};
var childCollection = new GroupCollection(parentGroup, isComposite: false);

// Add child groups to the collection
var childGroup1 = new GroupViewModel(childCollection, "Child1")
{
    DisplayName = "Step 1"
};
var childGroup2 = new GroupViewModel(childCollection, "Child2")
{
    DisplayName = "Step 2"
};
```

### CompositeGroup

A composite group collection (`isComposite: true`) shows child groups as a combined unit where activating one child deactivates others within the same composite.

```csharp
var stepsGroup = new GroupViewModel(Groups, "StepsGroup")
{
    DisplayName = "Steps"
};
var compositeCollection = new GroupCollection(stepsGroup, isComposite: true);

var step1 = new GroupViewModel(compositeCollection, "Step1") { DisplayName = "Step 1" };
var step2 = new GroupViewModel(compositeCollection, "Step2") { DisplayName = "Step 2" };
```

### Controls

Add controls (buttons, split buttons, dropdowns) to groups.

```csharp
// Command button in a group
var button = new CommandButtonViewModel(myGroup,
    commandName: "SomeOtherCommand",
    commandArgument: null,
    executeCommandOnAction: true)
{
    ContentSize = CommandContentSize.Medium
};

// Split button with dropdown
var splitButton = new CommandSplitButtonViewModel(myGroup,
    CommandButtonViewModel.CommandButtonType.Icon)
{
    Name = "MySplitButton",
    ContentSize = CommandContentSize.ExtraLarge
};
splitButton.DefaultButton = new CommandButtonViewModel(splitButton,
    commandName: "DefaultCommand",
    commandArgument: null,
    executeCommandOnAction: true);

var dropDown = new CommandDropDownMenuContentViewModel(splitButton);
splitButton.DropDownContent.Add(dropDown);
new CommandButtonViewModel(dropDown, commandName: "Option1",
    commandArgument: null, executeCommandOnAction: true);
new CommandButtonViewModel(dropDown, commandName: "Option2",
    commandArgument: null, executeCommandOnAction: true);
```

---

## 3. Properties Management

### Setting Property Source

For placement commands, set properties from a class ID. For modify commands, properties are auto-loaded from the select set.

```csharp
// Placement: set class-based properties (done in constructor or OnStart)
ClassIdForProperties = "CPMyObjectClass";

// After creating a business object, transition to object-based properties
SetPropertiesSource(myBusinessObject);

// For multiple objects
SetPropertiesSource(new Collection<BusinessObject> { obj1, obj2 });

// Reset back to class-based properties
SetPropertiesSource(); // uses ClassIdForProperties
```

### Common Properties GVM (CommonPropertiesViewModel)

`CommonPropertiesViewModel` is a reusable group that provides standard property controls (Name, Parent System, etc.).

```csharp
private CommonPropertiesViewModel _commonPropertiesGVM;

private void CreateGroups()
{
    var generalGroup = new GroupViewModel(Groups, "GeneralGroup")
    {
        DisplayName = "General"
    };
    var generalCollection = new GroupCollection(generalGroup, false);

    // Create common properties with Name and Parent System
    _commonPropertiesGVM = new CommonPropertiesViewModel(
        generalCollection,
        CommonSupportedProperties.NameAndParentSystem);

    // Add additional custom properties
    _commonPropertiesGVM.AddProperty("IMyInterface", "MyProperty");
}
```

### Reading and Writing Properties

```csharp
// Get a property descriptor
ClientPropertyDescriptor descriptor = GetProperty("IMyInterface", "MyProperty");

// Read current value
object currentValue = descriptor.CurrentValue;

// Set a default value
descriptor.SetDefaultValue("DefaultValue");

// Set a parameter on the property
descriptor.SetParameter("ParameterName", true);

// Check if any properties are in error
bool hasErrors = AnyPropertiesInError();

// Check specific property error
bool isInError = IsPropertyInError("IMyInterface", "MyProperty");
```

### Responding to Property Changes

```csharp
protected override void OnPropertyValuesChanged(
    IEnumerable<PropertyValueChangedEventArgs> eventArguments)
{
    foreach (var args in eventArguments)
    {
        if (args.InError) continue;

        if (args.PropertyName == "MyProperty" &&
            args.ChangeContext == PropertyChangeContext.CurrentValue)
        {
            // Handle the property change
            HandleMyPropertyChanged(args.NewCurrentValue);
        }
    }

    // Re-evaluate if command can finish
    CanFinish = !AnyPropertiesInError() && _myObject != null;
}
```

---

## 4. Compute and Commit Workflows

### Compute

Compute previews changes and validates impact on connected/related objects. Returns `true` if successful.

```csharp
// Mark that changes need computing before commit
IsComputePending = true;

// Explicitly compute changes
bool computeSuccess = ComputeChanges();

// For placement commands, register objects for error tracking
ObjectsForPlacement.Add(myNewObject);
bool success = ComputeChanges();
```

### Commit

Commit saves changes permanently to the database. If `IsComputePending` is true, a compute is done first.

```csharp
// Standard commit
bool commitSuccess = CommitUnsavedChanges();

// Commit with suppressed notifications (command handles its own notifications)
bool commitSuccess = CommitUnsavedChanges(suppressNotification: true);

// Abort unsaved changes (rollback)
bool abortSuccess = AbortUnsavedChanges();
```

### Typical Compute-then-Commit Flow

```csharp
// After user makes changes:
IsComputePending = true;

// When user clicks Finish:
protected override bool OnFinish(CompletionFlags completionFlags)
{
    // CommitUnsavedChanges will auto-compute if IsComputePending is true
    bool success = CommitUnsavedChanges();
    CanFinish = success;
    return success;
}
```

### PrepareToCommitUnsavedChanges

Called before automatic commit when the command is stopped. Override to do last-minute preparation.

```csharp
protected override void PrepareToCommitUnsavedChanges()
{
    base.PrepareToCommitUnsavedChanges();
    // Save preferences or do final validation
    SaveUserPreferences();
}
```

---

## 5. Error Handling

### Show Messages

```csharp
// Show error from exception
ShowMessage("ErrorKey", exception);

// Show warning with custom message
ShowMessage("WarningKey", UxtMessageType.Warning, "Something needs attention.");

// Show error with help topic
var helpTopic = new HelpTopic
{
    TopicId = 123456,
    ShortDescription = "Details here."
};
ShowMessage("ErrorKey", UxtMessageType.Error, "An error occurred.", helpTopic);

// Remove a previously shown message
RemoveUserMessage("ErrorKey");

// Clear all error messages
ClearErrorMessages();
```

### Exception Handling in OnFinish

```csharp
protected override bool OnFinish(CompletionFlags completionFlags)
{
    try
    {
        CanFinish = CommitUnsavedChanges();
        return CanFinish;
    }
    catch (CommandFrameworkCommitAbortedOnFailureException)
    {
        // Already logged and notification posted by framework
        return CanFinish = false;
    }
    catch (Exception ex)
    {
        ShowMessage("FinishError", ex);
        return CanFinish = false;
    }
}
```

---

## 6. Modify Command Pattern

A modify command edits existing objects from the select set. The framework auto-loads properties from selected objects.

```csharp
public class MyCommand : BaseFrameworkCommand
{
    public MyCommand()
        : base(CommandUILayout.Floating,
               CommandSupportFlags.Graphic | CommandSupportFlags.Modify)
    {
        ClassIdForProperties = "CPMyObjectClass";
    }

    public override void OnStart(int commandID, object argument)
    {
        base.OnStart(commandID, argument);
        CommitUndoMarker = "Modify My Object";

        // IsModifyCommand is true when started from select set
        if (IsModifyCommand)
        {
            DisplayName = "Modify My Object";
        }
        else
        {
            DisplayName = "Place My Object";
        }

        CreateCommandGroups();
    }

    protected override void OnViewLoaded()
    {
        if (IsModifyCommand)
        {
            // IsSelectSetModifiable indicates if objects can be edited
            if (IsSelectSetModifiable)
            {
                _inputGroup.SetAsActiveGroup();
            }
        }
        else
        {
            _selectGroup.SetAsActiveGroup();
        }
    }

    // Called to determine if a specific object can be modified
    protected override bool GetIsModifiable(BusinessObject businessObject)
    {
        return businessObject.SupportsInterface("IMyInterface");
    }
}
```

Key modify properties and methods:

- `IsModifyCommand` - true when command was started as modify
- `IsSelectSetModifiable` - true when all selected objects can be modified
- `ModifyIsActive` - true when modify is active and in control of input
- `ActivateModify()` - activates modify mode
- `RegisterForMakeModifiable()` - register groups to enable when approval status changes to Working

---

## 7. Overlay Pattern

Overlays show a group UI on top of the main command UI, hiding other groups temporarily.

```csharp
private GroupViewModel _overlayGroup;

private void CreateOverlayGroup()
{
    var parentCollection = new GroupCollection(Groups, isComposite: false);

    _overlayGroup = new GroupViewModel(parentCollection, "OverlayGroup")
    {
        DisplayName = "Edit Details",
        ShowAsOverlay = true,           // Show as overlay
        CloseOverlayOnAccept = true,    // Auto-close when accepted
        GroupAcceptVisible = true,      // Show Accept button
        GroupResetVisible = true        // Show Reset button
    };
}

// Show the overlay
_overlayGroup.SetAsActiveGroup();

// Handle overlay accept/reset
protected override void OnGroupAccept(GroupViewModel acceptedGroup)
{
    if (acceptedGroup == _overlayGroup)
    {
        ApplyOverlayChanges();
    }
}

protected override void OnGroupReset(GroupViewModel resetGroup)
{
    if (resetGroup == _overlayGroup)
    {
        RevertOverlayChanges();
    }
}
```

---

## 8. Command Continuation

Continue to another command after the current command stops.

```csharp
// Start a named command for continuation
StartCommandForContinuation("OtherCommandName", commandParameter: null);

// Start modify command for continuation with specific objects
using (var objects = new BOCollection())
{
    objects.Add(myObject);
    StartModifyCommandForContinuation(objects);
}

// Start modify command using existing select set
StartModifyCommandForContinuation();
```

### Event-Based Continuation

```csharp
// In constructor, subscribe to continuation restore event
EventAccumulator.Instance.GetEvent<CommandContinuationRestoreEvent>()
    .Subscribe(OnCommandStateRestore);

// Handle restore
private void OnCommandStateRestore(CommandContinuationEventArgs args)
{
    if (args is MyCustomContinuationEventArgs myArgs)
    {
        _restoredData = myArgs.SavedData;
    }
}

// In OnStop, publish continuation save event
public override void OnStop()
{
    base.OnStop();
    if (CommandCompletionInitiated == CompletionFlags.None)
    {
        EventAccumulator.Instance.GetEvent<CommandContinuationSaveEvent>()
            .Publish(new MyCustomContinuationEventArgs
            {
                SavedData = _myData
            });
    }
}
```

---

## 9. Group Activation/Deactivation Callbacks

```csharp
// Called when a group is activated
protected override void OnActivateGroup(GroupViewModel activatingGroup)
{
    if (activatingGroup == _step2Group)
    {
        // Prepare for step 2
    }
}

// Called when a group is deactivated
protected override void OnDeactivateGroup(
    GroupViewModel deactivatingGroup, GroupViewModel activatingGroup)
{
    if (deactivatingGroup == _step1Group)
    {
        // Clean up step 1
    }
}
```

---

## 10. OnRestart

Called after a successful Finish and Restart. The command stays running but resets for a new placement cycle.

```csharp
protected override void OnRestart()
{
    _createdObjects.Clear();

    // Restore default parent from preferences
    _commonPropertiesGVM.SetDefaultParent(MyPreferences.ParentSystem);

    // Re-enable input groups
    _selectGroup.SetAsActiveGroup();
}
```

---

## Quick Reference: Key Properties

| Property               | Type            | Description                              |
| ---------------------- | --------------- | ---------------------------------------- |
| ClassIdForProperties   | string          | Class ID for property source (placement) |
| CommitUndoMarker       | string          | Required undo marker for commit          |
| CommitSuccessMessage   | string          | Message shown on successful commit       |
| CommitFailureMessage   | string          | Message shown on failed commit           |
| CompletionButtons      | CompletionFlags | Which finish buttons to show             |
| DisplayName            | string          | Command display name in UI               |
| CanFinish              | bool            | Whether finish buttons are enabled       |
| IsComputePending       | bool            | Whether compute is needed before commit  |
| IsModifyCommand        | bool            | Whether running as modify command        |
| IsSelectSetModifiable  | bool            | Whether selected objects are modifiable  |
| DisableAutomaticCommit | bool            | Disable auto-commit on stop              |
| Groups                 | GroupCollection | Root group collection for command UI     |
| ActiveGroup            | GroupViewModel  | Currently active group                   |
| PreviousGroup          | GroupViewModel  | Previously active group                  |
| Running                | bool            | Whether command is running               |
| InitialViewLoaded      | bool            | Whether view has been loaded             |

## Quick Reference: Key Virtual Methods

| Method                                            | When Called                                         |
| ------------------------------------------------- | --------------------------------------------------- |
| OnStart(int, object)                              | Command starts                                      |
| OnStop()                                          | Command stops                                       |
| OnViewLoaded()                                    | View fully loaded                                   |
| OnFinish(CompletionFlags)                         | Completion button clicked                           |
| OnRestart()                                       | After Finish and Restart                            |
| OnPropertyValuesChanged(IEnumerable)              | Property values changed (batched)                   |
| OnPropertyValueChanged(args)                      | Single property value changed (immediate)           |
| OnActivateGroup(GroupViewModel)                   | Group activated                                     |
| OnDeactivateGroup(GroupViewModel, GroupViewModel) | Group deactivated                                   |
| OnGroupAccept(GroupViewModel)                     | Group accept button clicked                         |
| OnGroupReset(GroupViewModel)                      | Group reset button clicked                          |
| OnMouseDown/Move/Up(view, e, position)            | Graphic view mouse events                           |
| OnKeyDown/Up(e)                                   | Keyboard events                                     |
| OnDoubleClick(view, e, position)                  | Graphic view double click                           |
| GetIsModifiable(BusinessObject)                   | Check if object is modifiable                       |
| PrepareToCommitUnsavedChanges()                   | Before auto-commit on stop                          |
| OnTransitionForFinishAndModify()                  | After Finish and Modify transition                  |
| OnSelectSetChangedDuringModifyCommit              | Select set changed during modify commit             |
| OnMakeModifiable()                                | Approval status changed to Working                  |
| OnMakeNotModifiable()                             | Approval status changed to non-Working after commit |

## Reference Command Locations

```
G:\MRoot\CommonApp\Client\Commands\CommonClientCommands
G:\MRoot\Equipment\Client\Commands\EquipmentClientCommands
G:\Kroot\CommonRoute\Client\Commands\CommonRouteClientCommands
G:\SRoot\SmartPlantStructure\Client\Commands\SmartPlantStructureClientCommands
```
