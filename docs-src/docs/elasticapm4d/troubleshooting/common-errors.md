---
displayed_sidebar: elasticapm4dSidebar
title: Common Errors
---

## Span started without active transaction

- **Symptom:** ETransactionNotFound is raised when StartSpan, StartSpanDb, or StartSpanRequest is called without an active transaction.
- **Likely cause:** span APIs enforce the parent transaction precondition.
- **Action:** always call StartTransaction before starting spans and close spans in LIFO order.

## Events from previous tests affect current test

- **Symptom:** flaky assertions in queue or context tests.
- **Likely cause:** singleton and queue global state not reset between tests.
- **Action:** call TApm4DSettings.ReleaseInstance in teardown and flush any accessible queue state.

## No events visible in Elastic APM

- **Symptom:** transactions are created in code but not visible server-side.
- **Likely cause:** invalid Elastic URL, authentication token, or transport/network failure.
- **Action:** validate TApm4DSettings.Elastic configuration and endpoint reachability.

## Interceptors do not trigger on Linux

- **Symptom:** OnClick/DataSet/RESTRequest auto-instrumentation is absent on Linux builds.
- **Likely cause:** VCL interceptors are guarded for Windows platforms only.
- **Action:** use explicit TApm4D instrumentation on non-Windows targets.
