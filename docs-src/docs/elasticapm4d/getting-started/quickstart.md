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

## Next steps

- [Architecture](../architecture/overview.md)
- [Runtime Flow](../architecture/runtime-flow.md)
- [API Reference](../reference/api.md)
