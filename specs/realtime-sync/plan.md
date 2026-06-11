# Plan técnico: Realtime Sync

- Spec: `specs/realtime-sync/spec.md`

## Arquitectura

- `RealtimeGateway` (NestJS) con middleware JWT en `handleConnection`.
- Auto-join a room `taqueria:<taqueriaId>` derivado del token.
- Métodos del gateway expuestos al `OrdersService` para emit:
  - `emitOrderCreated(taqueriaId, order)`
  - `emitOrderUpdated(taqueriaId, order)`
  - `emitOrderStatusChanged(taqueriaId, order)`
- Cliente mobile: hook `useSocket()` que centraliza conexión, reconexión y resync.
- Resync: al `connect`, dispatch a `kitchenSlice.fetchOrders()`.

## Decisiones

- Sin adapter Redis por ahora (single instance backend).
- Multi-device: el modelo de rooms ya cubre el caso (cada socket se une al room por su user).

## Testing

- E2E: `backend/test/realtime.e2e-spec.ts`.
- Manual multi-device: doc en `feature-list.md` ETAPA 4.7.3.
- Gherkin: `specs/realtime-sync/acceptance.feature`.

## Trazabilidad

REQ-0050 a REQ-0054.
