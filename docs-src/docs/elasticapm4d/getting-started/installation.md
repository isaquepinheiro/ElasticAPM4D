---
displayed_sidebar: elasticapm4dSidebar
title: Installation
---

## Prerequisites

- Delphi 10.3 or newer (validated on Delphi 12 Yukon).
- Access to an Elastic APM Server 7.11.1+ endpoint.
- Optional JEDI-JCL if detailed stacktrace capture is required.

## Installation

1. Clone the repository.
2. Open Apm4D.dpk in the Delphi IDE.
3. Build and install the package.
4. Add source to the host application search path and include Apm4D in uses.

## Verification

- Compile your host application successfully with Apm4D in uses.
- Confirm TApm4DSettings.Activate executes during startup without exceptions.
- Run tests from tests/ElasticAPM4D.Tests.dpr to validate instrumentation behavior.
