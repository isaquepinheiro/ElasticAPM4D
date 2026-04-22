---
displayed_sidebar: elasticapm4dSidebar
title: Introduction
---

ElasticAPM4D solves application observability for Delphi applications by exposing a focused API to instrument business operations and runtime events. The library tracks transactions and spans, captures exceptions, records metadata and metricsets, and forwards telemetry to Elastic APM.

The project uses a facade-first model. Application code calls TApm4D and TApm4DSettings, while the framework handles serialization, queueing, and background transport internally.

## Key concepts

- **Transaction:** top-level business or request operation.
- **Span:** nested sub-operation executed inside a transaction.
- **Error event:** exception snapshot attached to the active tracing context.
- **Metricset:** periodic runtime metrics such as CPU and memory.
- **Trace context:** distributed tracing continuation with elastic-apm-traceparent.

## Features
 
 - **Third-party Stacktrace Support:** Built-in integration with **MadExcept**, **EurekaLog**, and **JEDI-JCL** for detailed error diagnostics.
 - **Flexible Transport:** Decoupled HTTP transport layer allowing custom client implementations.
 - **Resilient Delivery (v1.1.0):** Exponential backoff with jitter for handling transient HTTP 429 and 5xx errors.
 - **Structured Elastic APM intake v2 output.**
 - **Thread-aware transaction context with asynchronous delivery.**

## Target audience

This documentation is for Delphi developers and maintainers who need to instrument applications, validate behavior with tests, and troubleshoot runtime telemetry flow.

## Why use it

- Native Delphi instrumentation with low adoption friction.
- High-fidelity error reporting with stacktrace provider support.
- Performance-oriented asynchronous delivery architecture.

