# Pull Request

## Spec asociada

<!--
  Obligatorio. Sin spec, sin PR.
  El gate de CI "SDD Traceability" valida que este cuerpo contenga
  uno de:
    - "Closes REQ-NNNN" listando los requirements cubiertos
    - "Spec: specs/<feature>/spec.md"
    - El label "docs-only" / "chore" / "release" / "sdd-bootstrap" si no aplica
  Los REQ-IDs deben existir en traceability.md o agregarse en este mismo PR.
-->

- Spec: `specs/<feature>/spec.md`
- Closes REQ-XXXX, REQ-YYYY
- ETAPA: `X.Y.Z` (referencia a `roadmap.md`)
- Versión de spec tras este PR: `X.Y` (bump si cambia comportamiento de REQ implementado — ver ADR-0009)

## Tipo de cambio

- [ ] feat — nueva funcionalidad
- [ ] fix — corrección de bug
- [ ] docs — solo documentación
- [ ] refactor — sin cambio funcional
- [ ] test — agregar/actualizar tests
- [ ] chore — tooling, CI, deps
- [ ] adr — decisión arquitectónica (incluye archivo `docs/adr/NNNN-*.md`)

## Resumen

<!-- 2-4 líneas. El "por qué", no el "qué". -->

## Cambios principales

- 

## Trazabilidad

- [ ] `traceability.md` actualizado con los REQ cubiertos (gate de CI lo valida)
- [ ] Tests referencian `REQ-XXXX` en su nombre/cuerpo (`@REQ-XXXX` o `describe('REQ-XXXX: …')`)
- [ ] `scripts/build-traceability.js check` pasa sin huérfanos
- [ ] Si tocó contratos: `contracts/openapi.yaml` o `contracts/asyncapi.yaml` actualizado
- [ ] Si introdujo término nuevo: `glossary.md` actualizado
- [ ] Si tomó decisión arquitectónica: ADR agregado
- [ ] Si cambió comportamiento de REQ implementado: REQ nuevo + spec bumpeada (ADR-0009)

## Verificación constitucional

- [ ] Artículo I — Multi-tenancy estricto respetado
- [ ] Artículo II — Backend como fuente de verdad respetado
- [ ] Artículo III — Ownership validado en endpoints/queries
- [ ] Artículo IV — Eventos Socket.IO emitidos cuando corresponde
- [ ] Artículo V — Append-only respetado en órdenes
- [ ] Artículo IX — Sin exposición de datos sensibles

## Notas para el revisor

<!-- Decisiones no obvias, trade-offs, riesgos conocidos. -->
