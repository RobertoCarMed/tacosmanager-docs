# Specs

Cada feature vive en un directorio `specs/<feature>/` con tres archivos canónicos:

| Archivo | Contenido |
|---|---|
| `spec.md` | Especificación funcional: user stories, acceptance criteria, edge cases, REQ-IDs |
| `plan.md` | Plan técnico derivado: arquitectura, módulos afectados, decisiones |
| `tasks.md` | Tareas atómicas ejecutables con IDs `TASK-XXXX` |
| `acceptance.feature` | Gherkin ejecutable (Cucumber/Playwright) — derivado de spec.md |

## Flujo

```
/specify  → produce spec.md  (con stakeholder o cliente)
/plan     → produce plan.md  (técnico, derivado de spec)
/tasks    → produce tasks.md (descomposición ejecutable)
/implement → ejecuta tasks contra el código
```

Plantillas en `specs/_templates/`.

## Features actuales

| Feature | Estado | ETAPAS asociadas |
|---|---|---|
| `authentication` | ✅ implementada | 4.5.1 |
| `products-management` | ✅ implementada | 4.5.2 |
| `create-order` | ✅ implementada (piloto SDD) | 4.5.3, 4.6.1 |
| `edit-order` | ✅ implementada | 4.5.3, 4.5.6.2, 4.6.2 |
| `kitchen-queue` | ✅ implementada | 4.5.6.1, 4.6.3 |
| `realtime-sync` | ✅ implementada | 4.5.4, 4.7.1, 4.7.2, 4.7.3 |
| `order-filters` | ✅ implementada | 4.8 |
| `ticket-printing` | 🔴 planificada (Borrador) | 4.11 |

## Reglas

1. NUNCA un PR sin spec asociada.
2. Cada acceptance criterion lleva `REQ-NNNN` único persistente.
3. Cambios a un spec mergeado generan diff explícito en el PR (no edición silenciosa).
4. Tests automatizados referencian `REQ-NNNN` en su nombre o cuerpo.
