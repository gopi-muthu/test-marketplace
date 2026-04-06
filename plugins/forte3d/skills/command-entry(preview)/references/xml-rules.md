# S3Dx Commands XML Rules and Templates

## File Locations

| File | Purpose | Delivered in EUB? |
|------|---------|-------------------|
| `Xroot/Container/Configuration/en-US/Commands.xml` | Production command definitions | Yes |
| `Xroot/Container/Configuration/en-US/Ribbon.xml` | Production ribbon layout | Yes |
| `Xroot/Container/Configuration/en-US/DevelopmentCommands.xml` | Prototype/dev command definitions | No |
| `Xroot/Container/Configuration/en-US/DevelopmentRibbon.xml` | Prototype/dev ribbon layout | No |
| `MRoot/CommonApp/Testing/Commands/Smart3D/MissingCategories.csv` | Telemetry categories for commands without CommandGroup | Yes |

## Command Id Rules

- Must be **unique** across all S3Dx commands (both Commands.xml and DevelopmentCommands.xml)
- Should end with `Command` (e.g., `PlaceValveCommand`, `EditPipeRunCommand`)
- Once moved into Commands.xml, the Command Id **cannot be changed**
- Once in Commands.xml, a command **cannot be deleted** - only set to `Obsolete` category

## DisplayName Rules

- Must be **unique** across all commands - there should never be 2 matching DisplayNames
- Must be **meaningful** - a user typing it in the command search box should know exactly what it does
- Differentiating via tooltip alone is not acceptable
- No abbreviations unless industry-standard
- No misspelled words or run-on words
- Must not contain "command" or "cmd"
- Once in Commands.xml, the DisplayName **may** be changed (unlike Command Id)

### Verb Conventions

| Verb | When to Use | Example |
|------|-------------|---------|
| **Place** or **Route** | Placing a new object in the graphic view. Only add to DisplayName if there is also a separate Modify command for the same object. If both placement and modification are in 1 command, use only the object name. | `Place Pipe Support`, `Route Pipe` |
| **Insert** | Adding components to existing objects in the graphic view | `Insert Pipe Tap` |
| **New** | Creating non-graphic objects (e.g., items in hierarchy tree) | `New System` |
| **Select** | Command only adds to the select set | `Select By Filter` |
| **Create** | **Do NOT use.** Use `Place` (graphic) or `New` (non-graphic) instead | - |

### Automatic Modify Entry
When a command is added, a telemetry entry is automatically generated that prepends "Modify" to the DisplayName and adds "Modify Command" to the CommandParameter. The event data for the command indicates placement/modification in Telemetry.

## CommandGroup (Category) Rules

- No abbreviations allowed
- No misspelled words or run-on words
- Must be listed in the Categories-CommandGroup Changes spreadsheet
- If not listed, get PO approval and add to the spreadsheet (requires PO Sync meeting approval)
- For context-menu-only or modify-only commands, do NOT specify CommandGroup in XML - instead add to `MissingCategories.csv`

## CommandParameter Rules

- CommandParameter can be listed in Commands.xml but is **not supported at runtime** in S3Dx (ModernClient)
- It is **reserved for Telemetry use** (specifying Modify Commands and backwards compatibility)
- Each command needs a unique Command Id instead of relying on CommandParameter

## Options Rules

The `<Options>` element controls which UI surfaces a command appears on. It is optional — when omitted, all surfaces default to enabled.

### Structure

```xml
<Options>
  <Option Tag="Ribbon" Enabled="true" />
  <Option Tag="Shortcut" Enabled="false" />
  <Option Tag="Radial" Enabled="false" />
  <Option Tag="Search" Enabled="false" />
</Options>
```

### Option Tags

| Tag | Controls | Default (when `<Options>` is omitted) |
|-----|----------|----------------------------------------|
| `Ribbon` | Whether the command appears in the ribbon | Enabled |
| `Shortcut` | Whether the command appears in shortcut/context menus | Enabled |
| `Radial` | Whether the command appears in the radial menu | Enabled |
| `Search` | Whether the command appears in the command search box | Enabled |

### Common Patterns

