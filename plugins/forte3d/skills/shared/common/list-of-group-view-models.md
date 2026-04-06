# List of Public GroupViewModels

This document lists all public `GroupViewModel` classes available in `Ingr.SP3D.Common.Client.ViewModels` (from `CommonClient`) that downstream applications and commands can use.

Base path for most files: `CommonClient\CommonClient\CommandSupport\ViewModels\`

## Base GroupViewModel

| Class | File Path | Description |
|-------|-----------|-------------|
| `GroupViewModel` | `CommandSupport\ViewModels\GroupViewModel.cs` | Base group view model for supporting groups in the command framework. A group is defined as a grouping of behavior and optionally, UI layout to be used within the context of a command. Supports locate/select and SmartSketch behaviors, mouse event handling, selection management, and composite group patterns. |

## Specialized GroupViewModels

| Class | File Path | Description |
|-------|-----------|-------------|
| `CommandsGroupViewModel` | `CommandSupport\ViewModels\CommandsGroupViewModel.cs` | Defines a group that starts other related commands. Used when a command needs to launch or switch between sub-commands. |
| `ExpanderGroupViewModel` | `CommandSupport\ViewModels\ExpanderGroupViewModel.cs` | Specialized group that can be expanded and collapsed by the user, providing a collapsible section within the command UI. |
| `PreviewImageGroupViewModel` | `CommandSupport\ViewModels\PreviewImageGroupViewModel.cs` | Group for displaying a preview image within the command interface. |
| `PropertiesGroupViewModel` | `CommandSupport\ViewModels\PropertiesGroupViewModel.cs` | Displays properties directly within the command user interface. Supports dynamic property refresh. |
| `CommonPropertiesViewModel` | `CommandSupport\ViewModels\CommonPropertiesViewModel.cs` | Common properties group view model. Extends `PropertiesGroupViewModel` with standard interface/property combinations used across commands. |
| `MultiEditCommandSelectorGroupViewModel` | `CommandSupport\ViewModels\MultiEditCommandSelectorViewModel.cs` | Provides a group for multiple selected objects modification, enabling batch editing scenarios. |
| `PlaneDefinitionViewModel` | `CommandSupport\ViewModels\PlaneDefinitionViewModel.cs` | Plane definition view model for defining planes. Implements `ICompositeGroupViewModel` for composite group support. |
| `WorkingConstraintsViewModel` | `CommandSupport\ViewModels\WorkingConstraintsViewModel.cs` | Working constraints view model for managing constraint-based interactions. Implements `ICompositeGroupViewModel` and supports contextual actions. |
| `WorkingPlaneViewModel` | `CommandSupport\ViewModels\WorkingPlaneViewModel.cs` | Command combo box for display of the working planes. Supports contextual actions. (Obsolete - used only in construction graphics.) |
| `RotateGroupViewModel` | `CommandSupport\ViewModels\RotateGroupViewModel.cs` | Rotate group view model for rotating objects. Supports contextual actions and configurable display options (step control, axis of rotation). |
| `TranslateGroupViewModel` | `CommandSupport\ViewModels\TranslateGroupViewModel.cs` | Translate group view model for translating/repositioning objects. Implements `ICompositeGroupViewModel` and supports contextual actions with display options (From/To, Fast move). |

## Points-Based GroupViewModels

| Class | File Path | Description |
|-------|-----------|-------------|
| `PointsGroupViewModel` (abstract) | `CommandSupport\ViewModels\PointsGroupViewModel.cs` | Abstract base for standard group behavior selecting multiple points to define an input. Implements `ICompositeGroupViewModel`. Subclass this when you need N-point selection. |
| `TwoPointsGroupViewModel` | `CommandSupport\ViewModels\TwoPointsGroupViewModel.cs` | Standard group behavior for selecting 2 points. Supports optional glyph display during point selection. |
| `ThreePointsGroupViewModel` | `CommandSupport\ViewModels\ThreePointsGroupViewModel.cs` | Standard group behavior for selecting 3 points to define an input. |

## Sketch GroupViewModels

| Class | File Path | Description |
|-------|-----------|-------------|
| `SketchViewModel` | `Sketcher\ViewModels\SketchViewModel.cs` | SketchViewModel for defining the sketch plane and to sketch. Implements `ICompositeGroupViewModel` and supports contextual actions. |
| `SketchingGroupViewModel` | `Sketcher\ViewModels\SketchingGroupViewModel.cs` | Sketch GVM which holds view models for creating dimensions and constraints. Implements `ICompositeGroupViewModel` and supports contextual actions (Extend, Trim, Split, WorkingConstraints). |

## Abstract GroupViewModels (for extension)

| Class | File Path | Description |
|-------|-----------|-------------|
| `RadialControlGroupViewModel` (abstract) | `CommandSupport\ViewModels\RadialControlGroupViewModel.cs` | Abstract parent for an inherited GroupViewModel that provides a radial menu contextual action defined by the command writer. Subclass this to add radial menu support to a group. |
