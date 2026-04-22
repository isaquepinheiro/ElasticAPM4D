---
title: Common Errors
---

# Common Errors

## Data not appearing in Kibana

### Symptoms
- No transactions or spans visible in the APM UI.
- No errors reported.

### Root Causes
- **Agent not activated**: Ensure `TApm4DSettings.Activate` is called.
- **Incorrect URL**: Verify `TApm4DSettings.Elastic.Url`.
- **Firewall/Network**: Ensure the application can reach the APM Server on port 8200.
- **Invalid Secret Token**: Check `TApm4DSettings.Elastic.Secret`.

### Resolutions
1. Enable internal logging (`TApm4DSettings.Log.Enabled := True`) to see connection errors.
2. Verify connectivity with `curl -v http://your-apm-server:8200`.

## Connection refused (429 or 5xx)

### Symptoms
- Log messages indicating retries.
- High latency in sending telemetry.

### Root Causes
- **APM Server Overload**: The server is rate-limiting the agent (429).
- **Server Down**: The APM Server or Elasticsearch is experiencing issues (5xx).

### Resolutions
ElasticAPM4D will automatically retry with exponential backoff. If the problem persists, check the health of your Elastic APM Server and ensure it has enough resources.