| Pattern | Ribbon | Shortcut | Radial | Search | When to Use |
|---------|--------|----------|--------|--------|-------------|
| **No `<Options>` block** | ✅ | ✅ | ✅ | ✅ | Standard commands (most commands) |
| **Ribbon-only** | ✅ | ❌ | ❌ | ❌ | Ribbon controls like combo boxes, numeric up/down, and text boxes that only make sense in the ribbon (e.g., `ActiveWBSItemCommand`, `CoordinateSystemCommand`) |
| **Hidden from all** | ❌ | ❌ | ❌ | ❌ | Commands invoked only programmatically or hidden from all UI surfaces (e.g., `DrawingVolumeByViewCommand`, `CopyCommand` with specific CommandParameter) |

### Placement in XML

The `<Options>` element should appear **after** `<CommandGroup>` and **before** `<RibbonItems>`:

```xml
<Command Id="...">
  <DisplayName>...</DisplayName>
  <ToolTipTitle>...</ToolTipTitle>
  <ToolTipDescription>...</ToolTipDescription>
  <HelpIndex>...</HelpIndex>
  <CommandGroup>...</CommandGroup>
  <Options>
    ...
  </Options>
  <RibbonItems>
    ...
  </RibbonItems>
  <CanExecuteHandlers>
    ...
  </CanExecuteHandlers>
</Command>
```

## Command XML Templates

### Standard Command (with RibbonButton)

```xml
  <Command Id="MyNewCommand"
           IconId="Com_Placeholder"
           AssemblyQualifiedName="Namespace.ClassName,AssemblyName">
    <DisplayName Translate="true">My New Feature</DisplayName>
    <ToolTipTitle Translate="true">My New Feature</ToolTipTitle>
    <ToolTipDescription Translate="true">Description of what this command does.</ToolTipDescription>
    <HelpIndex>1234567</HelpIndex>
    <CommandGroup Translate="true">CategoryName</CommandGroup>
    <RibbonItems>
      <RibbonButton Size="Large"/>
    </RibbonItems>
    <CanExecuteHandlers>
      <CanExecuteHandler AssemblyQualifiedName="Namespace.HandlerClass,AssemblyName"/>
    </CanExecuteHandlers>
  </Command>
```

### Command with ICommandName

```xml
  <Command Id="MyNewCommand"
           IconId="Com_Placeholder"
           AssemblyQualifiedName="Namespace.ClassName,AssemblyName"
           ICommandName="SpecificCommandName">
    <DisplayName Translate="true">My New Feature</DisplayName>
    <ToolTipTitle Translate="true">My New Feature</ToolTipTitle>
    <ToolTipDescription Translate="true">Description of what this command does.</ToolTipDescription>
    <CommandGroup Translate="true">CategoryName</CommandGroup>
    <RibbonItems>
      <RibbonButton Size="Large"/>
    </RibbonItems>
    <CanExecuteHandlers/>
  </Command>
```

### Command with Options (ribbon-only control)

```xml
  <Command Id="MyComboBoxCommand"
           AssemblyQualifiedName="Namespace.ClassName,AssemblyName">
    <DisplayName Translate="true">My Combo Box</DisplayName>
    <ToolTipTitle Translate="true">My Combo Box</ToolTipTitle>
    <ToolTipDescription Translate="true">Select an item from the combo box.</ToolTipDescription>
    <HelpIndex>1234567</HelpIndex>
    <CommandGroup Translate="true">CategoryName</CommandGroup>
    <Options>
      <Option Tag="Ribbon" Enabled="true" />
      <Option Tag="Shortcut" Enabled="false" />
      <Option Tag="Radial" Enabled="false" />
      <Option Tag="Search" Enabled="false" />
    </Options>
    <RibbonItems>
      <RibbonComboBox Size="Large"/>
    </RibbonItems>
    <CanExecuteHandlers/>
  </Command>
```

### Toggle Button Command

```xml
  <Command Id="MyToggleCommand"
           IconId="Com_Placeholder"
           AssemblyQualifiedName="Namespace.ClassName,AssemblyName"
           ICommandName="ToggleBooleanPreferenceValue"
           CommandParameter="task.PreferenceKey">
    <DisplayName Translate="true">Toggle Feature</DisplayName>
    <ToolTipTitle Translate="true">Toggle Feature</ToolTipTitle>
    <ToolTipDescription Translate="true">Enable or disable the feature.</ToolTipDescription>
    <CommandGroup Translate="true">CategoryName</CommandGroup>
    <RibbonItems>
      <RibbonToggleButton Size="Large" PreferencesKey="task.PreferenceKey" DefaultValue="false"/>
    </RibbonItems>
    <CanExecuteHandlers/>
  </Command>
```

