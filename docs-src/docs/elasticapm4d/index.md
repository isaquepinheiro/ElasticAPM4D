---
displayed_sidebar: elasticapm4dSidebar
title: ElasticAPM4D
---

ElasticAPM4D is a native Delphi APM agent that captures transactions, spans, errors, and metricsets and sends them to Elastic APM using intake v2 NDJSON.

## Where to start

- [Introduction](introduction.md)
- [Installation](getting-started/installation.md)
- [Quickstart](getting-started/quickstart.md)
- [Architecture](architecture/overview.md)
- [API](reference/api.md)
- [Stacktrace Providers](guides/stacktrace-providers.md)
- [Tests](tests/overview.md)

## Scope

- **Covers:** instrumentation via TApm4D, global settings via TApm4DSettings, queue-based async delivery, NDJSON serialization, and built-in interceptors.
- **Does not cover:** hosted Elastic infrastructure setup, CI pipeline orchestration, or external HTTP mock abstractions not yet present in source.
