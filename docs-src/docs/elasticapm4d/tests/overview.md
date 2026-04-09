---
displayed_sidebar: elasticapm4dSidebar
title: Tests
---

## Strategy

- Unit and behavior-focused DUnitX fixtures per module.
- Regression checks for transaction, span, error, serialization, and queue behavior.
- Concurrency and edge-case slices to expose lifecycle and thread safety risks.
- Facade integration scenarios validating full transaction + span + error flows.
- Contract tests for deterministic exceptions on invalid span-start usage.

## How to run

1. Open tests/ElasticAPM4D.Tests.dpr in Delphi and compile.
2. Execute the generated binary or run from the IDE.
3. Optional scripted run: .claude/scripts/Compile.ps1 -Target tests (or -Target all -Clean).
4. Latest QA evidence for the span-guard contract: 44 tests passed, 0 failed.

## Expected coverage

- Settings and activation flows.
- User and database context handling.
- Transaction and span lifecycle.
- Error capture and stacktrace association.
- NDJSON output requirements.
- Internal queue behavior and limits.
- Multi-thread and edge-case scenarios.
- Facade integration checks for outcome/result propagation and trace/span linkage.
