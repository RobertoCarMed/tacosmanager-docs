# Pull Request

## Spec asociada

<!-- Obligatorio. Sin spec, sin PR. -->

- Spec: `specs/<feature>/spec.md`
- REQ cubiertos: `REQ-XXXX`, `REQ-YYYY`
- ETAPA: `X.Y.Z` (referencia a `roadmap.md`)

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

- [ ] `traceability.md` actualizado con los REQ cubiertos
- [ ] Tests referencian `REQ-XXXX` en su nombre/cuerpo
- [ ] Si tocó contratos: `contracts/openapi.yaml` o `contracts/asyncapi.yaml` actualizado
- [ ] Si introdujo término nuevo: `glossary.md` actualizado
- [ ] Si tomó decisión arquitectónica: ADR agregado

## Verificación constitucional

- [ ] Artículo I — Multi-tenancy estricto respetado
- [ ] Artículo II — Backend como fuente de verdad respetado
- [ ] Artículo III — Ownership validado en endpoints/queries
- [ ] Artículo IV — Eventos Socket.IO emitidos cuando corresponde
- [ ] Artículo V — Append-only respetado en órdenes
- [ ] Artículo IX — Sin exposición de datos sensibles

## Notas para el revisor

<!-- Decisiones no obvias, trade-offs, riesgos conocidos. -->
