---
displayed_sidebar: elasticapm4dSidebar
title: Quickstart
---

## Prerequisites

- Delphi project configured to find source/ units.
- Elastic APM URL configured in TApm4DSettings.Elastic.Url.

## Minimal example

```delphi
uses
  Apm4D,
  Apm4D.Settings;

procedure RunSample;
begin
  TApm4DSettings.Activate;
  TApm4DSettings.Application.SetName('MyApp').SetEnvironment('development');

  TApm4D.StartTransaction('ProcessSales', 'business');
  try
    TApm4D.StartSpan('LoadOrders', 'db.query');
    try
      // business work
    finally
      TApm4D.EndSpan;
    end;
  finally
    TApm4D.EndTransaction(success);
  end;
end;
```

## Enabling Stacktrace

To capture detailed stacktraces with file names and line numbers, add the conditional directive for your preferred provider to your project's **Conditional Defines**:

- **MadExcept:** `madExcept`
- **EurekaLog:** `EUREKALOG`
- **JCL:** `jcl`

The agent automatically detects and uses the first available provider from this list.

## Next steps

- [Architecture](../architecture/overview.md)
- [Runtime Flow](../architecture/runtime-flow.md)
- [API Reference](../reference/api.md)
