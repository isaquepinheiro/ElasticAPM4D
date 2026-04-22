---
title: Introduction
---

# Introduction

**ElasticAPM4D** is a powerful, native Delphi library that integrates your applications with the Elastic Observability ecosystem. By instrumenting your code with ElasticAPM4D, you gain deep visibility into your application's performance and health.

## Why use ElasticAPM4D?

In modern software development, understanding how your application behaves in production is crucial. ElasticAPM4D helps you:

- **Identify Bottlenecks**: See exactly which parts of your code or database queries are slow.
- **Debug Faster**: Get detailed stack traces and context for every error that occurs in your application.
- **Monitor Health**: Keep an eye on system resources and application-specific metrics.
- **Correlate Data**: Link traces across different services to understand the full lifecycle of a request.

## How it works

The agent runs as part of your Delphi process. It collects telemetry data and buffers it in an internal queue. A background thread periodically flushes this data to the Elastic APM Server using the [Intake API v2](https://www.elastic.co/guide/en/apm/guide/current/intake-api.html).

### Data Types

- **Transactions**: Highest level of instrumentation (e.g., an HTTP request or a background job).
- **Spans**: Steps within a transaction (e.g., a database query or a method call).
- **Errors**: Captured exceptions with stack traces.
- **Metrics**: Periodic snapshots of system/process state.

## License

ElasticAPM4D is licensed under the MIT License.
