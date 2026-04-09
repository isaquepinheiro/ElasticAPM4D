# Roadmap — ElasticAPM4D

> Agente de Application Performance Monitoring nativo para Delphi integrado ao Elastic APM.

**Última atualização:** 2026-04-08

---

## Fases

### Fase 1 — Configuração e Contextos (Sem Mock)

**Objetivo:** Cobertura inicial funcional para configurações e ativação do APM.
**Previsão:** Q2 2026

- [ ] Testes de Settings (TApm4DSettings)
- [ ] Testes de Ativação (Activate)
- [ ] Testes de Contextos (User, Database)

---

### Fase 2 — Core do APM (Sem Mock)

**Objetivo:** Testar a hierarquia e captura de métricas básicas.
**Previsão:** Q2 2026

- [ ] Criação e ciclo de vida de Transactions
- [ ] Criação e encadeamento de Spans
- [ ] Captura e associação de Errors / Exceptions

---

### Fase 3 — Serialização e Buffer

**Objetivo:** Garantir a conformidade do output NDJSON e funcionamento da fila em memória.
**Previsão:** Q2 2026

- [ ] Serialização correta do JSON (Estrutura, campos obrigatórios)
- [ ] Fila Interna (respeito a limites, inserção e consumo)

---

### Fase 4 — Avançado (Mocks)

**Objetivo:** Testar integrações diretas e HTTP com abstrações.
**Previsão:** Q3 2026

- [ ] Abstração de cliente HTTP (IHttpClient)
- [ ] Testes de chamadas HTTP com mock

---

## Backlog

Itens identificados mas não priorizados:

- Interceptors automáticos (UI, DataSet, DBConnection)
- Testes avançados de métricas do sistema (Metricsets customizados)

---

## Registro de sprints

Cada sprint documentado pelo `/sprint` é registrado aqui.
O `/sprint` tica o item correspondente ao fechar a rodada.

- [ ] Sprint 1 — Fase 1 (Configurações e Contextos) — 2026-04-08
