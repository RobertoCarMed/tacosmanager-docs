---
description: Genera specs/<feature>/tasks.md atómico desde el plan
---

# /tasks

Entrada del usuario: slug de la feature (debe existir `specs/<feature>/plan.md`).

Tu tarea:

1. Lee `specs/<feature>/spec.md` y `specs/<feature>/plan.md`.
2. Copia `specs/_templates/tasks.md` a `specs/<feature>/tasks.md`.
3. Descompón el plan en tareas atómicas con IDs `TASK-NNNN`:
   - Cada task DEBE ser ejecutable en una sesión de desarrollo (≤ 1 día).
   - Cada task referencia los `REQ-NNNN` que ayuda a cumplir.
   - Cada task tiene: archivos afectados, estimación (S/M/L), criterio de "done".
4. Ordena las tasks por dependencias (las primeras desbloquean a las siguientes).
5. Si detectas un riesgo o decisión arquitectónica nueva, indícalo al final del archivo.
6. Al terminar, recuerda al usuario que el próximo paso es `/implement`.

Restricciones:

- IDs `TASK-NNNN` únicos (chequea otros tasks.md del repo).
- No incluir tasks de "documentación" como afterthought: la doc se actualiza durante implementación, no después.
