---
displayed_sidebar: elasticapm4dSidebar
title: API - Reference
---

## Main inputs

| Item | Type | Description |
|------|------|-------------|
| TApm4D.StartTransaction(name, kind) | method | Starts a top-level operation context. |
| TApm4D.StartTransaction(name, kind, traceId) | method | Starts a transaction continuing an incoming trace. |
| TApm4D.StartSpan(name, kind) | method | Creates a nested operation under current transaction/span. |
| TApm4D.StartSpanDb(name, dbType) | method | Creates a database span under the active transaction/span. |
| TApm4D.StartSpanRequest(resource, method) | method | Creates an external/request span under the active transaction/span. |
| TApm4D.EndSpan | method | Ends current active span. |
| TApm4D.EndTransaction(outcome) | method | Closes transaction and sets outcome. |
| TApm4D.AddError(exception) | method | Captures exception details and links to current context. |
| TApm4DSettings.Activate / Deactivate | method | Enables or disables runtime capture and delivery. |
| TApm4DSettings.Elastic.* | settings | Configures URL, auth token, batch interval, and queue limits. |

## Main outputs

| Item | Type | Description |
|------|------|-------------|
| Transaction event | NDJSON object | Serialized transaction payload consumed by Elastic intake. |
| Span event | NDJSON object | Serialized span with timing and parent relationships. |
| Error event | NDJSON object | Captured exception envelope with optional stacktrace. |
| Metadata event | NDJSON object | Service, host, process, and cloud metadata. |
| Metricset event | NDJSON object | Periodic runtime metrics. |
| Trace header | string | elastic-apm-traceparent value for propagation. |

## Rules and contracts

- Activate settings before emitting telemetry.
- Keep transaction/span lifecycle balanced (start and end pairs).
- Start a transaction before calling StartSpan, StartSpanDb, or StartSpanRequest.
- Calling span-start APIs without an active transaction raises ETransactionNotFound.
- Use ReleaseInstance in teardown for isolated tests.
- Do not assume interceptor availability outside Windows builds.
- Use documented defaults when explicit settings are not provided.
