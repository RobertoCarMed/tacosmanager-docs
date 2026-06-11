---
description: Ejecuta tasks de specs/<feature>/tasks.md contra el código
---

# /implement

Entrada del usuario: slug de la feature y opcionalmente IDs de tasks específicos (`TASK-0030,TASK-0031`).

Tu tarea:

1. Lee `specs/<feature>/spec.md`, `plan.md`, `tasks.md`. Identifica las tasks objetivo (todas las pendientes o las solicitadas).
2. Antes de cambiar código:
   - Confirma branch dedicado (`feature/<feature>-<task>` o similar). Crea uno si estás en `main`/`dev`.
   - Verifica que el repo de código (backend/mobile) tiene el submódulo de docs actualizado.
3. Para cada task:
   - Implementa los cambios estrictamente necesarios.
   - Escribe/actualiza tests que referencien los `REQ-NNNN` cubiertos.
   - Actualiza `contracts/openapi.yaml` o `contracts/asyncapi.yaml` si cambia algún endpoint/evento.
   - Marca la task como `🟡 en progreso` mientras trabajas, `✅` al terminar.
4. Antes de commitear:
   - Actualiza `traceability.md` (estado, archivos clave).
   - Ejecuta lint + tests.
   - Mensaje de commit Conventional Commits + `Closes REQ-NNNN`.
5. NO toques specs ya `Aprobada`/`Implementada` salvo para marcar estado final.

Restricciones:

- Si una task requiere decisión arquitectónica no contemplada, DETENTE y propone un ADR antes de implementar.
- Si una task rompe un contrato, detente y abre discusión.
- Si un REQ no está claro, pregunta antes de inventar comportamiento.
