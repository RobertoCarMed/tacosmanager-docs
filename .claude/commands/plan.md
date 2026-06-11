---
description: Deriva specs/<feature>/plan.md a partir del spec.md aprobado
---

# /plan

Entrada del usuario: slug de la feature (debe existir `specs/<feature>/spec.md`).

Tu tarea:

1. Lee `specs/<feature>/spec.md`. Si está en estado `Borrador`, advierte al usuario antes de continuar.
2. Lee `constitution.md`, ADRs relevantes (`docs/adr/`) y `architecture.md`.
3. Copia `specs/_templates/plan.md` a `specs/<feature>/plan.md`.
4. Llena:
   - Resumen técnico (2-3 líneas).
   - Arquitectura: módulos NestJS, screens/slices mobile, tablas DB, eventos.
   - Modelo de datos: schema Prisma propuesto.
   - Contratos: rutas en `contracts/openapi.yaml` o eventos en `contracts/asyncapi.yaml`. Marca si requieren actualización.
   - Decisiones técnicas: si alguna es cross-cutting, indica que requiere ADR.
   - Migración/compatibilidad.
   - Testing.
   - Rollout.
   - Trazabilidad: tabla `REQ → Test → Archivos`.
5. NO toques `tasks.md`.
6. Al terminar:
   - Lista los REQ que ya quedaron resueltos en el plan.
   - Lista decisiones que requieran ADR nuevo.
   - Recuerda al usuario que el próximo paso es `/tasks`.

Restricciones:

- Respetar Artículos II (backend source of truth), III (ownership), IV (realtime), V (append-only) cuando aplique.
- No introducir librerías nuevas sin ADR.