### Minimal Command (no ribbon, context-menu only)

```xml
  <Command Id="MyContextMenuCommand"
           AssemblyQualifiedName="Namespace.ClassName,AssemblyName">
    <DisplayName Translate="true">Context Menu Action</DisplayName>
  </Command>
```

## Ribbon XML Templates

### Adding a button to an existing group

```xml
<RibbonButton Name="MyNewCommand" Size="Medium" KeyTip="MN"/>
```

### Adding a button with AlternativeDisplayName

```xml
<RibbonButton Name="MyNewCommand" Size="Medium" KeyTip="MN">
  <AlternativeDisplayName Translate="true">Short Name</AlternativeDisplayName>
</RibbonButton>
```

### Adding a toggle button

```xml
<RibbonToggleButton Name="MyToggleCommand" Size="Medium" PreferencesKey="task.PreferenceKey" DefaultValue="false" KeyTip="MT"/>
```

### Adding a new group to an existing tab

```xml
<RibbonGroup Name="MyNewGroup">
  <DisplayName Translate="true">Group Display Name</DisplayName>
  <RibbonItems>
    <RibbonCollapsiblePanel Name="MyNewGroupPanel">
      <RibbonItems>
        <RibbonButton Name="MyNewCommand" Size="Medium" KeyTip="MN"/>
      </RibbonItems>
    </RibbonCollapsiblePanel>
  </RibbonItems>
</RibbonGroup>
```

### Split button with dropdown

```xml
<RibbonSplitButton Name="PrimaryCommand" Size="Medium">
  <AlternativeDisplayName Translate="true">Primary</AlternativeDisplayName>
  <DropDownContent>
    <RibbonButton Name="SecondaryCommand" Size="Medium">
      <AlternativeDisplayName Translate="true">Secondary</AlternativeDisplayName>
    </RibbonButton>
  </DropDownContent>
</RibbonSplitButton>
```

## DevelopmentRibbon.xml Tab Structure

The development ribbon has these tabs (use these names when placing prototype commands):

| Tab Name | KeyTip | Purpose |
|----------|--------|---------|
| `Existing1` (Classic Client 1) | E1 | Legacy piping, foulcheck, hangers, planning, common, translators |
| `Existing2` (Classic Client 2) | E2 | Civil, molded forms, materials handling, space mgmt, structural |
| `Developer` | V | Diagnostic tools, developer tools (icon browser, catalog browser, etc.) |
| `Testing` | I | Test framework commands, messages, catalog, deliverables |
| `AutomatedTesting` | AT | MCAT assistant, performance test assistant |
| `Prototypes` | Y | **Most new prototype commands go here** - Common, Route, Deliverables groups |
| `As-Built (Prototype)` | - | Handover preparation commands |
| `Integration(Prototype)` | I | Integration 2.0 commands (edit, permissions, work packages) |

## Promotion Checklist (Prototype to Production)

1. Confirm **MCRB approval** has been obtained
2. Remove command entry from `DevelopmentCommands.xml`
3. Add command entry to `Commands.xml` (before `</Commands>`)
4. Remove ribbon button from `DevelopmentRibbon.xml`
5. Add ribbon button to `Ribbon.xml` in the appropriate tab/group
6. Verify Command Id has not changed
7. Verify DisplayName follows all naming conventions
8. Verify CommandGroup is in the Categories-CommandGroup spreadsheet
9. Remind: once in Commands.xml, Command Id is permanent and command cannot be deleted

## Telemetry Notes

- Telemetry is updated once per sprint by the Square8s team
- Command writers only need to get Commands.xml and MissingCategories.csv correct
- The process: export commands via "Export Commands" on Developer tab, compare with Smart3DEvents.xlsx, present changes to Telemetry Review Board, update EMT
- Commands removed from XML must be kept in the telemetry spreadsheet as Obsolete for backwards compatibility
