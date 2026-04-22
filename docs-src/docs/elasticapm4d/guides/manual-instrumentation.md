---
title: Manual Instrumentation
---

# Manual Instrumentation

Manual instrumentation allows you to fine-tune exactly what telemetry is captured in your application.

## Transactions

A transaction represents a top-level work item.

```delphi
TApm4D.StartTransaction('TransactionName', 'TransactionType');
try
  // Work
finally
  TApm4D.EndTransaction;
end;
```

### Setting Outcome

You can explicitly set the outcome of a transaction:

```delphi
TApm4D.EndTransaction('failure'); // default is 'success'
```

## Spans

Spans represent sub-operations within a transaction.

```delphi
TApm4D.StartSpan('QueryUsers', 'db.mysql.query');
try
  // DB Query
finally
  TApm4D.EndSpan;
end;
```

## User Attribution

Identify which user triggered a transaction.

```delphi
TApm4DSettings.User.Id := '12345';
TApm4DSettings.User.Email := 'user@example.com';
TApm4DSettings.User.UserName := 'jdoe';
```
