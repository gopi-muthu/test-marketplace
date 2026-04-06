---
name: command-entry
description: >
  Guides adding new S3Dx command entries to the XML configuration files (Commands.xml, DevelopmentCommands.xml, Ribbon.xml, DevelopmentRibbon.xml).
  Use this skill whenever the user wants to add a new command, promote a prototype command to production, register a command in the ribbon,
  configure command telemetry, or work with S3Dx command XML configuration. Also triggers when the user mentions DevelopmentCommands.xml,
  Commands.xml, DevelopmentRibbon.xml, Ribbon.xml, command registration, ribbon placement, command promotion, or S3Dx command setup.
---
# S3Dx Command Entry Skill

This skill walks through adding a new command entry to the S3Dx XML configuration files. There are two workflows:

1. **Prototype** - command goes into `DevelopmentCommands.xml` + `DevelopmentRibbon.xml`
2. **Production Promotion** - command goes into `Commands.xml` + `Ribbon.xml` (requires MCRB approval)

The config files live at: `Xroot/Container/Configuration/en-US/`

Read `references/xml-rules.md` for the full set of naming rules, telemetry guidelines, and XML structure templates before generating any XML.

## Workflow

### Step 1: Determine the intent

Ask the user:

> Are you adding a **new prototype command** or **promoting an existing prototype to production**?

If promoting, also confirm:

> Has this command received **MCRB approval**?

### Step 2: Gather command metadata

Ask the user for the following information. Present them as a numbered list and wait for answers before proceeding. If the user provides partial info, ask only for the missing pieces.

1. **Command Id** - Must be unique across all S3Dx commands. Should end with `Command` (e.g., `PlaceValveCommand`). Once in Commands.xml, this cannot be changed.
2. **DisplayName** - Must be unique and meaningful. The user should be able to identify the command from this name alone in the search box. See the naming rules in `references/xml-rules.md` for verb conventions (Place, Route, Insert, New, etc.). No abbreviations unless industry-standard. No misspellings or run-on words. Must not contain "command" or "cmd".
3. **IconId** - The icon identifier (e.g., `S3D_Route_Place_Pipe`, `Com_Placeholder`). Use `Com_Placeholder` if no icon is assigned yet.
4. **AssemblyQualifiedName** - The fully qualified .NET type and assembly (e.g., `Ingr.SP3D.Route.Client.PlacePipeCommand,RoutePipeClientCommands`).
5. **ToolTipTitle** - Short title for the tooltip.
6. **ToolTipDescription** - Longer description shown in the tooltip hover.
7. **CommandGroup (Category)** - The telemetry category. Must match an entry in the Categories-CommandGroup spreadsheet. No abbreviations. If the category doesn't exist, the user needs PO approval. For context-menu-only or modify-only commands, skip this and instead add the entry to `MRoot/CommonApp/Testing/Commands/Smart3D/MissingCategories.csv`.
8. **HelpIndex** - (Optional) The help topic ID number.
9. **ICommandName** - (Optional) Only needed if the command implements a named ICommand pattern different from the class name.
10. **CommandParameter** - (Optional) Note: CommandParameter is reserved for Telemetry use in S3Dx (ModernClient). It is not functionally supported at runtime.
11. **Options** - (Optional) Controls which UI surfaces the command appears on. Contains four `<Option>` tags: `Ribbon`, `Shortcut`, `Radial`, and `Search`, each with `Enabled="true"` or `Enabled="false"`. When omitted, all surfaces are enabled by default. Use this to hide a command from specific surfaces (e.g., hide from Search and Radial, or hide from all surfaces for programmatically-invoked commands). See `references/xml-rules.md` for details and common patterns.

### Step 3: Gather ribbon placement details

Ask the user:

1. **Which ribbon tab** should this command appear on? (For prototypes, this is typically the `Prototypes` tab. For production, ask which existing tab or if a new tab is needed.)
2. **Which ribbon group** within that tab? (Existing group name, or describe a new group.)
3. **Button size** - `Small`, `Medium`, or `Large`?
4. **Button type** - `RibbonButton`, `RibbonToggleButton`, or `RibbonSplitButton`?
5. **AlternativeDisplayName** - (Optional) Shorter name shown on the ribbon button itself.
6. **KeyTip** - (Optional) Keyboard shortcut letters for the ribbon button.
7. **CanExecuteHandlers** - (Optional) Any CanExecuteHandler assembly qualified names that gate when the command is enabled.

### Step 4: Validate against rules

Before generating XML, validate all inputs against the rules in `references/xml-rules.md`. Flag any violations to the user:

- DisplayName must not duplicate any existing DisplayName in Commands.xml or DevelopmentCommands.xml
- DisplayName verb conventions (Place/Route for graphic objects, New for non-graphic, Insert for adding to existing, never use Create)
- CommandGroup must be a recognized category
- Command Id must be unique and end with "Command"
- No abbreviations, misspellings, or "cmd"/"command" in DisplayName

### Step 5: Generate the XML entries

Generate two XML snippets:

1. **Command entry** - for `DevelopmentCommands.xml` (prototype) or `Commands.xml` (production)
2. **Ribbon entry** - for `DevelopmentRibbon.xml` (prototype) or `Ribbon.xml` (production)

Present both snippets to the user for review before making any file changes.

### Step 6: Apply changes

After user approval, insert the XML into the appropriate files. For the command entry, add it before the closing `</Commands>` tag. For the ribbon entry, add the button reference into the correct tab/group.

### Step 7: Handle promotion (if applicable)

When promoting from prototype to production:

1. Remove the command entry from `DevelopmentCommands.xml`
2. Add it to `Commands.xml`
3. Remove the ribbon reference from `DevelopmentRibbon.xml`
4. Add the ribbon reference to `Ribbon.xml` in the appropriate tab/group
5. Remind the user: once in Commands.xml, the Command Id cannot be changed and the command cannot be deleted (only set to Obsolete category)

### Step 8: Telemetry reminder

After adding the command, remind the user:

- Telemetry is updated once per sprint by Square8s team
- The command writer only needs to ensure Commands.xml and MissingCategories.csv are correct
- If the command has no CommandGroup (context-menu-only or modify-only), add it to `MRoot/CommonApp/Testing/Commands/Smart3D/MissingCategories.csv`
