# Plan técnico: Kitchen Queue

- Spec: `specs/kitchen-queue/spec.md`

## Arquitectura

- `OrdersService.updateStatus(orderId, status)` con guard de rol COOK.
- Validación: status ∈ {PENDING, PREPARING, READY, DELIVERED, CANCELLED}. `UPDATED` rechazado con 400.
- Si nuevo status = READY: `UPDATE items SET isNew=false WHERE order.id=...` en la misma transacción.
- `GET /orders` ordena por `CASE status` (1..5) y luego `priorityTimestamp ASC` (ADR-0010, reemplaza el `createdAt ASC` de ADR-0006). En creación `priorityTimestamp = createdAt`; append en PENDING no lo altera, append en PREPARING lo actualiza (business-rules §17).
- Emit `order-status-changed` post-commit.

## Decisiones

- Sin máquina de estados estricta: permitimos cualquier transición salvo `UPDATED`. Auditoría queda en logs.
- Limpieza de `isNew` se hace en la misma transacción para garantizar consistencia con el evento emitido.

## Testing

- E2E: `backend/test/orders.e2e-spec.ts` (sección status).
- Gherkin: `specs/kitchen-queue/acceptance.feature`.

## Trazabilidad

REQ-0040 a REQ-0047 (REQ-0044 deprecado por REQ-0047, ver ADR-0010).
