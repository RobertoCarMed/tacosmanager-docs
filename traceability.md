# Matriz de Trazabilidad

Versión: 1.0
Estado: Vigente

Mapea cada `REQ-ID` (acceptance criterion) a sus artefactos: spec, test, archivos de implementación, PR y ETAPA del roadmap.

Reglas:

1. Cada `REQ-ID` es único e inmutable. Nunca se reutiliza.
2. Una spec PUEDE tener múltiples REQ. Un test PUEDE cubrir múltiples REQ.
3. Esta tabla es la fuente de verdad para auditoría. PRs sin entrada aquí son rechazados.

---

## Convenciones

- `REQ-NNNN` — Acceptance criterion estable. **Inmutable** una vez `✅` (ver ADR-0009).
- `TEST-<archivo>::<nombre>` — Identificador legible del test que lo cubre.
- `Spec` — Ruta relativa al directorio de la spec.
- `Versión` — Versión de la spec en la que el REQ fue introducido (SemVer MAJOR.MINOR, ver ADR-0009).
- `Sucesor` — Para REQ deprecados, indica qué REQ-ID lo reemplaza.
- `ETAPA` — Hito del roadmap.

---

## Matriz

| REQ-ID | Descripción corta | Spec | Versión introducida | Test esperado | Archivos clave | ETAPA | Estado | Sucesor |
|---|---|---|---|---|---|---|---|---|
| REQ-0001 | Login válido devuelve accessToken + user + taqueria | specs/authentication | 1.0 | auth.e2e-spec.ts::login_success | backend/src/auth/* | 4.5.1 | ✅ |   |
| REQ-0002 | Login con credenciales inválidas devuelve 401 | specs/authentication | 1.0 | auth.e2e-spec.ts::login_invalid | backend/src/auth/* | 4.5.1 | ✅ |   |
| REQ-0003 | GET /auth/me valida token y retorna contexto | specs/authentication | 1.0 | auth.e2e-spec.ts::me_valid | backend/src/auth/* | 4.5.1 | ✅ |   |
| REQ-0004 | Smart register crea taquería si no existe | specs/authentication | 1.0 | auth.e2e-spec.ts::register_new | backend/src/auth/* | 4.5.1 | ✅ |   |
| REQ-0005 | Smart register une usuario a taquería existente | specs/authentication | 1.0 | auth.e2e-spec.ts::register_join | backend/src/auth/* | 4.5.1 | ✅ |   |
| REQ-0010 | COOK lista todos los productos de su taquería | specs/products-management | 1.0 | products.e2e-spec.ts::cook_lists_all | backend/src/products/* | 4.5.2 | ✅ |   |
| REQ-0011 | WAITER lista todos los productos (lectura) | specs/products-management | 1.0 | products.e2e-spec.ts::waiter_lists_all | backend/src/products/* | 4.5.2 | ✅ |   |
| REQ-0012 | Solo COOK puede crear productos | specs/products-management | 1.0 | products.e2e-spec.ts::waiter_cannot_create | backend/src/products/* | 4.5.2 | ✅ |   |
| REQ-0013 | Solo COOK puede editar productos | specs/products-management | 1.0 | products.e2e-spec.ts::waiter_cannot_edit | backend/src/products/* | 4.5.2 | ✅ |   |
| REQ-0014 | Solo COOK puede eliminar productos | specs/products-management | 1.0 | products.e2e-spec.ts::waiter_cannot_delete | backend/src/products/* | 4.5.2 | ✅ |   |
| REQ-0015 | Usuario de taquería A no ve productos de taquería B | specs/products-management | 1.0 | products.e2e-spec.ts::tenant_isolation | backend/src/products/* | 4.5.2 | ✅ |   |
| REQ-0020 | WAITER crea orden DINE_IN con reference obligatoria | specs/create-order | 1.0 | orders.e2e-spec.ts::create_dine_in | backend/src/orders/* | 4.6.1 | ✅ |   |
| REQ-0021 | WAITER crea orden TAKEAWAY con reference obligatoria | specs/create-order | 1.0 | orders.e2e-spec.ts::create_takeaway | backend/src/orders/* | 4.6.1 | ✅ |   |
| REQ-0022 | WAITER crea orden DELIVERY con deliveryAddress obligatoria | specs/create-order | 1.0 | orders.e2e-spec.ts::create_delivery | backend/src/orders/* | 4.6.1 | ✅ |   |
| REQ-0023 | DINE_IN sin reference → 400 | specs/create-order | 1.0 | orders.e2e-spec.ts::dine_in_no_ref_fails | backend/src/orders/dto/* | 4.6.1 | ✅ |   |
| REQ-0024 | DELIVERY sin deliveryAddress → 400 | specs/create-order | 1.0 | orders.e2e-spec.ts::delivery_no_address_fails | backend/src/orders/dto/* | 4.6.1 | ✅ |   |
| REQ-0025 | Orden creada con revision = 1 y status = PENDING | specs/create-order | 1.0 | orders.e2e-spec.ts::initial_revision | backend/src/orders/* | 4.6.1 | ✅ |   |
| REQ-0026 | Crear orden emite order-created al room taqueria:<id> | specs/create-order | 1.0 | orders.e2e-spec.ts::emit_order_created | backend/src/orders/* | 4.5.4 | ✅ |   |
| REQ-0027 | COOK NO puede crear órdenes | specs/create-order | 1.0 | orders.e2e-spec.ts::cook_cannot_create | backend/src/orders/* | 4.6.1 | ✅ |   |
| REQ-0030 | PATCH /orders/:id agrega plates/items nuevos | specs/edit-order | 1.0 | orders.e2e-spec.ts::append_items | backend/src/orders/* | 4.6.2 | 🗑️ | REQ-0048 |
| REQ-0031 | PATCH no permite modificar items históricos | specs/edit-order | 1.0 | orders.e2e-spec.ts::cannot_modify_history | backend/src/orders/* | 4.6.2 | ✅ |   |
| REQ-0032 | revision se incrementa en cada append | specs/edit-order | 1.0 | orders.e2e-spec.ts::revision_increments | backend/src/orders/* | 4.6.2 | ✅ |   |
| REQ-0033 | Items nuevos llegan con isNew = true | specs/edit-order | 1.0 | orders.e2e-spec.ts::new_items_flagged | backend/src/orders/* | 4.5.6.2 | ✅ |   |
| REQ-0034 | Append en READY transiciona status a PENDING | specs/edit-order | 1.0 | orders.e2e-spec.ts::ready_to_pending | backend/src/orders/* | 4.5.6.1 | ✅ |   |
| REQ-0035 | Append en PREPARING mantiene PREPARING | specs/edit-order | 1.0 | orders.e2e-spec.ts::preparing_stays | backend/src/orders/* | 4.5.6.1 | ✅ |   |
| REQ-0036 | Append emite order-updated | specs/edit-order | 1.0 | orders.e2e-spec.ts::emit_order_updated | backend/src/orders/* | 4.5.4 | ✅ |   |
| REQ-0048 | PATCH agrega plate nuevo; plateNumber existente → 400 (sucede a REQ-0030) | specs/edit-order | 2.0 | orders.e2e-spec.ts::append_new_plate | backend/src/orders/orders.service.ts (updateOrder) | 4.6.2 | 🟡 |   |
| REQ-0040 | COOK cambia status a valores válidos | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::status_change | backend/src/orders/* | 4.5.6.1 | ✅ |   |
| REQ-0041 | Asignar UPDATED manualmente → 400 | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::updated_rejected | backend/src/orders/* | 4.5.6.1 | ✅ |   |
| REQ-0042 | Transición a READY limpia isNew | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::ready_clears_isnew | backend/src/orders/* | 4.5.6.2 | ✅ |   |
| REQ-0043 | Ordenamiento Kitchen: PREPARING > PENDING > READY > DELIVERED > CANCELLED | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::queue_ordering | backend/src/orders/* | 4.5.6.1 | ✅ |   |
| REQ-0044 | Dentro del mismo status, FIFO por createdAt | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::fifo_within_status | backend/src/orders/* | 4.5.6.1 | 🗑️ | REQ-0047 |
| REQ-0045 | Cambio de status emite order-status-changed | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::emit_status_changed | backend/src/orders/* | 4.5.4 | ✅ |   |
| REQ-0046 | WAITER NO puede cambiar status | specs/kitchen-queue | 1.0 | orders.e2e-spec.ts::waiter_cannot_change_status | backend/src/orders/* | 4.5.6.1 | ✅ |   |
| REQ-0047 | Dentro del mismo status, FIFO por priorityTimestamp (sucede a REQ-0044) | specs/kitchen-queue | 2.0 | orders.e2e-spec.ts::fifo_by_priority_timestamp | backend/src/orders/orders.service.ts (getOrders, updateOrder) | 4.5.6.1 | 🟡 |   |
| REQ-0050 | Socket sin JWT es rechazado | specs/realtime-sync | 1.0 | realtime.e2e-spec.ts::no_jwt_rejected | backend/src/realtime/* | 4.5.4 | ✅ |   |
| REQ-0051 | Socket conectado se une a taqueria:<taqueriaId> | specs/realtime-sync | 1.0 | realtime.e2e-spec.ts::auto_join_room | backend/src/realtime/* | 4.5.4 | ✅ |   |
| REQ-0052 | Usuarios de distintas taquerías nunca comparten room | specs/realtime-sync | 1.0 | realtime.e2e-spec.ts::room_isolation | backend/src/realtime/* | 4.5.4 | ✅ |   |
| REQ-0053 | Tras reconexión, cliente puede resincronizar | specs/realtime-sync | 1.0 | realtime.e2e-spec.ts::reconnect_resync | mobile/src/realtime/* | 4.7.2 | ✅ |   |
| REQ-0054 | Multi-device: dos dispositivos del mismo user reciben los eventos | specs/realtime-sync | 1.0 | realtime.e2e-spec.ts::multi_device | backend/src/realtime/* | 4.7.3 | ✅ |   |

---

## Estados

- ✅ Implementado y verificado
- 🟡 Implementado, falta test automatizado
- 🔴 Pendiente
- 🗑️ Deprecado

---

## Cómo Agregar un REQ Nuevo

1. Asignar el siguiente `REQ-NNNN` libre (incrementar el último usado).
2. Agregar fila en esta matriz **antes** de abrir el PR.
3. Referenciar el `REQ-ID` en:
   - La spec correspondiente.
   - El nombre o cuerpo del test.
   - El cuerpo del PR (`Closes REQ-NNNN`).
4. Una vez merged, el `REQ-ID` es inmutable. Si el requisito cambia, se crea uno nuevo y el viejo pasa a `🗑️` con referencia al sucesor.
