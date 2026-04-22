---
displayed_sidebar: elasticapm4dSidebar
title: Custom HTTP Transport
---

By default, ElasticAPM4D uses **Indy** (`TIdHTTP`) to send telemetry data to the Elastic APM Server. However, you can implement your own transport layer if you prefer another library (like NetHTTPClient, ICS, or Synapse) or need specific proxy/security configurations.

## The IApm4DHttpClient Interface

To create a custom transport, you must implement the `IApm4DHttpClient` interface defined in `Apm4D.Share.Types`:

```delphi
IApm4DHttpClient = interface
  ['{8844D1EB-D65D-4F29-B0F3-E2E1A299F7A2}']
  function Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
end;
```

### Implementation Example (System.Net.HttpClient)

```delphi
unit MyCustomTransport;

interface

uses
  System.Net.HttpClient, Apm4D.Share.Types;

type
  TMyHttpClient = class(TInterfacedObject, IApm4DHttpClient)
  public
    function Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
  end;

implementation

function TMyHttpClient.Post(const AUrl, ASecretToken, ATraceparent, ABody: string): Integer;
var
  LClient: THTTPClient;
  LResponse: IHTTPResponse;
  LStream: TStringStream;
begin
  LClient := THTTPClient.Create;
  LStream := TStringStream.Create(ABody, TEncoding.UTF8);
  try
    LClient.CustomHeaders['Content-Type'] := 'application/x-ndjson';
    if not ASecretToken.IsEmpty then
      LClient.CustomHeaders['Authorization'] := 'Bearer ' + ASecretToken;
      
    if not ATraceparent.IsEmpty then
      LClient.CustomHeaders['elastic-apm-traceparent'] := ATraceparent;

    LResponse := LClient.Post(AUrl, LStream);
    Result := LResponse.StatusCode;
  finally
    LStream.Free;
    LClient.Free;
  end;
end;

end.
```

## Registering the Custom Transport

You must provide a factory function that creates your custom client and register it in `TApm4DSettings` **before** activating the agent:

```delphi
uses
  Apm4D.Settings, MyCustomTransport;

function MyHttpClientFactory: IApm4DHttpClient;
begin
  Result := TMyHttpClient.Create;
end;

begin
  TApm4DSettings.SetHttpClientFactory(MyHttpClientFactory);
  TApm4DSettings.Activate;
end;
```

## Why use a custom transport?

- **Proxy Support:** If your corporate environment requires complex proxy authentication.
- **SSL/TLS:** If you need to use specific certificates or TLS versions not easily configured in Indy.
- **Dependency Management:** To avoid including Indy in your project if you already use another HTTP library.
- **Mocking:** For integration tests where you want to capture the outgoing NDJSON without sending it to a real server.
