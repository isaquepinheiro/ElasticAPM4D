# Roadmap — ElasticAPM4D

> Agente de Application Performance Monitoring nativo para Delphi integrado ao Elastic APM.

**Última atualização:** 2026-04-21 17:30

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

- [x] Abstração de cliente HTTP (IHttpClient) — delivered v0.1.2 2026-04-21
- [x] Testes de chamadas HTTP com mock — delivered v0.1.2 2026-04-21
- [x] Suporte para MadExcept e EurekaLog — delivered 2026-04-21

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

---

## Backlog sincronizado

Backlog operacional sincronizado com este roadmap:

- `.archive/2026-04-09_backlog-sincronizado-roadmap.md`

Prioridade imediata para continuidade da trilha atual de testes:

1. Fase 4 (Avancado com Mocks): abstracao HTTP e testes 2xx/4xx/5xx/timeout/conexao.
2. Nao-regressao: blindagem da captura de excecoes Delphi com stacktrace.
3. Atualizar os checkboxes das fases apos fechamento da rodada de testes.
