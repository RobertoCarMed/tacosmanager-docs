# ADR-0008: Spec-Driven Development como flujo de trabajo

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

A medida que el producto crece y el desarrollo se asiste con agentes IA, surgieron problemas:

1. Documentación post-hoc divergente del código.
2. Cambios sin trazabilidad: "¿quién pidió esto?", "¿qué test lo cubre?".
3. Agentes que reinterpretan reglas en cada sesión.

## Decisión

Adoptamos **Spec-Driven Development**:

1. Toda feature inicia con `specs/<feature>/spec.md` (user stories + Gherkin con `REQ-XXXX`).
2. Se deriva `plan.md` (técnico) y `tasks.md` (atómico) antes de implementar.
3. Tests automatizados se trazan a `REQ-XXXX` en `traceability.md`.
4. Contratos REST/Socket.IO viven en `contracts/openapi.yaml` y `contracts/asyncapi.yaml`.
5. Slash commands `/specify`, `/plan`, `/tasks`, `/implement` automatizan el flujo agentic.
6. PRs sin spec o sin entrada en `traceability.md` son rechazados.

## Alternativas consideradas

- **Solo BDD** — útil pero no cubre planning ni decisiones arquitectónicas.
- **TDD puro** — el test es código, no especificación legible por stakeholders.
- **Mantener doc post-hoc** — status quo, ya demostró divergencia.

## Consecuencias

Positivas:
- Cualquier cambio es auditable: spec → tests → código → PR → commit.
- Onboarding de agentes IA reproducible (CLAUDE.md + comandos).
- Reglas constitucionales explícitas y testables.

Negativas:
- Costo inicial: migrar features existentes a specs retroactivas.
- Disciplina: PRs que se saltan la spec son tentadores en hotfixes.

Neutrales:
- Las ETAPAS del roadmap conviven con las specs — la spec describe el QUÉ, la ETAPA agrupa entregables temporales.

## Referencias

- Constitución Artículo VI — Spec-Driven Development
- `CLAUDE.md`
- `specs/_templates/`
- `traceability.md`
