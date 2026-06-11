# Plan técnico: Edit Order (Append)

- Spec: `specs/edit-order/spec.md`

## Arquitectura

- `OrdersService.appendToOrder(orderId, dto)` en transacción Prisma.
- Lookup de orden con `taqueriaId` del JWT (ownership).
- Cálculo de nuevo status según CASO 1/2/3.
- Inserción de plates/items con `createdInRevision = order.revision + 1` y `isNew=true`.
- `UPDATE order SET revision = revision + 1, status = <nuevoStatus>`.
- Emit `order-updated` post-commit.

## Decisiones

- "No-op" PATCH (sin cambios) responde 400, no 200, para detectar bugs de cliente.
- Reglas de transición codificadas en `OrdersService.computeStatusAfterAppend()`.

## Testing

- E2E: `backend/test/orders.e2e-spec.ts` (sección append).
- Gherkin: `specs/edit-order/acceptance.feature`.

## Trazabilidad

REQ-0030 a REQ-0036.
