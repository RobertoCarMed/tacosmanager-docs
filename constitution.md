# Constitución TacosManager

Versión: 1.1
Estado: Vigente
Última actualización: 2026-06-21

Este documento es la **Constitución del proyecto**. Define principios inmutables que toda spec, ADR, plan o commit DEBE respetar. Cualquier desviación requiere modificar primero esta constitución mediante un ADR explícito.

Jerarquía de autoridad documental:

```
constitution.md         ← principios (este documento)
  ↓
docs/adr/*.md           ← decisiones arquitectónicas trazables
  ↓
specs/<feature>/spec.md ← especificación funcional
  ↓
specs/<feature>/plan.md ← plan técnico derivado de la spec
  ↓
specs/<feature>/tasks.md ← tareas atómicas
  ↓
código + tests
```

---

## Artículo I — Multi-Tenancy Estricto

1. Toda entidad persistida DEBE pertenecer a exactamente una `Taquería` identificada por `taqueriaId`.
2. Ningún endpoint, query, evento o respuesta puede exponer datos de una taquería distinta a la del usuario autenticado.
3. El aislamiento se valida tanto en capa de aplicación (guards, ownership) como en capa de datos (filtros obligatorios por `taqueriaId`).
4. Tests automatizados DEBEN cubrir el caso "usuario de taquería A intenta acceder a recurso de taquería B → 403/404".

## Artículo II — Backend como Fuente de Verdad

1. El backend NestJS es la única fuente autoritativa del estado del sistema.
2. El frontend NUNCA calcula estado derivado que pueda divergir del backend (precios, totales, transiciones de estado, ordenamiento de cocina).
3. Toda regla de negocio DEBE residir en el backend. El frontend solo presenta y delega.
4. Los contratos REST y Socket.IO publicados en `contracts/` son vinculantes para todos los clientes.

## Artículo III — Ownership-Based Security

1. Todo acceso a recurso individual DEBE validar:
   - `recurso.taqueriaId === request.user.taqueriaId`
   - cuando aplique: `recurso.waiterId === request.user.id` (rol WAITER)
2. La autorización se enforza por guards declarativos, no por chequeos ad-hoc dispersos.
3. Roles soportados: `COOK`, `WAITER`. Cualquier nuevo rol requiere ADR.

## Artículo IV — Realtime Coherente

1. Toda mutación de orden DEBE emitir el evento Socket.IO correspondiente al room `taqueria:<taqueriaId>`.
2. Eventos definidos: `order-created`, `order-updated`, `order-status-changed`.
3. Los payloads de eventos siguen el contrato declarado en `contracts/asyncapi.yaml`. Romper el contrato requiere versionado + ADR.
4. El cliente DEBE poder reconectar y resincronizar sin perder consistencia.

## Artículo V — Append-Only en Órdenes

1. El **trabajo de cocina** de una orden es inmutable: los plates e items históricos (productos, cantidades, complementos, notas) NUNCA se modifican retroactivamente. Solo se permite agregar plates/items nuevos.
2. La **clasificación** de la orden (`type`, `reference`, `deliveryAddress`) es metadata corregible y queda fuera del alcance restrictivo de este artículo: `PATCH /orders/:id` PUEDE actualizarla, validando el estado efectivo resultante (ver ADR-0011).
3. La `revision` de la orden se incrementa monotónicamente con cada `PATCH /orders/:id`.
4. Los items nuevos se marcan `isNew: true` y se limpian automáticamente al transicionar a `READY`. Editar clasificación no crea items ni marca `isNew`.
5. Modificar items/plates históricos es bug. Tests de regresión DEBEN cubrirlo.

## Artículo VI — Spec-Driven Development

1. Toda feature nueva o cambio funcional inicia con una spec en `specs/<feature>/spec.md`.
2. La spec contiene: user stories, acceptance criteria en Gherkin, edge cases, requerimientos no funcionales.
3. Cada criterio Gherkin tiene un ID `REQ-XXXX` único, persistente, jamás reutilizado. Una vez `✅ Implementado` es **inmutable** (ver ADR-0009).
4. Las specs siguen SemVer `MAJOR.MINOR` declarado en su header. Cambios breaking bumpean MAJOR (ADR-0009).
5. Los tests automatizados se trazan a `REQ-XXXX` y aparecen en `traceability.md`.
6. PRs sin spec asociada (`Closes REQ-XXXX` o `Spec: specs/<feature>/`) son rechazados.

## Artículo VII — Decisiones Documentadas

1. Toda decisión arquitectónica con impacto cross-cutting DEBE quedar en un ADR (`docs/adr/NNNN-*.md`).
2. Los ADRs son inmutables una vez aceptados. Cambios producen un ADR nuevo con estado `Supersedes: ADR-XXXX`.
3. ADRs siguen formato MADR (Markdown Architecture Decision Record).

## Artículo VIII — Convenciones Operativas

1. Branching: `feature/*` → `dev` → `qa` → `main`. Ver `branch-strategy.md`.
2. Commits: Conventional Commits. Ver `cicd-strategy.md`.
3. CI/CD: todo PR DEBE pasar status checks declarados en `cicd-governance.md`.
4. Documentación: distribuida vía Git Submodules. Ningún backend/frontend duplica esta información.

## Artículo IX — No Exposición de Datos Sensibles

1. Respuestas API NUNCA incluyen: passwords, hashes, tokens internos, datos de otras taquerías.
2. Logs NUNCA contienen credenciales en texto plano.
3. Tests de seguridad DEBEN verificar redacción de payloads.

## Artículo X — Ubiquitous Language

1. Términos del dominio se usan consistentemente en código, doc, UI, commits y conversación.
2. El vocabulario canónico vive en `glossary.md`.
3. Renombrar un término del dominio requiere ADR y migración coordinada.

---

## Enmienda

Modificar esta constitución requiere:

1. PR con cambio explícito a este archivo.
2. ADR nuevo que justifique la enmienda y referencie el artículo afectado.
3. Aprobación de al menos un mantenedor del repo de docs.

---

## Referencias

- `glossary.md` — vocabulario canónico
- `docs/adr/` — decisiones arquitectónicas
- `specs/` — especificaciones funcionales
- `contracts/` — contratos OpenAPI y AsyncAPI
- `traceability.md` — matriz REQ ↔ TEST ↔ código
