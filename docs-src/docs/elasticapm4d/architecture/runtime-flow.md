---
displayed_sidebar: elasticapm4dSidebar
title: Runtime Flow
---

## Main sequence

1. Application code starts a transaction using TApm4D.
2. Optional spans and errors are attached to the active context.
3. Events are serialized to NDJSON envelopes.
4. NDJSON items are enqueued in TQueueSingleton.
5. Background sender thread batches and posts payloads to Elastic APM intake.

## Error points

- **No active transaction:** StartSpan, StartSpanDb, and StartSpanRequest require an open transaction and raise ETransactionNotFound when none exists.
- **Global state leakage:** singleton settings or queue state can leak between tests without teardown.
- **Transport delivery issues:** endpoint, token, or network problems may prevent event upload.
- **Windows-only interceptors:** interceptor behavior differs on non-Windows targets.
