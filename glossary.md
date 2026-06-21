# Glosario TacosManager — Ubiquitous Language

Versión: 1.0
Estado: Vigente

Este glosario define el vocabulario canónico del dominio. Cada término aquí listado DEBE usarse consistentemente en código, documentación, UI, commits y conversación. Renombrar un término requiere ADR.

---

## Dominio de Negocio

### Taquería
Restaurante de tacos que opera dentro de TacosManager. Es la **unidad de tenancy**. Toda entidad pertenece a una y solo una Taquería.

### RestaurantCode
Identificador único, público y legible de una Taquería. Generado automáticamente, inmutable. Ejemplos: `TM-4821`, `TQR-1832`.
Diferencia con `taqueriaId`: el `taqueriaId` es interno (UUID); `restaurantCode` es de cara al usuario.

### Plan de Suscripción
Nivel comercial contratado por una Taquería. Valores: `STARTER`, `GROWTH`, `PRO`. Ver `business-model.md`.

---

## Actores

### Cook (COOK)
Usuario con rol cocinero. Ve TODOS los pedidos de su Taquería, cambia estados, gestiona productos.

### Waiter (WAITER)
Usuario con rol mesero. Crea y edita pedidos. Solo ve SUS propios pedidos.

---

## Órdenes

### Order (Orden / Pedido)
Agregado raíz de venta. Contiene metadata (tipo, referencia, status, revision) y una colección de `Plate`s.

### OrderType
Modalidad de consumo. Independiente de `OrderStatus`. Valores:
- `DINE_IN` — consumo en mesa
- `TAKEAWAY` — para llevar
- `DELIVERY` — a domicilio

### OrderStatus
Etapa de preparación de cocina. Valores:
- `PENDING` — recibido, no iniciado
- `PREPARING` — en cocina
- `READY` — listo para entrega
- `DELIVERED` — entregado al cliente
- `CANCELLED` — cancelado
- `UPDATED` — **DEPRECADO** (ETAPA 4.5.6.1). Se conserva en DB para histórico.

### Plate (Platillo / Conjunto)
Subagregado de Order. Agrupa items pedidos juntos (por ejemplo "Plato del cliente 1"). Tiene `plateNumber`, `isClosed`, `createdInRevision`.

### Item
Línea individual dentro de un Plate. Referencia un `Product`, cantidad, complementos seleccionados, notas. Campo `isNew: true` lo marca como recién agregado.

### Revision
Contador monotónico de la Order. Inicia en `1` al crear. Se incrementa en cada `PATCH /orders/:id` (append).

### Append-Only
Principio constitucional (Artículo V). El **trabajo de cocina** de una orden es inmutable: los plates/items históricos nunca se modifican retroactivamente, solo se agregan nuevos. La **clasificación** de la orden (`type`/`reference`/`deliveryAddress`) sí puede corregirse post-creación (ver [Edición de Clasificación] y ADR-0011).

### Edición de Clasificación
Corrección de `type`/`reference`/`deliveryAddress` de una orden existente vía `PATCH /orders/:id` (ADR-0011, REQ-0062). No toca plates/items históricos. La validación se aplica sobre el estado efectivo resultante (tipo nuevo + reference/deliveryAddress coherentes).

### priorityTimestamp
Timestamp usado para ordenamiento en Kitchen Queue. FIFO dentro del mismo `OrderStatus`.

### Reference
Etiqueta humana de la orden, dependiente de `OrderType`:
- `DINE_IN`: identificación de mesa (ej. "Mesa 4"). Obligatorio.
- `TAKEAWAY`: nombre del cliente. Obligatorio.
- `DELIVERY`: opcional.

### DeliveryAddress
Dirección de entrega. Obligatorio si `OrderType = DELIVERY`. Nulo en otros casos.

### isNew (highlight)
Flag a nivel Item. `true` cuando el item fue agregado en una revisión posterior a la creación de la orden. Genera highlight verde en cocina. Se limpia automáticamente al transicionar a `READY`.

---

## Productos

### Product
Ítem del catálogo de una Taquería. CRUD por COOK. Lectura por COOK y WAITER.

### Complement (Complemento)
Opción seleccionable de un Product (ej. "Salsa verde", "Sin cebolla"). Se almacena como `selectedComplements: string[]` dentro del Item.

---

## Realtime

### Room
Canal Socket.IO. Naming: `taqueria:<taqueriaId>`. Garantiza aislamiento multi-tenant.

### Eventos Servidor → Cliente
- `order-created` — emitido tras `POST /orders`
- `order-updated` — emitido tras `PATCH /orders/:id` (append)
- `order-status-changed` — emitido tras `PATCH /orders/:id/status`

### Eventos Cliente → Servidor
- `join-taqueria` — confirma room activa del usuario autenticado

### Resync
Proceso de reconciliación tras reconexión del socket. El cliente solicita estado actual y descarta caché potencialmente obsoleta.

---

## Autenticación

### accessToken
JWT firmado por el backend. Expiración 1 día. Contiene `userId`, `taqueriaId`, `role`.

### Session Restore
Flujo de arranque del frontend: lee token persistido, valida con `GET /auth/me`, restaura contexto o redirige a Login.

### Smart Register
`POST /auth/register`. Detecta coincidencias de taquería, crea nueva o une al usuario a una existente.

---

## Arquitectura

### Source of Truth (Backend)
Principio constitucional (Artículo II). El backend es la única fuente autoritativa del estado.

### Ownership
Validación de propiedad. Toda query a recurso individual filtra por `taqueriaId` y, cuando aplique, por `waiterId`.

### Multi-Tenant
Modelo donde múltiples Taquerías comparten infraestructura pero NUNCA datos. Aislamiento enforzado por filtros obligatorios.

---

## Proceso

### Spec
Documento `specs/<feature>/spec.md`. Funcional, con user stories y acceptance criteria.

### Plan
Documento `specs/<feature>/plan.md`. Técnico, derivado de la spec.

### Tasks
Documento `specs/<feature>/tasks.md`. Atómico, ejecutable, con IDs `TASK-XXXX`.

### ADR
Architecture Decision Record. Vive en `docs/adr/NNNN-titulo.md`. Inmutable una vez aceptado.

### REQ-ID
Identificador estable de un acceptance criterion. Formato `REQ-NNNN`. Nunca se reutiliza.

### ETAPA
Hito de desarrollo en `roadmap.md`. Formato `X.Y.Z` (ej. `4.6.1`). Cada ETAPA tiene archivos impactados declarados.

---

## Términos PROHIBIDOS

Los siguientes términos NO se usan en este proyecto:

| Evitar | Usar en su lugar |
|---|---|
| Restaurant, Store | Taquería |
| Order Status `UPDATED` (en lógica nueva) | Status condicional (CASO 1/2/3 de business-rules §16) |
| Modificar plates/items históricos | Append items / append plates |
| Cliente final | (no es entidad del modelo actual) |
| Inventory, Stock | (fuera de scope hasta nuevo ADR) |
