---
title: Configuration Reference
---

# Configuration Reference

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
| `Url` | `http://localhost:8200` | The URL of your Elastic APM Server. |
| `Secret` | `''` | Authentication token for the APM Server. |
| `UpdateTime` | `60000ms` (1m) | How often (in ms) to send batched events to the server. |
| `MaxJsonPerThread` | `60` | Maximum number of events to batch in a single request. |
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

Select how stack traces are captured when an error occurs.

| Method | Parameters | Description |
|--------|------------|-------------|
| `SetStacktraceProvider` | `TApm4DStacktraceProvider` | Selects the provider (`spAutomatic`, `spMadExcept`, `spEurekaLog`, `spJcl`, `spNone`). |

Providers:
- `spAutomatic`: Automatically detects if MadExcept, EurekaLog, or JCL is present (via compiler defines).
- `spNone`: Disables stack trace capture.

## Internal Logging

Configured via `TApm4DSettings.Log`.

| Property | Default | Description |
|----------|---------|-------------|
| `Level` | `llError` | Internal log level for the agent (`llDebug`, `llInfo`, `llWarning`, `llError`). |
| `Enabled` | `False` | Enables logging agent activity to a local file or console. |
