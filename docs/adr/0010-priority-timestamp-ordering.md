# ADR-0010: Ordenamiento de Kitchen Queue por priorityTimestamp automático

- Estado: Aceptado
- Fecha: 2026-06-20
- Autores: Equipo TacosManager
- Supersedes: ADR-0006

## Contexto

ADR-0006 decidió que, dentro de un mismo `OrderStatus`, la cola de cocina se ordena
por `createdAt ASC` (FIFO), y rechazó explícitamente un `priorityTimestamp` **editable
manualmente** por riesgo de reordenamiento no auditado.

Sin embargo, el resto del corpus evolucionó en otra dirección sin pasar por un ADR:

- `business-rules.md §17` define un campo `priorityTimestamp` con semántica de
  actualización **automática** (controlada por el sistema, no por el usuario).
- `glossary.md` declara `priorityTimestamp` como el campo de ordenamiento FIFO.
- El contrato (`openapi.yaml`, `asyncapi.yaml`) ya expone `priorityTimestamp` en `Order`.
- `create-order` REQ-0025 fija `priorityTimestamp = createdAt` al crear la orden.

Resultado: `createdAt` (ADR-0006 + REQ-0044) y `priorityTimestamp` (§17 + glossary +
contratos) compiten como clave de orden. La diferencia es observable: en un append a una
orden en `PREPARING`, `createdAt` nunca cambia pero `priorityTimestamp` se actualiza, lo
que reordena la cola. Back y front pueden divergir según qué campo usen.

Nota clave: la alternativa que ADR-0006 rechazó era `priorityTimestamp` **editable/manual**.
El mecanismo de §17 es **automático** y determinista — un caso que ADR-0006 no evaluó.

## Decisión

La clave canónica de ordenamiento FIFO dentro de un mismo `OrderStatus` es
**`priorityTimestamp ASC`** (automático). El backend devuelve la lista ya ordenada; el
frontend NO reordena (Artículo II).

El ordenamiento global por prioridad de status se mantiene tal como en ADR-0006:

```
PREPARING(1) > PENDING(2) > READY(3) > DELIVERED(4) > CANCELLED(5)
```

Semántica de `priorityTimestamp` (autoridad: `business-rules.md §17`):

- Al **crear** la orden: `priorityTimestamp ≈ createdAt`. (En la implementación,
  `priorityTimestamp` se asigna con `new Date()` y `createdAt` con `@default(now())` de
  Postgres — relojes independientes, mismo instante lógico. No afecta el FIFO.)
- Append en **PENDING**: `priorityTimestamp` NO se actualiza — la orden conserva su
  posición FIFO original (no salta por delante de otras PENDING anteriores).
- Append en **PREPARING**: `priorityTimestamp = now` — se reprioriza.
- El valor NUNCA lo fija el cliente; es siempre derivado por el backend.

Trazabilidad: REQ-0044 (FIFO por `createdAt`) queda `🗑️ Deprecado` con sucesor
**REQ-0047** (FIFO por `priorityTimestamp`). La spec `kitchen-queue` sube a `2.0` (MAJOR,
cambio breaking de comportamiento, ADR-0009).

## Alternativas consideradas

- **Mantener `createdAt` (ADR-0006)** — más simple y sin breaking, pero deja
  `priorityTimestamp` como campo vestigial y elimina la reprioritización de appends en
  PREPARING que el negocio (§17) sí quiere. Descartada por incoherencia con el resto del
  corpus ya construido alrededor de `priorityTimestamp`.
- **`priorityTimestamp` editable manual** — rechazada ya por ADR-0006; permite
  reordenamiento no auditado. Esta decisión NO la reintroduce: el campo es automático.

## Consecuencias

Positivas:
- Una sola clave de orden coherente entre contrato, spec, glosario y business-rules.
- La reprioritización de appends en PREPARING queda especificada y trazable (REQ-0047).
- El orden sigue siendo determinista y no manipulable por el cliente.

Negativas:
- `traceability.md` retiene REQ-0044 como histórico deprecado.

Verificación (2026-06-20):
- El backend YA implementa este comportamiento (`orders.service.ts` getOrders ordena por
  `priorityTimestamp ASC` dentro del status; updateOrder actualiza `priorityTimestamp`
  solo en append sobre PREPARING). REQ-0047 queda `🟡` (implementado; falta test
  automatizado dedicado que asevere la reprioritización PREPARING). No hay trabajo de
  backend pendiente para C1.

Neutrales:
- ADR-0006 pasa a `Reemplazado por ADR-0010`; su contenido permanece como registro.

## Referencias

- ADR-0006 — Ordenamiento de Kitchen Queue (reemplazado)
- ADR-0009 — Política de versionado de specs y REQ-IDs
- Constitución Artículo II — Backend como Fuente de Verdad
- Constitución Artículo VII — Decisiones Documentadas
- `business-rules.md` §14, §15, §17
- `specs/kitchen-queue/spec.md` — REQ-0047 (sucesor de REQ-0044)
- `glossary.md` — priorityTimestamp
