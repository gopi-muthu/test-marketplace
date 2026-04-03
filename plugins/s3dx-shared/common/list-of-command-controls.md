# List of Public Command Control ViewModels

This document lists all public `Command<ControlName>ViewModel` classes available in `Ingr.SP3D.Common.Client.ViewModels` (from `CommonClient`) that downstream applications and commands can use as UI controls.
Base path: `CommonClient\CommonClient\CommandSupport\ViewModels\`

## Button Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandButtonViewModel` | `CommandButtonViewModel.cs` | Base command button item for displaying a button in command UI. Supports various button types (standard text, icon, etc.). |
| `CommandButtonSelectableViewModel` | `CommandButtonSelectableViewModel.cs` | Selectable button for displaying in a drop-down list. Extends `CommandButtonViewModel` for use inside `CommandDropDownContentViewModel`. |
| `CommandToggleButtonViewModel` | `CommandToggleButtonViewModel.cs` | Toggle button that can remain pressed while a command is running. Set `DepressWhileActive` to true for press-and-hold behavior. |
| `CommandCheckBoxViewModel` | `CommandCheckBoxViewModel.cs` | Check box control for command UI. Functionally identical to toggle button but with check box presentation. |
| `CommandRadioButtonViewModel` | `CommandRadioButtonViewModel.cs` | Radio button that can be grouped. Supports standard text labels and icon mode. |
| `CommandDialogRadioButtonViewModel` | `CommandDialogRadioButtonViewModel.cs` | Radio button for dialog commands. Provides a simple radio button with text to the right, designed for dialog layouts. |
| `CommandSplitButtonViewModel` | `CommandSplitButtonViewModel.cs` | Split button with a primary action and a drop-down for secondary actions. |

## Input Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandInputViewModel` (abstract) | `CommandInputViewModel.cs` | Abstract base for all command input controls. Provides modified/required state tracking and view model event handling. |
| `CommandTextBoxViewModel` | `CommandTextBoxViewModel.cs` | Text box input control for command UI. Supports data error validation via `INotifyDataErrorInfo`. |
| `CommandNumericInputViewModel` | `CommandNumericInputViewModel.cs` | Numeric input control for entering numeric values. Supports data error validation via `INotifyDataErrorInfo`. |
| `CommandDateTimePickerViewModel` | `CommandDateTimePickerViewModel.cs` | Date/time picker control. Supports picking date only, time only, or both date and time. Implements `INotifyDataErrorInfo`. |
| `CommandColorPickerViewModel` | `CommandColorPickerViewModel.cs` | Color picker control for selecting colors in command UI. |
| `CommandSliderViewModel` | `CommandSliderViewModel.cs` | Slider control for selecting a value within a range. |
| `CommandSearchBoxViewModel` | `CommandSearchBoxViewModel.cs` | Search box control for providing search functionality in command UI. |

## ComboBox Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandComboBoxViewModel` | `CommandComboBoxViewModel.cs` | Standard combo box for command UI. Supports multiple combo box types (text, icon, etc.). |
| `CommandComboBoxItem` | `CommandComboBoxItem.cs` | Item for a `CommandComboBoxViewModel`. Supports icon IDs and is auto-added to parent on creation. |
| `CommandNestedComboBoxViewModel` | `CommandNestedComboBoxViewModel.cs` | Nested combo box for hierarchical/grouped selection in command UI. |
| `CommandNestedComboBoxItem` | `CommandNestedComboBoxItem.cs` | Item for a `CommandNestedComboBoxViewModel`. Represents a selectable entry in the nested combo box. |
| `CommandPermissionGroupViewModel` | `CommandPermissionGroupViewModel.cs` | Specialized combo box pre-populated with available permission groups that have FullAccess or write access. |
| `CommandInputDropDownViewModel` | `CommandInputDropDownViewModel.cs` | Input control with a drop-down for combined text input and selection. Supports data error validation. |
| `CommandInputChecklistViewModel` | `CommandInputChecklistViewModel.cs` | Multi-select checklist drop-down control. Defaults `AutoCloseDropDown` to false for multiple selection. Publishes events on selection change and clear. |

## Drop-Down Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandDropDownViewModel` | `CommandDropDownViewModel.cs` | Drop-down button that opens a drop-down content area. Extends `CommandButtonViewModel` with drop-down behavior. |
| `CommandDropDownContentViewModel` | `CommandDropDownContentViewModel.cs` | Base content view model for defining drop-down content. Add child controls to this to populate the drop-down. |
| `CommandDropDownMenuContentViewModel` | `CommandDropDownMenuContentViewModel.cs` | Menu-style drop-down content for displaying a vertical menu in a drop-down. |
| `CommandDropDownPaletteContentViewModel` | `CommandDropDownPaletteContentViewModel.cs` | Palette-style drop-down content for displaying a grid of icon buttons in a drop-down. |
| `CommandDropDownSimpleListContentViewModel` | `CommandDropDownSimpleListContentViewModel.cs` | Simple list drop-down content for displaying a vertical list of items. Supports configurable minimum widths (small, medium). |
| `CommandDropDownHorizontalListViewModel` | `CommandDropDownHorizontalListViewModel.cs` | Horizontal simple list drop-down content for displaying items in a horizontal layout. |

## Flyout Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandFlyoutButtonViewModel` | `CommandFlyoutButtonViewModel.cs` | Button with a fly-out panel for additional user interaction. |
| `CommandFlyoutContentViewModel` | `CommandFlyoutContentViewModel.cs` | Defines fly-out content for a `CommandFlyoutButtonViewModel`. Derive from this class to define custom XAML/view model details for specific fly-out usage. |

## List and Collection Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandListBoxViewModel` | `CommandListBoxViewModel.cs` | List box control for command UI. Supports single, multiple, and extended selection modes. |
| `CommandListBoxItemViewModel` | `CommandListBoxItemViewModel.cs` | Item for a `CommandListBoxViewModel`. Auto-added to parent list box on creation. |
| `CommandItemsControlViewModel` | `CommandItemsControlViewModel.cs` | Vertical list of items control. Intended for full-width usage within a command. |
| `CommandItemsControlItemViewModel` | `CommandItemsControlItemViewModel.cs` | Item for a `CommandItemsControlViewModel`. Keyed item with a display name. |
| `CommandGalleryViewModel` | `CommandGalleryViewModel.cs` | Gallery control for displaying a collection of items with an MRU (most recently used) list. Items are populated via `AddGalleryCommand`. |

## Grid Controls

| Class | File | Description |
|-------|------|-------------|
| `BaseCommandGridViewModel` (abstract) | `CommandGridViewModel.cs` | Abstract base class for command grids. Cell editing view model events include the row object for the selected row via `EventParameter`. |
| `CommandGridViewModel<T>` | `CommandGridViewModel.cs` | Generic typed command grid for displaying tabular data in command UI. Type parameter `T` represents the row data object type. |

## Text Display Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandTextBlockViewModel` | `CommandTextBlockViewModel.cs` | Read-only text block for displaying static text in command UI. |

## Dialog Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandDialogContentViewModel` (abstract) | `CommandDialogContentViewModel.cs` | Abstract base for defining dialog content details. Derive from this to create custom dialog content for command dialogs. |

## Group Controls

| Class | File | Description |
|-------|------|-------------|
| `CommandsGroupViewModel` | `CommandsGroupViewModel.cs` | Specialized group that starts other related commands. Used when a command needs to launch or switch between sub-commands. |
