---
title: Quickstart
---

# Quickstart

Get up and running with ElasticAPM4D in minutes.

## 1. Installation

Add the `source` folder of the ElasticAPM4D repository to your Delphi Library Path (`Tools > Options > IDE > Environment Options > Delphi Options > Library`).

Alternatively, include the files directly in your project.

## 2. Basic Configuration

Configure the agent as early as possible in your application lifecycle (e.g., in the `.dpr` or the main form's `OnCreate`).

```delphi
uses
  Apm4D.Settings;

begin
  TApm4DSettings.Application.ServiceName := 'OrderProcessingService';
  TApm4DSettings.Application.ServiceVersion := '1.2.0';
  TApm4DSettings.Application.Environment := 'production';

  TApm4DSettings.Elastic.Url := 'https://your-apm-server:8200';
  TApm4DSettings.Elastic.Secret := 'your-secret-token';

  // Enable the agent
  TApm4DSettings.Activate;
end;
```

## 3. Your First Transaction

Wrap your important operations in a transaction.

```delphi
uses
  Apm4D;

procedure TForm1.btnProcessClick(Sender: TObject);
begin
  TApm4D.StartTransaction('ProcessOrder', 'request');
  try
    // Your business logic here
    DoWork;
  finally
    TApm4D.EndTransaction;
  end;
end;
```

## 4. Capture an Error

Capture exceptions automatically.

```delphi
try
  PerformRiskyOperation;
except
  on E: Exception do
  begin
    TApm4D.CaptureError(E);
    raise;
  end;
end;
```

## 5. Verify in Kibana

Open Kibana and navigate to **Observability > APM** to see your application data appearing in real-time.
