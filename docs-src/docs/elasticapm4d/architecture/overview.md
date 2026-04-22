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
- **TQueueSingleton + TSendThread:** queue and asynchronous transport pipeline.
- **TStacktraceEngine:** abstraction for pluggable stacktrace providers (MadExcept, EurekaLog, JCL).
- **Interceptor units:** optional automatic instrumentation for VCL and data access flows.

## Extensibility

- Custom stacktrace providers through TApm4DSettings.AddStackTracer.
- Distributed tracing continuation with StartTransaction(name, type, traceId).
- Additional instrumentation can be added through interceptor registration APIs.
