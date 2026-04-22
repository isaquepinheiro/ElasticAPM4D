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
6. **Retry Loop:** If delivery fails with transient errors (429/5xx), the sender thread performs an exponential backoff with jitter and retries the delivery until `MaxRetries` is reached.

## Error points

- **No active transaction:** StartSpan, StartSpanDb, and StartSpanRequest require an open transaction and raise ETransactionNotFound when none exists.
- **Global state leakage:** singleton settings or queue state can leak between tests without teardown.
- **Transport delivery issues:** transient failures (429, 5xx) are handled via retries; persistent failures or terminal client errors (4xx) cause the batch to be dropped.
- **Windows-only interceptors:** interceptor behavior differs on non-Windows targets.
