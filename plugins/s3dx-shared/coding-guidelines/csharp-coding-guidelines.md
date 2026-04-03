# C# Coding Guidelines

These rules apply to all generated C# code. They are derived from the project `.editorconfig` and team conventions.

## File Header (Required)

Every `.cs` file must start with this license header:

```csharp
// ------------------------------------------------------------------------------------------
// © 2026 Intergraph Corporation and/or its subsidiaries and affiliates. All rights reserved.
// ------------------------------------------------------------------------------------------
```

## Naming Conventions

| Symbol                             | Style                               | Example                           |
| ---------------------------------- | ----------------------------------- | --------------------------------- |
| Private fields                     | `_camelCase` (underscore prefix)  | `_progressListener`             |
| Constants                          | `PascalCase`                      | `MaxRetryCount`                 |
| Parameters / locals                | `camelCase`                       | `selectedObjects`               |
| Classes, structs, enums, delegates | `PascalCase`                      | `DeleteCommand`                 |
| Properties, methods, events        | `PascalCase`                      | `OnStart`, `CommitUndoMarker` |
| Interfaces                         | `IPascalCase` (prefix with `I`) | `IProgressListener`             |

## `var` Usage

- Do NOT use `var` for built-in types — use explicit types: `int count = 0;` not `var count = 0;`
- Use `var` when the type is apparent from the right side: `var list = new List<string>();`
- Do NOT use `var` elsewhere when the type is not obvious

## Braces and Formatting

- Always use braces for control flow blocks (`if`, `else`, `for`, `foreach`, `while`) even for single statements
- Allman style braces — opening brace on a new line for all constructs
- New line before `else`, `catch`, `finally`
- Indent `case` contents and `switch` labels
- No space after cast: `(int)value`
- Space after keywords in control flow: `if (condition)`

## Expression Style

- Do NOT use expression-bodied methods, constructors, or operators
- Expression-bodied properties, indexers, and accessors are allowed
- Prefer `is null` over `ReferenceEquals` for null checks
- Use object/collection initializers where appropriate
- Use `?.` (null propagation) and `??` (null coalescing)

## Modifiers

- Always specify accessibility modifiers (e.g., `private`, `public`) for non-interface members
- Mark fields `readonly` when possible
- Modifier order: `public, private, protected, internal, static, extern, new, virtual, abstract, sealed, override, readonly, unsafe, volatile, async`

## Usings

- Sort `System.*` usings first

## Single Exit Point

Functions must have a single exit point (one `return` statement at the end). Do not use early returns scattered through the method body. Use a result variable and conditional logic to flow to a single return.

**Correct** — single exit point:

```csharp
public string GetStatus(BusinessObject bo)
{
    string result = "Unknown";

    if (bo == null)
    {
        result = "Invalid";
    }
    else if (bo.IsActive)
    {
        result = "Active";
    }
    else
    {
        result = "Inactive";
    }

    return result;
}
```

**Incorrect** — multiple early returns:

```csharp
public string GetStatus(BusinessObject bo)
{
    if (bo == null) return "Invalid";
    if (bo.IsActive) return "Active";
    return "Inactive";
}
```

> **Exception**: Guard clauses in `OnStart` that call `AbortUnsavedChanges(); return;` for empty selection are acceptable — this is an established framework pattern seen across all 47 production commands.
