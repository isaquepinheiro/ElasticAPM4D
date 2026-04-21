---
displayed_sidebar: elasticapm4dSidebar
title: Overview
---

## Context

ElasticAPM4D is a Delphi library layer between application instrumentation calls and the Elastic APM intake endpoint. It is not a full observability platform by itself.

## Main components

- **TApm4D facade:** public entrypoint used by application code.
- **TApm4DSettings singleton:** global runtime configuration and feature toggles.
- **TDataController threadvar context:** per-thread transaction state.
- **TApm4DSerializer:** JSON and NDJSON formatting via REST.Json.
- **IApm4DHttpClient:** abstraction for HTTP delivery (Indy implementation included by default).
- **TQueueSingleton + TSendThread:** queue and asynchronous transport pipeline using the HTTP abstraction.
- **Interceptor units:** optional automatic instrumentation for VCL and data access flows.

## Extensibility

- **Stacktrace Providers:** Native support for MadExcept, EurekaLog, and JCL, plus custom providers via `TApm4DSettings.AddStackTracer`.
- **HTTP Transport:** Swap the default Indy transport by providing a custom `IApm4DHttpClient` factory.
- **Distributed Tracing:** Continuation with `StartTransaction(name, type, traceId)`.
- **Interceptors:** Registration APIs for custom instrumentation logic.

