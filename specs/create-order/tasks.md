# Tasks: Create Order

- Spec: `specs/create-order/spec.md`
- Plan: `specs/create-order/plan.md`

> Tasks retroactivas: la feature ya está implementada. Se documentan para mantener el modelo SDD coherente y como referencia de re-implementación.

## TASK-0001 — Definir DTO `CreateOrderDto` con validación condicional

- Cubre: REQ-0020, REQ-0021, REQ-0022, REQ-0023, REQ-0024
- Archivos: `backend/src/orders/dto/create-order.dto.ts`
- Estimación: S
- Estado: ✅

Pasos:
1. Enum `OrderType` (DINE_IN, TAKEAWAY, DELIVERY).
2. Campos `type` (required), `reference` (condicional), `deliveryAddress` (condicional).
3. `@ValidateIf` para reglas por tipo.
4. `plates` con `@ArrayMinSize(1)` y `@Type` nested.

## TASK-0002 — Implementar `OrdersService.create()` con transacción

- Cubre: REQ-0020, REQ-0021, REQ-0022, REQ-0025
- Archivos: `backend/src/orders/orders.service.ts`
- Estimación: M
- Estado: ✅

Pasos:
1. `prisma.$transaction(async tx => { … })`.
2. Crear Order con `taqueriaId` del JWT, `status=PENDING`, `revision=1`, `priorityTimestamp=now()`.
3. Crear plates con `plateNumber` autoincremental por orden.
4. Crear items con `isNew=false` (inicial) y `createdInRevision=1`.
5. Retornar la orden con includes completos.

## TASK-0003 — Controller con guards de rol

- Cubre: REQ-0027
- Archivos: `backend/src/orders/orders.controller.ts`
- Estimación: S
- Estado: ✅

Pasos:
1. `@UseGuards(JwtAuthGuard, RolesGuard)` + `@Roles('WAITER')`.
2. Endpoint `POST /orders` recibe `CreateOrderDto`.
3. Llama service, retorna orden.

## TASK-0004 — Emitir `order-created` desde gateway

- Cubre: REQ-0026
- Archivos: `backend/src/realtime/realtime.gateway.ts`, `backend/src/orders/orders.service.ts`
- Estimación: S
- Estado: ✅

Pasos:
1. Tras commit de la transacción, llamar `gateway.emitOrderCreated(taqueriaId, order)`.
2. En el gateway: `server.to(\`taqueria:${taqueriaId}\`).emit('order-created', { order })`.
3. Test e2e que conecta un socket COOK y verifica recepción.

## TASK-0005 — Aislamiento multi-tenant

- Cubre: REQ-0026 (parte de aislamiento)
- Archivos: `backend/test/orders.e2e-spec.ts`
- Estimación: S
- Estado: ✅

Pasos:
1. Test: COOK de taquería B conectado a su room.
2. WAITER de taquería A crea orden.
3. Asegurar que el socket B NO recibió evento.

## TASK-0006 — Tests e2e completos

- Cubre: REQ-0020 a REQ-0027
- Archivos: `backend/test/orders.e2e-spec.ts`
- Estimación: M
- Estado: ✅

## TASK-0007 — Actualizar `traceability.md` y `contracts/openapi.yaml`

- Cubre: meta
- Archivos: `traceability.md`, `contracts/openapi.yaml`
- Estimación: S
- Estado: ✅
