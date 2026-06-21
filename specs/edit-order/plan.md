# Plan técnico: Edit Order (Append)

- Spec: `specs/edit-order/spec.md` (v3.0)
- Estado: Implementado

## Arquitectura

`PATCH /orders/:id` (`OrdersService.updateOrder`) combina dos operaciones en una
transacción Prisma, al menos una presente:

- **Append de plates nuevos** (REQ-0048): inserción de plates con `plateNumber`
  NUEVO; un `plateNumber` ya existente → 400 (inmutabilidad a nivel plate). Items
  nuevos con `createdInRevision = order.revision + 1` e `isNew=true`.
- **Corrección de clasificación** (REQ-0062, ADR-0011): escribe
  `type`/`reference`/`deliveryAddress` validando el estado efectivo con
  `validateClassification`. No crea items ni marca `isNew`.

Común a ambas:
- Lookup de orden con `taqueriaId` del JWT (ownership).
- Cálculo de nuevo status según CASO 1/2/3 (`computeStatusAfterAppend()`).
- `UPDATE order SET revision = revision + 1, status = <nuevoStatus>`.
- Emit `order-updated` post-commit.

## Decisiones

- "No-op" PATCH (sin cambios útiles) responde 400, no 200, para detectar bugs de cliente.
- Reglas de transición codificadas en `OrdersService.computeStatusAfterAppend()`.
- La clasificación es metadata corregible fuera del alcance del Artículo V (ADR-0011);
  los plates/items históricos siguen inmutables.

## Testing

- E2E: `backend/test/orders.e2e-spec.ts` (sección append).
- Gherkin: `specs/edit-order/acceptance.feature`.

## Trazabilidad

REQ-0031 a REQ-0036, REQ-0048, REQ-0062.
Deprecados: REQ-0030 (sucesor REQ-0048), REQ-0049 (sucesor REQ-0062).
