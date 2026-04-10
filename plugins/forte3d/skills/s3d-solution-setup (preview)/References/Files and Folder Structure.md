# <Component>ClientCommands Project/Solution files and folder structure organization.

Location: G:\<root>\<Component>\Client\Commands\ folder (when `<ProjectSuffix>` = `ClientCommands`) or G:\<root>\<Component>\Client\ (when `<ProjectSuffix>` = `Client`).
<root> may be KRoot, MRoot or SRoot.
<Component> is provided by user.
In some cases <Component> provided by the user differs by existing folder name slightly. For example, corresponding Folder for SpaceManagement may be SpaceMgmt.


<Component><ProjectSuffix>/
├── <Component><ProjectSuffix>/          (Main project)
│   ├── Localizers/
│   │   └── <Component>ClientLocalizer.cs
│   ├── ViewModels/
│   ├── Properties/
│   │   ├── AssemblyInfo.cs
│   │   ├── Resources.Designer.cs
│   │   ├── Resources.resx
│   │   ├── Settings.Designer.cs
│   │   └── Settings.settings
│   ├── Resources/
│   │   └── <Component><ProjectSuffix>.en-US.resx
│   └── <Component><ProjectSuffix>.csproj
├── <Component><ProjectSuffix>Tests/     (Unit test project)
│   ├── Properties/
│   │   └── AssemblyInfo.cs
│   ├── AssemblyResolvingTestInitializer.cs
│   └── <Component><ProjectSuffix>Tests.csproj
└── <Component><ProjectSuffix>.sln       (Solution file)
```

---

## UnitTesting Scripts

Location: G:\<root>\<Component>\Testing\UnitTesting\
(`<ComponentRoot>\Testing\UnitTesting\` where `<ComponentRoot>` = `G:\<root>\<Component>`)

```
<Component>\
└── Testing\
    └── UnitTesting\
        ├── <Component>ClientUnitTests.ps1          (runs EquipmentClientTests; present when ClientCommands project exists)
        ├── <Component>ClientCommandsUnitTests.ps1  (runs EquipmentClientCommandsTests; present when Client project exists)
        ├── UnitTestingSummary.ps1                  (aggregates all *Results.txt into a summary; shared)
        ├── UnitTests.bld                           (build script; lists setup, per-suffix test runs, summary, cleanup)
        └── UnitTestsSetup.bat                      (clears M:\<Component>\Testing\UnitTesting\UnitTestResults\)
```

### Per-suffix script naming

| `<ProjectSuffix>` | Script file |
|---|---|
| `ClientCommands` | `<Component>ClientCommandsUnitTests.ps1` |
| `Client` | `<Component>ClientUnitTests.ps1` |

### `UnitTests.bld` — line added per suffix

One `+$powershell` line is added (or appended) for each `<ProjectSuffix>`:

```
+$powershell <ComponentRoot>\Testing\UnitTesting\<Component><ProjectSuffix>UnitTests.ps1
```
