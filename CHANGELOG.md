# Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/).
Versionamento segue [Semantic Versioning](https://semver.org/).

## [1.1.0] — 2026-04-22

### Added
- Resilient retry mechanism in `TSendThread` with exponential backoff and jitter (#17).
- Automatic registration for standard components via `TApm4DInterceptorBuilder` (#10).
- Detailed documentation for MadExcept and EurekaLog providers (#12).
- Non-regression test baseline for stacktrace parsing (#14).

### Changed
- Decoupled `TSpan` and `TError` core domain classes from `TApm4DSettings` singleton using `TStackTracerFactory` dependency injection (#16).
- Centralized stacktrace lifecycle management to prevent memory leaks and improve reliability (#15).
- Optimized regex performance by caching `TRegEx` instances in stacktrace providers (#13).

### Fixed
- Improved `TSendThread` termination logic to be interruptible during backoff (#17).
- Resolved naming convention violations (Rule 9/91) across multiple units (#16).

## [1.0.0] — 2026-04-21

### Added
- Support for MadExcept and EurekaLog stacktrace providers (#7).
- HTTP client abstraction (`IApm4DHttpClient`) to decouple transport logic (#6).
- New unit test suite for stacktrace providers and facade integration (#7, #6).
- DUnitX audit coverage and test roadmap (#2).

### Changed
- Refactored `TSendThread` to use the new HTTP client abstraction (#6).
- Improved stacktrace capture logic to resolve recursion and expand frame contract (#5).
- Updated project package (`Apm4D.dpk`) and project file (`Apm4D.dproj`) with new units.
- Aligned project history with remote master branch via merge.

### Fixed
- Guarded span start without an active transaction (#3).
- Resolved convention violations in various units (parameter and variable naming).
- Updated `.gitignore` rules to persist approved ignore patterns.


---

## [0.1.0] — 2026-04-08

### Added
- Versão inicial da documentação de testes e arquitetura.
