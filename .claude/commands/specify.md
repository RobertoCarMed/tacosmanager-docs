---
description: Genera o actualiza specs/<feature>/spec.md desde un brief
---

# /specify

Entrada del usuario: nombre/slug de la feature y un brief de 2-5 líneas.

Tu tarea:

1. Si no existe `specs/<feature>/`, créalo.
2. Copia la plantilla `specs/_templates/spec.md` a `specs/<feature>/spec.md`.
3. Llena la spec con:
   - Problema / oportunidad (extraído del brief).
   - Objetivos y no-objetivos (deduce; pregunta si dudoso).
   - Actores (COOK, WAITER, sistema — consulta `glossary.md`).
   - User stories realistas.
   - Acceptance criteria en Gherkin (`Dado / Cuando / Entonces`) con IDs `REQ-NNNN`.
4. Asigna `REQ-NNNN` libres consultando `traceability.md` (último usado + 1).
5. Identifica dependencias con otras specs y ADRs existentes.
6. NO escribas implementación. NO toques `plan.md` ni `tasks.md`.
7. Al terminar:
   - Imprime las nuevas filas para `traceability.md` (con `Estado: 🔴 Pendiente`).
   - Recuerda al usuario que el próximo paso es `/plan`.

Restricciones:

- Toda regla nueva debe ser consistente con `constitution.md`. Si entra en conflicto, detente y pregunta.
- Vocabulario solo del `glossary.md`. Términos nuevos requieren PR aparte.
- Idioma: español.
