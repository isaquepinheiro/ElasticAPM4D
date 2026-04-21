---
displayed_sidebar: elasticapm4dSidebar
title: Stacktrace Providers
---

Detailed stacktraces are essential for diagnosing errors in production. ElasticAPM4D supports multiple third-party providers and can automatically detect them based on project defines.

## Supported Providers

| Provider | Project Define | Requirement |
|----------|----------------|-------------|
| **MadExcept** | `madExcept` | MadExcept 4+ installed and active in the project. |
| **EurekaLog** | `EUREKALOG` | EurekaLog 7+ installed and active in the project. |
| **JEDI-JCL** | `jcl` | JCL Debug units and stack tracking enabled. |
| **Default** | None | Uses internal Delphi stacktrace (limited). |

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

## Custom Providers

If you use a different tool or want to implement custom stacktrace logic, you can create a subclass of `TStackTracer` and register it:

```delphi
type
  TMyStackTracer = class(TStackTracer)
  public
    procedure Capture(const AException: Exception; const AMaxFrames: Integer); override;
  end;

begin
  TApm4DSettings.AddStackTracer(TMyStackTracer);
end;
```

## Limits

The agent respects a limit of **15 frames** (defined by `MAX_FRAMES`) to keep payloads small and efficient.
