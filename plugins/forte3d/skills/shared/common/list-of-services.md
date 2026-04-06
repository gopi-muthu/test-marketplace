# List of Public Services

This document lists all public `Service` classes available in the CommonClient project that downstream applications and commands can use. Most services are accessed through the static `ClientServiceProvider` class.

Base path for all files: `G:\MRoot\CommonApp\SOM\Client\CommonClient\CommonClient\`

## Service Base Class Hierarchy

```
Service (abstract)                              -- ServicesSupport\Service.cs
+-- COMWrapperService (abstract)                -- ServicesSupport\COMWrapperService.cs
|   +-- SessionFileCOMWrapperService (abstract) -- ServicesSupport\SessionFileCOMWrapperService.cs
+-- SessionFileService (abstract)               -- ServicesSupport\SessionFileService.cs
+-- TriadWidgetServiceBase (abstract)           -- TriadWidgetServiceBase.cs
```

All service classes live in the `Ingr.SP3D.Common.Client.Services` namespace.

## ClientServiceProvider

```
CommonClient\CommonClient\ClientServiceProvider.cs
```

```csharp
public static class ClientServiceProvider
```

Static singleton that provides access to all registered services. This is the primary way to obtain service instances.

### Key Methods

| Method | Description |
|--------|-------------|
| `GetService<T>()` | Returns the registered service of type T. Throws if not found. |
| `TryGetService<T>(out T)` | Tries to get a service; returns false if not found. |
| `GetOrCreateService<T>()` | Gets existing or creates and registers a new service of type T. |
| `GetServiceStatus()` | Returns the current status of a service. |
| `AddService()` | Registers a service instance. |
| `RemoveService()` | Unregisters a service instance. |

### Common Property Accessors

Most services have a static property shortcut on `ClientServiceProvider`:

```csharp
ClientServiceProvider.CommandMgr              // CommandManager
ClientServiceProvider.GraphicViewMgr          // GraphicViewManager
ClientServiceProvider.SelectSet               // SelectSet
ClientServiceProvider.TransactionMgr          // ClientTransactionManager
ClientServiceProvider.WorkingSet              // WorkingSet
ClientServiceProvider.Preferences             // Preferences
ClientServiceProvider.SessionManager          // SessionManager
ClientServiceProvider.PinPointService         // PinPointService
ClientServiceProvider.ClipboardService        // ClipboardService
ClientServiceProvider.ValueMgr               // ValueManager
ClientServiceProvider.ErrHandler              // ErrorHandler
ClientServiceProvider.WaitCursor             // WaitCursor
ClientServiceProvider.ViewHiliterMgr         // ViewHiliterManager
ClientServiceProvider.ProgressDisplayService  // ProgressDisplayService
ClientServiceProvider.ServiceLocator         // ServiceLocator
ClientServiceProvider.ClientContext           // ClientContext
ClientServiceProvider.ActiveCoordinateSystemMgr // ActiveCoordinateSystemManager
ClientServiceProvider.ViewManager            // ViewStyleManager
ClientServiceProvider.CustomGraphicViewSetManager // CustomGraphicViewSetManager
ClientServiceProvider.SelectMultiCaster      // SelectMultiCaster
ClientServiceProvider.LocateNotifier         // LocateNotifier
ClientServiceProvider.ColorPreferences       // ColorPreferences
```

---

## Services Derived from Service

| Class | File Path | Description |
|-------|-----------|-------------|
| `ColorPreferences` | `ServicesSupport\ColorPreferences.cs` | Manages color session file preferences for the application. |
| `CommitNotifications` | `ServicesSupport\CommitNotifications.cs` | Listens to Revision Manager and raises create, modify, and delete events for BusinessObjects on commit. |
| `ServiceLocator` | `ServicesSupport\ServiceLocator.cs` | Provides MEF-based service location for resolving exported components. |
| `ContextMenuManager` | `ServicesSupport\ContextMenuManager.cs` | Manages context menu visibility handlers for right-click menus. |
| `ErrorHandler` | `ServicesSupport\ErrorHandler.cs` | Central error handler for displaying and managing error messages. |
| `GraphicLabelManager` | `ServicesSupport\GraphicLabelManager.cs` | Manages placement and display of labels in graphic views. |
| `ModifierKeySelectService` | `ServicesSupport\ModifierKeySelectService.cs` | Processes modifier key (Ctrl, Shift) selection behavior. |
| `NamedSetManager` | `ServicesSupport\NamedSetManager.cs` | Keeps an in-memory list of named sets saved by the user. |
| `OrderedPropertiesManager` | `ServicesSupport\OrderedPropertiesManager.cs` | Manages ordered properties lists for property display ordering. |
| `PinPointService` (sealed) | `ServicesSupport\PinPointService.cs` | Provides precision input (PinPoint) for exact coordinate entry in graphic views. |
| `ProgressDisplayService` | `ServicesSupport\ProgressDisplayService.cs` | Smart 3D wrapper around the COM ProgressDisplayService for showing progress bars. |
| `RotateViewService` | `ServicesSupport\RotateViewService.cs` | Rotates the active graphic view. |
| `ViewHiliterManager` | `ServicesSupport\ViewHiliterManager.cs` | Manages hiliting (highlighting) of objects across multiple graphic views. |
| `WaitCursor` (sealed) | `ServicesSupport\WaitCursor.cs` | Displays a busy/wait cursor during long-running operations. |
| `WidgetManager` (sealed) | `ServicesSupport\WidgetManager.cs` | Dynamically adds and manages widgets at 3D positions in graphic views. |

## Services Derived from COMWrapperService

These services wrap underlying COM objects and provide .NET-friendly APIs.

| Class | File Path | Description |
|-------|-----------|-------------|
| `ClipboardService` | `ServicesSupport\ClipboardService.cs` | Clipboard service wrapper for copy/paste operations. |
| `CommandManager` | `ServicesSupport\CommandManager.cs` | Manages starting, stopping, and subscribing to command lifecycle events. |
| `GraphicViewManager` | `ServicesSupport\GraphicViewManager.cs` | Manages graphic views (creation, activation, layout). |
| `SelectSet` | `ServicesSupport\SelectSet.cs` | Provides access to the current selection of objects. |
| `SelectMultiCaster` | `ServicesSupport\SelectMultiCaster.cs` | Multicasts select events to multiple listeners. |
| `LocateNotifier` | `ServicesSupport\LocateNotifier.cs` | Notifies listeners of locate (hover/highlight) events. |
| `SessionManager` (sealed) | `ServicesSupport\SessionManager.cs` | .NET wrapper for the COM SessionManager; manages session lifecycle. |
| `ClientTransactionManager` | `ServicesSupport\ClientTransactionManager.cs` | Manages client-side transactions for database operations. |
| `ValueManager` | `ServicesSupport\ValueManager.cs` | Stores and accesses key-value pairs during the session lifetime. |

## Services Derived from SessionFileService

These services persist state to session files and are restored when a session is reopened.

| Class | File Path | Description |
|-------|-----------|-------------|
| `ClientBusinessObjectCache` | `ServicesSupport\ClientBusinessObjectCache.cs` | Caches ClientBusinessObjects for efficient name and icon access. |
| `CommandGraphicViewManager` | `ServicesSupport\CommandGraphicViewManager.cs` | Manages graphic views created by commands (temporary views). |
| `CustomGraphicViewSetManager` | `ServicesSupport\CustomGraphicViewSetManager.cs` | Manages custom graphic view set objects. |
| `ModifyCommandManager` | `ServicesSupport\ModifyCommandManager.cs` | Handles modification of selected objects (modify command routing). |
| `ShowHideService` | `ServicesSupport\ShowHideService.cs` | Handles hiding and unhiding objects in graphic views. |
| `WorkspaceDefinitionService` (sealed) | `ServicesSupport\WorkspaceDefinitionService.cs` | Stores properties relevant to the workspace scope. |

## Services Derived from SessionFileCOMWrapperService

These services combine COM wrapping with session file persistence.

| Class | File Path | Description |
|-------|-----------|-------------|
| `ActiveCoordinateSystemManager` | `ServicesSupport\ActiveCoordinateSystemManager.cs` | Manages the active coordinate system; wraps the COM counterpart. |
| `ClientContext` | `ServicesSupport\ClientContext.cs` | Client context service providing database configuration and connection info. |
| `Preferences` | `ServicesSupport\Preferences.cs` | Saves and accesses user preferences during the session. |
| `TreeViewManager` | `ServicesSupport\TreeViewManager.cs` | Wraps the COM TreeViewManager for tree-based navigation. |
| `ViewStyleManager` | `ServicesSupport\ViewStyleManager.cs` | Manages view styles (colors, rendering modes) for graphic views. |
| `WorkingSet` | `ServicesSupport\WorkingSet.cs` | Provides access to the working set of objects loaded in the session. |

## Services Derived from TriadWidgetServiceBase

These services provide interactive 3D triad widgets for transform operations.

| Class | File Path | Description |
|-------|-----------|-------------|
| `TransformWidgetCommandService` (sealed) | `TransformWidgetCommandService.cs` | Interactive triad for Move/Rotate initiated from separate commands. |
| `TransformWidgetService` (sealed) | `TransformWidgetService.cs` | Interactive triad for Rotate/Translate operations from the graphics view. |
| `TriadWidgetService` (sealed) | `TriadWidgetService.cs` | Simple display-only triad widget (no interaction). |
