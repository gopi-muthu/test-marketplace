---
name: s3d-solution-setup (preview)
description: Scaffold a new S3D <Component>Client or <Component>ClientCommands Visual Studio solution following S3D/.NET 8.0 WPF framework conventions. The "Commands" suffix is optional — the skill handles both. Includes main WPF library and a companion unit test project. Use this skill whenever users ask to create a new Client or ClientCommands solution, set up a new S3D module project, scaffold a new component project structure, or say things like "create new solution", "new Client project", "new ClientCommands project", "set up project for <Component>", or "scaffold S3D module". Always use this skill when creating any new S3D client or client commands project — even if the user just names a component without explicitly asking for a skill.
---

# S3D Client / ClientCommands Solution and Project Setup

Produces a complete, build-ready Visual Studio solution with:
- **`<Component><ProjectSuffix>`** — main .NET 8.0 WPF library project (`<ProjectSuffix>` = `ClientCommands` or `Client`)
- **`<Component><ProjectSuffix>Tests`** — MSTest unit test project (net8.0, win-x64, JustMock)

Folder/file structure reference: [Example of Files and Folder Structure.md](.References/Files%20and%20Folder%20Structure.md).

---

## Step 0: Gather Inputs

Before creating any file, confirm:

1. **`<Component>`** — the module name (e.g. `SpaceManagement`, `Compartment`, `Structure`). Verify the exact component name and corresponding folder name (e.g. `SpaceMgmt` vs `SpaceManagement`) in the existing codebase under `G:\KRoot`, `G:\MRoot`, and `G:\SRoot`.
2. **Root path** — search for the component folder under `G:\KRoot`, `G:\MRoot`, and `G:\SRoot` (in that order). Do not search any folder other than specified. The Root Path should start with G:\.
Run:

   ```powershell
   $component = "<Component>"
   $roots = @("G:\KRoot", "G:\MRoot", "G:\SRoot")
   $found = $roots | Where-Object { Test-Path "$_\$component\Client" } | Select-Object -First 1
   if (-not $found) { $found = "G:\SRoot" }   # fallback if not found in any root
   $componentRoot = "$found\$component"
   Write-Host "ComponentRoot = $componentRoot"
   $binaryDriveMap = @{ "G:\KRoot" = "K:\"; "G:\MRoot" = "M:\"; "G:\SRoot" = "S:\" }
   $binaryDrive = $binaryDriveMap[$found]
   Write-Host "BinaryDrive = $binaryDrive"
   ```

   Assign **`<ComponentRoot>`** = `$componentRoot` (e.g. `G:\MRoot\Equipment`). This is used for UnitTesting scripts (Phase 5) and the `ALIUnitTest` property in both project files.

   Assign **`<binaryDrive>`** = `$binaryDrive` — the virtual drive letter that mirrors the root folder (`K:\` for `G:\KRoot`, `M:\` for `G:\MRoot`, `S:\` for `G:\SRoot`). Used as the `OutputFolder` prefix in all UnitTesting scripts.

3. **`<ProjectSuffix>`** — determines the project name suffix (`ClientCommands` or `Client`). Infer from the user's request or from existing solutions already present in the component tree:

   ```powershell
   $cmdBase   = "$found\$component\Client\Commands"
   $clientBase = "$found\$component\Client"
   $hasCmds   = Get-ChildItem $cmdBase   -Filter "*ClientCommands.sln" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
   $hasClient = Get-ChildItem $clientBase -Filter "*Client.sln"        -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
   # Use whichever already exists; if neither, default to ClientCommands
   ```

   | User says | `<ProjectSuffix>` | `<RootPath>` | `<Namespace>` |
   |---|---|---|---|
   | `ClientCommands` / `commands` | `ClientCommands` | `$found\<ComponentFolder>\Client\Commands` | `Ingr.SP3D.<Component>.Client.Commands` |
   | `Client` only | `Client` | `$found\<ComponentFolder>\Client` | `Ingr.SP3D.<Component>.Client` |
   | Neither (default) | `ClientCommands` | `$found\<ComponentFolder>\Client\Commands` | `Ingr.SP3D.<Component>.Client.Commands` |

   Create `<RootPath>` if it doesn't exist. Assign **`<ProjectSuffix>`**, **`<RootPath>`**, and **`<Namespace>`** and use them throughout all phases below.

4. **5 fresh GUIDs** — generate now:

```powershell
1..5 | ForEach-Object { [System.Guid]::NewGuid().ToString("B").ToUpper() }
```
Do not reuse any GUIDs from other solutions or projects. Each new solution must have a unique set of GUIDs.

Assign: `GUID-1` = main project · `GUID-2` = solution · `GUID-3` = main project type · `GUID-4` = test project · `GUID-5` = test project type

---

## Phase 1 — Solution File

**Path**: `<RootPath>\<Component><ProjectSuffix>\<Component><ProjectSuffix>.sln`

```
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.5.33627.172
MinimumVisualStudioVersion = 10.0.40219.1
Project("{GUID-3}") = "<Component><ProjectSuffix>", "<Component><ProjectSuffix>\<Component><ProjectSuffix>.csproj", "{GUID-1}"
EndProject
Project("{GUID-5}") = "<Component><ProjectSuffix>Tests", "<Component><ProjectSuffix>Tests\<Component><ProjectSuffix>Tests.csproj", "{GUID-4}"
	ProjectSection(ProjectDependencies) = postProject
		{GUID-1} = {GUID-1}
	EndProjectSection
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{GUID-1}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{GUID-1}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{GUID-1}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{GUID-1}.Release|Any CPU.Build.0 = Release|Any CPU
		{GUID-4}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{GUID-4}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{GUID-4}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{GUID-4}.Release|Any CPU.Build.0 = Release|Any CPU
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
	GlobalSection(ExtensibilityGlobals) = postSolution
		SolutionGuid = {GUID-2}
	EndGlobalSection
EndGlobal
```

---

## Phase 2 — Main Project

### 2.1 Create Folders

```powershell
$base = "<RootPath>\<Component><ProjectSuffix>\<Component><ProjectSuffix>"
"Localizers","ViewModels","Properties","Resources" | ForEach-Object {
    New-Item -Path "$base\$_" -ItemType Directory -Force
}
```

### 2.2 Project File (`<Component><ProjectSuffix>.csproj`)

Create project file as per .\References\ComponentProjectSuffix\ComponentProjectSuffix.csproj


if the project is `Client` (`<ProjectSuffix>` = `Client`), also check for a companion Client DLL:
> **`<Component>Client` HintPath** — verify the actual location before adding. Some components (e.g. `PlanningClient`) ship to `$(Configuration)\` (non-NetCore), not `$(Configuration)\NetCore\`. Check with: `Get-ChildItem "X:\Container\Bin\Assemblies\Debug" -Filter "<Component>Client.dll" -Recurse | Select-Object FullName`



### 2.3 Properties Files (5 files)

| File | Notes |
|---|---|
| `AssemblyInfo.cs` | see References\ComponentProjectSuffix\Properties\AssemblyInfo.cs for exact content |
| `Resources.resx` | see References\ComponentProjectSuffix\Resources\Resources.resx for exact content |
| `Resources.Designer.cs` | see References\ComponentProjectSuffix\Resources\Resources.Designer.cs for exact content, class in namespace `<Namespace>.Properties`. |
| `Settings.settings` | see References\ComponentProjectSuffix\Properties\Settings.settings for exact content. |
| `Settings.Designer.cs` | see References\ComponentProjectSuffix\Properties\Settings.Designer.cs for exact content. |


### 2.4 Localizer (`Localizers\<ComponentProject><ProjectSuffix>Localizer.cs`)

see References\ComponentProjectSuffix\Localizers\ComponentProjectSuffixLocalizer.cs for exact content. Namespace should be `<Namespace>.Localizers` and class name should be `<Component>ClientLocalizer`. The `ResourceManager` constructor's base name string should be `<Namespace>.Resources.<Component><ProjectSuffix>` to match the resx file's fully-qualified resource name.


### 2.5 Resource File (`Resources\<Component><ProjectSuffix>.en-US.resx`)

see References\ComponentProjectSuffix\Resources\ComponentProjectSuffix.en-US.resx for exact content. The file name should be `<Component><ProjectSuffix>.en-US.resx` and the namespace for generated `Resources` class should be `<Namespace>.Resources`.

**Same Middle + NetCore references as main project** (use identical HintPaths), **except omit** `Intergraph.CommonToolkit.Middle`. **Add** the main project DLL reference:


---

## Phase 3 — Unit Test Project

### 3.1 Create Folder

```powershell
$testBase = "<RootPath>\<Component><ProjectSuffix>\<Component><ProjectSuffix>Tests"
New-Item -Path "$testBase\Properties" -ItemType Directory -Force
```

### 3.2 Project File (`<Component><ProjectSuffix>Tests.csproj`)

Create project file as per References\ComponentProjectSuffixTests\ComponentProjectSuffixTests.csproj. Namespace should be `<Namespace>.Tests` and AssemblyName should be `<Component><ProjectSuffix>Tests`. Verify all assembly references have `Private=False` and `SpecificVersion=False`. Ensure there is a `ProjectReference` to the main project with `Private=False`.


### 3.3 Properties File (`Properties\AssemblyInfo.cs`)

see References\ComponentProjectSuffixTests\Properties\AssemblyInfo.cs for exact content. Namespace should be `<Namespace>.Tests`.  Generate new GUID using powershell: `[guid]::NewGuid()` and update the `NEW_GUID` attribute with the new GUID generated.

### 3.4 Assembly Resolver (`AssemblyResolvingTestInitializer.cs`)

see References\ComponentProjectSuffixTests\AssemblyResolvingTestInitializer.cs for exact content. Namespace should be `<Namespace>.Tests`. Update the `args` array paths to match actual project locations for `CommonMiddle`, `ReferenceDataMiddle`, `CommonClient`, the main `<Component><ProjectSuffix>.csproj`, and this test project's `<Component><ProjectSuffix>Tests.csproj`.

---

## Phase 5 — UnitTesting Scripts

**Folder path**: `<ComponentRoot>\Testing\UnitTesting\`

> `<ComponentRoot>` = `$componentRoot` from Step 0 (e.g. `G:\MRoot\Equipment`).

Create the folder if it doesn't exist:

```powershell
New-Item -Path "<ComponentRoot>\Testing\UnitTesting" -ItemType Directory -Force
```

### 5.1 `<Component><ProjectSuffix>UnitTests.ps1`  *(one file per `<ProjectSuffix>`)*

Create this file for the requested `<ProjectSuffix>` (e.g. `EquipmentClientCommandsUnitTests.ps1`):

```powershell
Import-Module G:\mroot\CommonApp\Testing\UnitTesting\Invoke-Tests -Force

Invoke-Tests -TestAssemblyName "<Component><ProjectSuffix>Tests" -OutputFolder "<binaryDrive><Component>\Testing\UnitTesting\UnitTestResults" -TargetedArchitecture "x64"
```

> The `OutputFolder` uses the `<binaryDrive>` virtual drive (`K:\` for `G:\KRoot`, `M:\` for `G:\MRoot`, `S:\` for `G:\SRoot`). The `-TestAssemblyName` must match the test project's `AssemblyName`.

### 5.2 `UnitTestsSetup.bat`  *(create only if not already present)*

```batch
:: Set output folder
Set OUTPUTFOLDER=<binaryDrive><Component>\Testing\UnitTesting\UnitTestResults

:: Clear out old results
IF EXIST %OUTPUTFOLDER% CMD /c RMDIR /s /q %OUTPUTFOLDER%

exit /b 0
```

### 5.3 `UnitTestingSummary.ps1`  *(create only if not already present)*

```powershell
$OutputFolder = "<binaryDrive><Component>\Testing\UnitTesting\UnitTestResults"
$OutputFile = Join-Path $OutputFolder "UnitTestingSummary.txt"

# Remove the test summary file
If (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }

# Ensure user is an administrator
& {
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    if (!$IsAdmin)
    {
        $errorMessage = "`r`nTests must be run by machine administrators."
        Write-Host $errorMessage
        Add-Content $OutputFile $errorMessage
        exit -1
    }
}

# Append all result files into summary file
$files = Get-ChildItem $OutputFolder -Filter "*Results.txt"

$resultFileCount = $files.Count

$ExitCode = 0
Write-Host
foreach($file in $files) 
{ 
    $TestContext = "`r`n$($file.Name) Summary`r`n"
    
    $TestContext | Out-File -Append $OutputFile
    Get-Content $file.FullName | Out-File -Append $OutputFile 
    
    $HostTestHeader = $TestContext.TrimEnd("*Results.txt").Trim()
    Write-Host "$HostTestHeader"

    # Count the number of Failed strings, subtract the expected count
    $failed = Select-String -Pattern "Failed" -Path $file
    $failedCount = $failed.Count
    $failedCount -= 1 #for the summary line

    If ($failedCount -gt 0) 
    {
        Write-Host
        foreach($failure in $failed)
        {
            If (!$failure.Line.StartsWith("Total")) { Write-Host (">> {0}" -f $failure.Line) }
        }
        Write-Host
        Write-Host 

        $ExitCode = -1
    } 
    else 
    {
        Write-Host
        Write-Host ">> All Tests Succeeded"
        Write-Host
        Write-Host
    }
}

exit $ExitCode
```

### 5.4 `UnitTests.bld`  *(create if not present; if it already exists, append only the new `+$powershell` line after existing test lines)*

**Full file when creating from scratch:**

```
# Smart3D .NET Client Unit Tests

# Setup
$<ComponentRoot>\Testing\UnitTesting\UnitTestsSetup.bat

# Start Assert Helper
$G:\mroot\CommonApp\Testing\UnitTesting\StartAssertHelper.bat

+$powershell <ComponentRoot>\Testing\UnitTesting\<Component><ProjectSuffix>UnitTests.ps1

# Aggregate Results
$powershell <ComponentRoot>\Testing\UnitTesting\UnitTestingSummary.ps1

# Cleanup
$G:\mroot\CommonApp\Testing\UnitTesting\StopAssertHelper.bat
```

**When the file already exists** (another `<ProjectSuffix>` was added previously), insert a new `+$powershell` line after the last existing `+$powershell` line:

```
+$powershell <ComponentRoot>\Testing\UnitTesting\<Component><ProjectSuffix>UnitTests.ps1
```

---


## Phase 4 — Build & Verify

```powershell
Set-Location "<RootPath>\<Component><ProjectSuffix>"
dotnet restore
dotnet build --configuration Debug
```

Expected output files in `X:\Container\Bin\Assemblies\Debug\NetCore\`:
- `<Component><ProjectSuffix>.dll` + `.xml`
- `<Component><ProjectSuffix>Tests.dll` + `.xml`

---

## Verification Checklist

- [ ] `<ProjectSuffix>` and `<Namespace>` determined correctly
- [ ] Solution file: GUIDs correct, both `.csproj` paths use `<Component><ProjectSuffix>`, test project has `ProjectDependencies` section
- [ ] Main project: `.csproj` (RootNamespace=`<Namespace>`, AssemblyName=`<Component><ProjectSuffix>`), 4 subfolders, 5 Properties files, Localizer, `.en-US.resx`
- [ ] Test project: `.csproj` (RootNamespace=`<Namespace>.Tests`, AssemblyName=`<Component><ProjectSuffix>Tests`), `Properties\AssemblyInfo.cs`, `AssemblyResolvingTestInitializer.cs`
- [ ] All assembly references: `Private=False`, `SpecificVersion=False`
- [ ] UnitTesting scripts: `<Component><ProjectSuffix>UnitTests.ps1` created; `UnitTestsSetup.bat`, `UnitTestingSummary.ps1`, `UnitTests.bld` present (created or updated) in `<ComponentRoot>\Testing\UnitTesting\`
- [ ] Build: no errors, no warnings

---

## Common Issues

| Symptom | Fix |
|---|---|
| `CS0579: Duplicate 'AssemblyCompany' (or 'AssemblyProduct') attribute` | Remove `AssemblyCompany`, `AssemblyProduct`, and `AssemblyCopyright` from `AssemblyInfo.cs` — they are already defined by the linked `X:\Bldtools\S3DVersionAssemblyInfo.cs` |
| `Could not find key file: key.snk` | Verify `G:\Xroot\Tools\Developer\Key\key.snk` exists and is readable |
| Assembly reference not found at build | Build dependency assemblies first; verify `X:\Container\Bin\Assemblies\` is populated |
| Output directory missing | `New-Item "X:\Container\Bin\Assemblies\Debug\NetCore" -ItemType Directory -Force` |rebuild solution |
| Localizer resource not found at runtime | Confirm the base name string in `ResourceManager` constructor matches the resx file's fully-qualified resource name: `<Namespace>.Resources.<Component><ProjectSuffix>` |

---

## Next Steps After Setup

1. **Base command class** — create `Base<Component>Command.cs` abstract class (see Command-Development-Plan.md)
2. **ViewModels** — create placement ViewModels in `ViewModels\` folder
3. **Concrete commands** — implement commands following existing `<RootPath>\` patterns