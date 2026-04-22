---
displayed_sidebar: elasticapm4dSidebar
title: Local Development Setup
---

To test ElasticAPM4D locally, you can run a complete Elastic Stack (Elasticsearch, Kibana, and APM Server) using Docker. This allows you to visualize traces and errors immediately without needing a cloud subscription.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running.
- [Docker Compose](https://docs.docker.com/compose/) (included with Docker Desktop).

## Running the Stack

The ElasticAPM4D repository includes a `docker-compose.yml` file configured with Elastic Stack version 7.11.1.

1. Open a terminal in the project root.
2. Run the following command:

```bash
docker-compose up -d
```

3. Wait for the services to start. You can check the status with:

```bash
docker-compose ps
```

## Accessing the Services

| Service | URL | Description |
|---------|-----|-------------|
| **Kibana** | [http://localhost:5601](http://localhost:5601) | Dashboard and Visualization |
| **APM Server** | [http://localhost:8200](http://localhost:8200) | Intake API for the Delphi Agent |
| **Elasticsearch** | [http://localhost:9200](http://localhost:9200) | Data storage |

## Configuring the Delphi Agent

Once the stack is running, configure your Delphi application to point to the local APM Server:

```delphi
begin
  TApm4DSettings.Elastic.ServerUrl := 'http://localhost:8200';
  // No secret token is required for the default local setup
  TApm4DSettings.Activate;
end;
```

## Viewing Data in Kibana

1. Open Kibana at [http://localhost:5601](http://localhost:5601).
2. Go to **Observability > APM**.
3. You should see your service listed (default name is your application executable name).
4. Click on the service to explore Transactions, Spans, and Errors.

## Stopping the Stack

To stop and remove the containers, run:

```bash
docker-compose down
```

To also remove the data volumes:

```bash
docker-compose down -v
```
