---
title: Auto-Instrumentation
---

# Auto-Instrumentation (Windows only)

On Windows, ElasticAPM4D can automatically intercept common Delphi events and components to provide telemetry without changing your business logic.

## Interceptor Builder

The easiest way to enable auto-instrumentation is using the `TApm4DInterceptorBuilder`.

```delphi
uses
  Apm4D.Interceptor;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Injects interceptors for Buttons, DataSets, and RESTRequests
  TApm4DInterceptorBuilder.CreateDefault(Self).Inject;
end;
```

## Supported Interceptors

| Interceptor | Description |
|-------------|-------------|
| **OnClick** | Automatically starts a transaction when a TButton or TBitBtn is clicked. |
| **DataSet** | Captures database operations (Open, ExecSQL) as spans. |
| **RESTRequest** | Intercepts `TRESTRequest` to capture outgoing HTTP calls as spans. |

## Customizing Interceptors

You can register specific classes for interception:

```delphi
TApm4DSettings.RegisterInterceptor(TApm4DInterceptOnClick, [TMyCustomButton]);
```
