# Plan técnico: Create Order

- Spec: `specs/create-order/spec.md`
- Estado: Implementado (plan retroactivo)
- Fecha: 2026-06-11

## 1. Resumen

`POST /orders` en NestJS valida DTO con `class-validator` (incluyendo reglas condicionales por `OrderType`), persiste con Prisma en una transacción que crea `Order` + `Plate`s + `Item`s, y emite `order-created` al room `taqueria:<taqueriaId>` vía gateway de Socket.IO.

## 2. Arquitectura

- **Backend:**
  - Módulo `OrdersModule` (`backend/src/orders/`).
  - Controller `OrdersController` con `JwtAuthGuard` + `RolesGuard(WAITER)`.
  - Service `OrdersService.create()` — transacción Prisma.
  - Gateway `RealtimeGateway.emitOrderCreated(taqueriaId, order)`.
- **Frontend:**
  - Screen `CreateOrderScreen` (`mobile/src/features/orders/screens/`).
  - Slice Redux `ordersSlice` con thunk `createOrder`.
  - Listener Socket.IO `order-created` en `kitchenSlice` para refrescar cola.
- **DB (Prisma):**
  - `Order(id, taqueriaId, waiterId, type, reference, deliveryAddress, status, revision, priorityTimestamp, createdAt, updatedAt)`
  - `Plate(id, orderId, plateNumber, isClosed, createdInRevision, createdAt)`
  - `Item(id, plateId, productId, quantity, selectedComplements jsonb, notes, isNew, createdInRevision, createdAt)`
  - Índice `(taqueriaId, status, priorityTimestamp)` para Kitchen Queue.

## 3. Modelo de datos

Ver `architecture.md` y `backend-api.md`. Sin cambios para este spec más allá de los campos `type/reference/deliveryAddress` introducidos en ETAPA 4.6.1.

## 4. Contratos

- REST: `POST /orders` — ver `contracts/openapi.yaml#/paths/~1orders/post`.
- Socket.IO: `order-created` — ver `contracts/asyncapi.yaml#/channels/taqueria.{taqueriaId}/subscribe/message/OrderCreated`.
- DTO `CreateOrderDto`:
  - `type: OrderType` (enum)
  - `reference?: string` — `@ValidateIf(o => o.type !== 'DELIVERY')` → requerido
  - `deliveryAddress?: string` — `@ValidateIf(o => o.type === 'DELIVERY')` → requerido
  - `plates: CreatePlateDto[]` — `@ArrayMinSize(1)`
  - `CreatePlateDto.items: CreateItemDto[]` — `@ArrayMinSize(1)`

## 5. Decisiones técnicas

- Transacción Prisma: la creación es atómica (order + plates + items). No quedan plates sin order si algo falla. Sin ADR (estándar).
- Validación condicional con `@ValidateIf` en lugar de DTOs polimórficos. Sin ADR (estándar NestJS).
- Emisión post-commit: el `emit` se hace después del `await tx.commit()` implícito de Prisma para no emitir órdenes que no quedaron persistidas.

## 6. Migración / Compatibilidad

- ETAPA 4.6.1 introdujo `type`, `reference`, `deliveryAddress`. Migración Prisma creó las columnas con default seguro (`type=DINE_IN`).
- No hay breaking change posterior.

## 7. Testing

- Unit: `OrdersService.create()` con Prisma mock.
- E2E: `backend/test/orders.e2e-spec.ts` — cubre REQ-0020 a REQ-0027.
- Gherkin: `specs/create-order/acceptance.feature`.
- Cobertura mínima esperada: ≥85% del service.

## 8. Observabilidad

- Log estructurado al crear orden: `{ orderId, taqueriaId, waiterId, type, plates, items }`.
- Métrica: contador `orders_created_total{taqueria,type}`.
- Health check no afectado.

## 9. Rollout

- Sin feature flag (feature core).
- Deploy estándar pipeline backend (`cicd-backend.md`).
- Rollback: revertir migración de Prisma solo si rompió `type/reference/deliveryAddress`. Hoy estable.

## 10. Trazabilidad

| REQ | Test | Archivos |
|---|---|---|
| REQ-0020 | orders.e2e-spec.ts::create_dine_in | backend/src/orders/orders.service.ts, dto/create-order.dto.ts |
| REQ-0021 | orders.e2e-spec.ts::create_takeaway | idem |
| REQ-0022 | orders.e2e-spec.ts::create_delivery | idem |
| REQ-0023 | orders.e2e-spec.ts::dine_in_no_ref_fails | backend/src/orders/dto/create-order.dto.ts |
| REQ-0024 | orders.e2e-spec.ts::delivery_no_address_fails | idem |
| REQ-0025 | orders.e2e-spec.ts::initial_revision | backend/src/orders/orders.service.ts |
| REQ-0026 | orders.e2e-spec.ts::emit_order_created | backend/src/realtime/realtime.gateway.ts |
| REQ-0027 | orders.e2e-spec.ts::cook_cannot_create | backend/src/orders/orders.controller.ts |
