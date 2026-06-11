# Spec: Create Order

- ID: SPEC-create-order
- Estado: Implementada (spec piloto SDD retroactiva)
- Autores: Equipo TacosManager
- Fecha: 2026-06-11
- ETAPA asociada: 4.5.3 (CRUD inicial) → 4.6.1 (OrderType)

## 1. Problema / Oportunidad

Un mesero (WAITER) necesita capturar un pedido nuevo en menos de 30 segundos desde que el cliente pide, sin posibilidad de error en aislamiento entre taquerías. La cocina debe ver el pedido en tiempo real sin polling.

## 2. Objetivos

- Permitir crear órdenes con uno o varios `Plates`, cada uno con uno o varios `Items`.
- Soportar tres modalidades de consumo (`DINE_IN`, `TAKEAWAY`, `DELIVERY`) con validaciones específicas.
- Emitir evento `order-created` en realtime para que cocina lo vea sin refresh.
- Garantizar que un WAITER de taquería A NUNCA cree órdenes en taquería B.

## 3. No-objetivos

- Pago / facturación (fuera de scope).
- Edición de la orden (cubierto por `specs/edit-order/spec.md`).
- Cambio de estado por cocina (cubierto por `specs/kitchen-queue/spec.md`).
- Notificaciones push al cliente final.

## 4. Actores

- **WAITER** — único actor que puede crear órdenes.
- **COOK** — receptor pasivo vía Socket.IO; NO puede crear.
- **Sistema (backend)** — valida, persiste, emite evento.

## 5. User Stories

- US-1: Como WAITER quiero crear una orden DINE_IN con referencia a mesa para enviar el pedido a cocina al instante.
- US-2: Como WAITER quiero crear una orden TAKEAWAY con el nombre del cliente para identificar el pedido al entregarlo.
- US-3: Como WAITER quiero crear una orden DELIVERY con dirección para que el repartidor sepa a dónde llevarla.
- US-4: Como WAITER quiero agregar múltiples plates con múltiples items y complementos en una sola orden para representar pedidos complejos.
- US-5: Como COOK quiero ver el pedido apenas el WAITER lo crea para empezar a prepararlo sin demora.

## 6. Acceptance Criteria (Gherkin)

### REQ-0020 — Crear orden DINE_IN con reference obligatoria

```gherkin
Dado un WAITER autenticado de la taquería "TM-0001"
Y un producto válido "Taco al pastor"
Cuando el WAITER envía POST /orders con type="DINE_IN", reference="Mesa 4", y un plate con un item del producto
Entonces el sistema responde 201
Y la orden persistida tiene type="DINE_IN", reference="Mesa 4", deliveryAddress=null, status="PENDING", revision=1
```

### REQ-0021 — Crear orden TAKEAWAY con reference obligatoria

```gherkin
Dado un WAITER autenticado
Cuando envía POST /orders con type="TAKEAWAY", reference="Roberto", y al menos un item
Entonces responde 201
Y la orden tiene type="TAKEAWAY", reference="Roberto", deliveryAddress=null
```

### REQ-0022 — Crear orden DELIVERY con deliveryAddress obligatoria

```gherkin
Dado un WAITER autenticado
Cuando envía POST /orders con type="DELIVERY", deliveryAddress="Av. Juárez #123", y al menos un item
Entonces responde 201
Y la orden tiene type="DELIVERY", deliveryAddress="Av. Juárez #123"
Y reference es opcional (puede ser null)
```

### REQ-0023 — DINE_IN sin reference falla con 400

```gherkin
Dado un WAITER autenticado
Cuando envía POST /orders con type="DINE_IN" sin reference
Entonces responde 400 con error de validación citando "reference"
Y no se persiste ninguna orden
Y no se emite ningún evento
```

### REQ-0024 — DELIVERY sin deliveryAddress falla con 400

```gherkin
Dado un WAITER autenticado
Cuando envía POST /orders con type="DELIVERY" sin deliveryAddress
Entonces responde 400 con error de validación citando "deliveryAddress"
Y no se persiste ninguna orden
```

### REQ-0025 — Orden creada arranca con revision=1 y status=PENDING

```gherkin
Dado un WAITER autenticado
Cuando crea una orden válida
Entonces la respuesta incluye revision=1 y status="PENDING"
Y priorityTimestamp = createdAt
```

### REQ-0026 — POST /orders emite order-created al room de la taquería

```gherkin
Dado un WAITER de taquería "TM-0001" autenticado
Y un COOK de la misma taquería conectado a Socket.IO en el room "taqueria:<id>"
Cuando el WAITER hace POST /orders con datos válidos
Entonces el COOK recibe el evento "order-created" con el payload completo de la orden
Y un COOK de otra taquería "TM-0002" NO recibe ese evento
```

### REQ-0027 — COOK no puede crear órdenes

```gherkin
Dado un COOK autenticado
Cuando intenta POST /orders
Entonces responde 403
```

## 7. Edge Cases

- **Sin plates ni items** → 400 (DTO requiere al menos un plate con al menos un item).
- **Producto inexistente o de otra taquería** → 400/404 (validación de ownership en service).
- **JWT inválido o ausente** → 401.
- **Concurrencia: dos waiters crean orden a la vez** → ambos exitosos, IDs distintos, sin colisión.
- **complementos = `[]`** → válido.
- **notes = null o ""** → válido.

## 8. Requerimientos no funcionales

- **Performance:** p95 < 300ms para crear orden con hasta 5 plates / 10 items totales.
- **Seguridad:** JWT obligatorio. Guard de rol exige `WAITER`. Filtro por `taqueriaId` en lookup de productos.
- **Multi-tenancy:** la orden persiste con `taqueriaId = request.user.taqueriaId`. Constitución Artículo I.
- **Realtime:** evento emitido en la misma transacción lógica del controller (no fire-and-forget si falla la emisión, log + alerta).
- **Idempotencia:** no garantizada en esta versión — un POST repetido crea dos órdenes. (Riesgo aceptado para MVP.)

## 9. Dependencias

- Spec: `specs/authentication/spec.md` (requiere JWT)
- Spec: `specs/products-management/spec.md` (productos referenciados deben existir)
- Spec: `specs/realtime-sync/spec.md` (canal de emisión)
- ADRs: ADR-0001 (multi-tenant), ADR-0002 (JWT), ADR-0003 (Socket.IO), ADR-0004 (backend source of truth), ADR-0005 (append-only)
- Contratos: `contracts/openapi.yaml#/paths/~1orders~POST`, `contracts/asyncapi.yaml#/components/messages/OrderCreated`

## 10. Riesgos / Preguntas abiertas

- ❓ ¿Necesitamos idempotency-key para evitar duplicados por tap doble del WAITER? — Probable ADR futuro.
- ❓ ¿Qué pasa si la emisión del socket falla pero la DB ya commiteó? — Hoy: log warning, la orden existe. Futuro: outbox pattern.

## 11. Referencias

- Roadmap ETAPA 4.5.3, 4.6.1
- `business-rules.md` §6 (Pedidos), §16 (Tipos)
- `backend-api.md` — POST /orders
- `api-reference.md` — POST /orders
- `backend-realtime.md` — order-created
