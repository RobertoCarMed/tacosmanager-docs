# CLAUDE.md — Guía para Agentes en este Repositorio

Este repositorio es la **fuente de verdad documental** del producto TacosManager. Sigue Spec-Driven Development (SDD).

## Antes de cualquier cambio funcional

1. Lee `constitution.md`. Sus artículos son no negociables.
2. Lee `glossary.md`. Usa el vocabulario canónico.
3. Identifica la spec en `specs/<feature>/` que cubre el cambio. Si no existe, créala primero.

## Flujo SDD obligatorio

```
1. /specify   → genera/actualiza specs/<feature>/spec.md
2. /plan      → deriva specs/<feature>/plan.md
3. /tasks     → produce specs/<feature>/tasks.md
4. /implement → ejecuta tasks contra el código
```

Los comandos viven en `.claude/commands/`. Cada uno tiene su propio prompt.

## Reglas duras

- NUNCA cambies un endpoint o evento sin actualizar `contracts/openapi.yaml` o `contracts/asyncapi.yaml`.
- NUNCA introduzcas un término nuevo sin agregarlo a `glossary.md`.
- NUNCA tomes una decisión arquitectónica sin crear un ADR en `docs/adr/`.
- NUNCA cierres un PR sin entrada en `traceability.md`.
- NUNCA modifiques retroactivamente items o plates de una orden existente (Artículo V).
- NUNCA expongas datos de una taquería distinta a la del usuario autenticado (Artículo I).

## Convenciones de archivos

| Tipo | Ubicación | Plantilla |
|---|---|---|
| Spec funcional | `specs/<feature>/spec.md` | `specs/_templates/spec.md` |
| Plan técnico | `specs/<feature>/plan.md` | `specs/_templates/plan.md` |
| Tasks | `specs/<feature>/tasks.md` | `specs/_templates/tasks.md` |
| Gherkin ejecutable | `specs/<feature>/acceptance.feature` | — |
| ADR | `docs/adr/NNNN-titulo.md` | `docs/adr/README.md` |
| Contrato REST | `contracts/openapi.yaml` | — |
| Contrato Socket.IO | `contracts/asyncapi.yaml` | — |

## Idioma

- Specs, ADRs, constitution, glossary, business docs: **español**.
- OpenAPI/AsyncAPI: campos `description` en español; nombres técnicos en inglés.
- Gherkin: español (`Dado / Cuando / Entonces`).
- Código y nombres de tests: inglés.

## Branching

`feature/*` → `dev` → `qa` → `main`. Ver `branch-strategy.md`. Trabajo agentic siempre en branch dedicado.

## Commits

Conventional Commits. Ver `cicd-strategy.md`. Cuerpo del commit DEBE referenciar `REQ-IDs` afectados.

## Cuando dudes

Pregunta antes de inventar. Es mejor un mensaje aclaratorio que una spec divergente.
