# TacosManager Documentation

Repositorio centralizado de documentación compartida para:

- TacosManager API
- TacosManager App

Esta documentación sigue **Spec-Driven Development (SDD)**. Toda funcionalidad inicia con una spec versionada antes que con código.

## Mapa documental

```
constitution.md         ← principios no negociables
glossary.md             ← Ubiquitous Language
traceability.md         ← matriz REQ ↔ TEST ↔ código
CLAUDE.md               ← guía para agentes IA
docs/adr/               ← decisiones arquitectónicas
specs/                  ← especificaciones funcionales por feature
contracts/              ← OpenAPI + AsyncAPI
```

## Documentos por categoría

### Fundamentos SDD
- `constitution.md` — principios constitucionales
- `glossary.md` — vocabulario canónico
- `traceability.md` — REQ-IDs ↔ tests ↔ archivos
- `CLAUDE.md` — guía para agentes IA

### Decisiones arquitectónicas
- `docs/adr/` — ADRs (Architecture Decision Records)

### Specs por feature
- `specs/authentication/`
- `specs/products-management/`
- `specs/create-order/`
- `specs/edit-order/`
- `specs/kitchen-queue/`
- `specs/realtime-sync/`
- `specs/_templates/` — plantillas spec/plan/tasks

### Contratos ejecutables
- `contracts/openapi.yaml` — REST (OpenAPI 3.1)
- `contracts/asyncapi.yaml` — Socket.IO (AsyncAPI 2.6)

### Referencia técnica
- `architecture.md`
- `backend-api.md`
- `backend-realtime.md`
- `api-reference.md`
- `frontend-architecture.md`
- `ui-flows.md`

### Negocio
- `business-model.md`
- `business-rules.md`
- `feature-list.md`
- `roadmap.md`

### Proceso
- `branch-strategy.md`
- `cicd-strategy.md`, `cicd-backend.md`, `cicd-mobile.md`, `cicd-governance.md`
- `contributing.md`
- `deployment-runbook.md`

## Flujo SDD

```
/specify  → specs/<feature>/spec.md   (qué)
/plan     → specs/<feature>/plan.md   (cómo técnico)
/tasks    → specs/<feature>/tasks.md  (descomposición ejecutable)
/implement → código + tests + actualización de traceability.md
```

Slash commands disponibles en `.claude/commands/`.

## Fuente de verdad

Toda modificación funcional debe reflejarse aquí ANTES de tocar código.

Backend y Frontend consumen esta documentación mediante Git Submodules. Ver `docs/adr/0007-git-submodules-docs.md`.
