---
displayed_sidebar: elasticapm4dSidebar
title: Stacktrace Providers
---

Detailed stacktraces are essential for diagnosing errors in production. ElasticAPM4D includes a flexible stacktrace capture system that integrates with popular Delphi debugging tools. This allows the agent to attach detailed source code context (file, line, and function) to captured error events.

## Supported Providers

| Provider | Project Define | Requirement |
|----------|----------------|-------------|
| **MadExcept** | `madExcept` | MadExcept 4+ installed. Uses `MadStackTrace` unit. |
| **EurekaLog** | `EUREKALOG` | EurekaLog 7+ installed. Uses `ExceptionLog7` and `ECallStack` units. |
| **JEDI-JCL** | `jcl` | JCL Debug units and stack tracking enabled. Uses `JclDebug` unit. |
| **Default** | None | Uses internal Delphi stacktrace (requires debug symbols). |

## How to Enable

### 1. Add the Conditional Define

To enable a provider, add the corresponding define to your project's **Conditional Defines** (Project > Options > Delphi Compiler):

- For MadExcept: `madExcept`
- For EurekaLog: `EUREKALOG`
- For JCL: `jcl`

### 2. Automatic Detection

By default, `TApm4DSettings.StacktraceProvider` is set to `spAutomatic`. In this mode, the agent selects the first available provider in the following order:

1. MadExcept
2. EurekaLog
3. JCL
4. None (Fallback to default)

### 3. Manual Selection

You can force a specific provider at runtime:

```delphi
uses
  Apm4D.Settings,
  Apm4D.Share.Types;

begin
  TApm4DSettings.SetStacktraceProvider(spEurekaLog);
  TApm4DSettings.Activate;
end;
```

## Performance Optimization (Regex Caching)

Starting from version 1.0.0 (ESP-011), the stacktrace providers utilize **cached TRegEx instances**. 

In previous versions, regex patterns used for parsing stacktrace lines were compiled on every exception capture. Now, these patterns are compiled once during the class initialization (using class constructors) and reused across all capture events.

This optimization results in:
- **Reduced CPU overhead** during error reporting.
- **Significant reduction in heap allocations** (no redundant regex object creation).
- **Faster response times** for the application when an exception occurs.

## Custom Providers

If you use a different tool or want to implement custom stacktrace logic, you can create a subclass of `TStackTracer` (found in `Apm4D.Share.Stacktrace.pas`) and register it:

```delphi
type
  TMyStackTracer = class(TStackTracer)
  public
    function Get: TArray<TStacktrace>; override;
    function GetCulprit: string; override;
  end;

begin
  TApm4DSettings.AddStackTracer(TMyStackTracer.Create);
end;
```

## Best Practices

- **Debug Symbols:** For JCL to work correctly, ensure your project is configured to generate a `.map` file or includes JEDI debug information.
- **Production Use:** We recommend using MadExcept or EurekaLog for production environments as they provide the most reliable and detailed stacktraces with minimal overhead.
- **Limits:** The agent respects a limit of **15 frames** (defined by `MAX_FRAMES`) to keep payloads small and efficient.
