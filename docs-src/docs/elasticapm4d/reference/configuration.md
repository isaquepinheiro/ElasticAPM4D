---
displayed_sidebar: elasticapm4dSidebar
title: Configuration Reference
---

Global configuration for the ElasticAPM4D agent is managed through the `TApm4DSettings` class.

## Activation

The agent must be explicitly activated to begin capturing and sending telemetry.

```delphi
TApm4DSettings.Activate;
TApm4DSettings.Deactivate;
if TApm4DSettings.IsActive then ...
```

## Elastic Server Settings

Configured via `TApm4DSettings.Elastic`.

| Property | Default | Description |
|----------|---------|-------------|
| `ServerUrl` | `http://localhost:8200` | The URL of your Elastic APM Server. |
| `SecretToken` | `''` | Authentication token for the APM Server. |
| `ApiKey` | `''` | Alternative authentication via API Key. |
| `ServiceNodeName` | `''` | Unique name for the service node. |
| `FlushInterval` | `10s` | How often to send batched events to the server. |
| `MaxQueueSize` | `500` | Maximum number of events to queue before dropping new ones. |
| `MaxRetries` | `5` | Maximum number of retry attempts for transient errors (429, 5xx). |
| `InitialRetryDelay` | `1000ms` | Initial delay for the exponential backoff algorithm. |
| `MaxRetryDelay` | `30000ms` | Maximum delay for the exponential backoff algorithm. |

## Application Metadata

Configured via `TApm4DSettings.Application`.

| Property | Default | Description |
|----------|---------|-------------|
| `ServiceName` | (Exe name) | Name of the service as it appears in Elastic APM. |
| `ServiceVersion` | `1.0.0` | Version of your application. |
| `Environment` | `production` | Deployment environment (e.g., development, staging). |

## Stacktrace Configuration

Configured via `TApm4DSettings`.

| Method | Parameters | Description |
|--------|------------|-------------|
| `SetStacktraceProvider` | `TApm4DStacktraceProvider` | Selects the provider (`spAutomatic`, `spMadExcept`, `spEurekaLog`, `spJcl`, `spNone`). |
| `AddStackTracer` | `TStackTracerClass` | Registers a custom stacktracer implementation. |

## HTTP Transport

| Method | Parameters | Description |
|--------|------------|-------------|
| `SetHttpClientFactory` | `TApm4DHttpClientFactory` | Injects a custom HTTP client factory. Default is Indy. |

## Internal Logging

Configured via `TApm4DSettings.Log`.

| Property | Default | Description |
|----------|---------|-------------|
| `Level` | `llError` | Internal log level for the agent (`llDebug`, `llInfo`, `llWarning`, `llError`). |
| `Enabled` | `False` | Enables logging agent activity to a local file or console. |
