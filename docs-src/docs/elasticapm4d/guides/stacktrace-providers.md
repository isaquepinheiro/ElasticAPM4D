---
displayed_sidebar: elasticapm4dSidebar
title: Stacktrace Providers
---

# Stacktrace Providers

ElasticAPM4D includes a flexible stacktrace capture system that integrates with popular Delphi debugging tools. This allows the agent to attach detailed source code context (file, line, and function) to captured error events.

## Automatic Detection

The agent is designed to automatically detect and register the best available provider at compile-time. You don't need to manually register providers in your code; simply add the appropriate conditional directive to your project options.

### Detection Priority

If multiple providers are available or multiple directives are defined, the agent follows this priority:

1. **MadExcept** (highest)
2. **EurekaLog**
3. **JEDI JCL**
4. **Default** (minimal stacktrace using native RTL functions)

## Supported Providers

| Provider | Conditional Directive | Requirement |
|----------|-----------------------|-------------|
| **MadExcept** | `madExcept` | [MadExcept](http://www.madshi.net/) installed and active in the project. |
| **EurekaLog** | `EUREKALOG` | [EurekaLog](https://www.eurekalog.com/) installed and active in the project. |
| **JEDI JCL** | `jcl` | [JEDI JCL](https://github.com/project-jedi/jcl) installed and configured with debug symbols. |

## Performance Optimization (Regex Caching)

Starting from version 1.0.0 (ESP-011), the stacktrace providers utilize **cached TRegEx instances**. 

In previous versions, regex patterns used for parsing stacktrace lines were compiled on every exception capture. Now, these patterns are compiled once during the class initialization (using class constructors) and reused across all capture events.

This optimization results in:
- Reduced CPU overhead during error reporting.
- Significant reduction in heap allocations.
- Faster response times for the application when an exception occurs.

## Manual Implementation

If you want to implement your own stacktrace provider, you can inherit from `TStackTracer` found in `Apm4D.Share.Stacktrace.pas` and register it using `TApm4DSettings.AddStackTracer`.

```delphi
type
  TCustomStackTracer = class(TStackTracer)
  public
    function Get: TArray<TStacktrace>; override;
    function GetCulprit: string; override;
  end;

// Registration
TApm4DSettings.AddStackTracer(TCustomStackTracer.Create);
```

## Best Practices

- **Debug Symbols:** For JCL to work correctly, ensure your project is configured to generate a `.map` file or includes JEDI debug information.
- **Production Use:** We recommend using MadExcept or EurekaLog for production environments as they provide the most reliable and detailed stacktraces with minimal overhead.
- **Binary Size:** Enabling these providers will increase your binary size due to the inclusion of debug metadata.
