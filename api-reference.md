# TacosManager API Reference

Version: 1.0

Base URL

```txt
/api
```

---

# System

## GET /health

Health check del servicio. No requiere autenticación.

Response:

```json
{
  "status": "ok",
  "timestamp": "2026-05-27T12:00:00.000Z",
  "environment": "development"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `status` | `string` | Estado del servicio — siempre `"ok"` si el proceso responde |
| `timestamp` | `string` | ISO 8601 — momento en que se procesó la request |
| `environment` | `string` | Ambiente activo (`development` / `qa` / `production`) |

Usado por: Railway healthcheck, Backend CI pipeline (Health Check QA en push a main).

## GET /

Alias de `GET /health`. Devuelve el mismo payload.

---

# Authentication

---

## POST /auth/register

Registro inteligente.

Responsabilidades:

- detectar coincidencias de taquería
- crear nueva taquería
- unir usuario a taquería existente

---

## POST /auth/login

Login de usuario.

Body:

```json
{
  "email": "user@test.com",
  "password": "123456"
}
```

Response:

```json
{
  "accessToken": "jwt"
}
```

---

# Products

Todas las rutas requieren JWT.

---

## GET /products

Obtiene catálogo de la taquería actual.

Role:

- COOK
- WAITER

---

## POST /products

Crear producto.

Role:

- COOK

---

## GET /products/:id

Obtener producto.

Role:

- COOK
- WAITER

---

## PATCH /products/:id

Actualizar producto.

Role:

- COOK

---

## DELETE /products/:id

Eliminar producto.

Role:

- COOK

---

# Orders

Todas las rutas requieren JWT.

---

## POST /orders

Crear pedido.

Role:

- WAITER

Permite:

- múltiples plates
- múltiples items
- complementos
- notas opcionales

Campos requeridos (ETAPA 4.6.1 ✅):

- type (DINE_IN | TAKEAWAY | DELIVERY) — independiente de OrderStatus
- reference (obligatorio para DINE_IN y TAKEAWAY; opcional para DELIVERY)
- deliveryAddress (obligatorio para DELIVERY)

---

## GET /orders

COOK:

Obtiene todos los pedidos de la taquería.

WAITER:

Obtiene únicamente sus pedidos.

---

## GET /orders/:id

Obtiene detalle de pedido.

Ownership obligatorio.

---

## PATCH /orders/:id

Editar pedido.

Regla:

Append Only.

Permitido:

- agregar plates
- agregar items

Prohibido:

- modificar historial
- modificar items anteriores
- modificar plates anteriores

---

## PATCH /orders/:id/status

Actualizar estado.

Role:

- COOK

Estados válidos (asignables manualmente):

```txt
PENDING
PREPARING
READY
DELIVERED
CANCELLED
```

`UPDATED` no puede asignarse manualmente — es rechazado con `400`. Ver nota de deprecación abajo.

---

# Response Rules

Nunca retornar:

- passwords
- hashes
- datos sensibles
- información de otras taquerías

---

# Ownership Rules

Todas las consultas deben validar:

```txt
request.user.taqueriaId
```

---

# Multi-Tenant Rules

Usuarios únicamente pueden acceder a:

```txt
su propia taquería
```

---

# Kitchen Queue Rules

Orden global (ETAPA 4.5.6.1 ✅ implementado):

```txt
PREPARING  (trabajo activo)
PENDING    (trabajo nuevo)
READY      (listo para entrega)
DELIVERED
CANCELLED
```

> **Implementado en ETAPA 4.5.6.1:** Ordenamiento activo `PREPARING(1) > PENDING(2) > READY(3) > DELIVERED(4) > CANCELLED(5)`.

> **UPDATED `[DEPRECADO — ETAPA 4.5.6.1]`:** No forma parte del flujo operativo. El backend ya no asigna `UPDATED` al hacer `PATCH /orders/:id`. El status al hacer append es condicional (CASO 1/2/3 — ver business-rules.md sección 16). El enum se conserva en DB para compatibilidad con registros históricos.

---

Dentro de cada grupo:

FIFO (ADR-0010 — clave `priorityTimestamp`, reemplaza a `createdAt` de ADR-0006)

```txt
priorityTimestamp ASC
```

---

# Order Classification Rules ✅ ETAPA 4.6.1 COMPLETADA

## OrderType vs OrderStatus — Conceptos Independientes

OrderType NO reemplaza OrderStatus.

```txt
OrderStatus — etapa de preparación de cocina:
  PENDING | PREPARING | READY | DELIVERED | CANCELLED
  UPDATED  [DEPRECADO — ETAPA 4.5.6.1]

OrderType — modalidad de consumo:
  DINE_IN   → consumo en el restaurante
  TAKEAWAY  → para recoger
  DELIVERY  → entrega a domicilio
```

Un pedido puede tener orderType = DINE_IN y orderStatus = PREPARING al mismo tiempo.

## Campos nuevos por tipo

DINE_IN:

```txt
reference: string (obligatorio)   — ej. "Mesa 4", "Terraza 2"
deliveryAddress: null
```

TAKEAWAY:

```txt
reference: string (obligatorio)   — nombre del cliente
deliveryAddress: null
```

DELIVERY:

```txt
reference: string | null (opcional)
deliveryAddress: string (obligatorio)  — ej. "Av. Juárez #123"
```

## Visualización en Kitchen

```txt
🍽 Mesa 4
🥡 Roberto
🛵 Av. Juárez #123
```

---

# Highlight Rules

Item nuevo:

```txt
isNew = true
```

Visible en:

```txt
Cualquier estado activo donde isNew === true (PENDING, PREPARING — ETAPA 4.5.6.2 ✅)
```

Desaparece en:

```txt
READY — isNew limpiado en la misma transacción de BD
```

---

# WebSocket — Socket.IO

Puerto: mismo que la API REST (3000 por defecto).

Protocolo: Socket.IO v4.

---

## Conexión

El cliente debe enviar el JWT en el handshake:

```js
// Opción A — recomendada (React Native)
const socket = io('http://localhost:3000', {
  auth: { token: '<jwt>' }
});

// Opción B — header Authorization
const socket = io('http://localhost:3000', {
  extraHeaders: { Authorization: 'Bearer <jwt>' }
});
```

JWT inválido o ausente → conexión rechazada automáticamente.

---

## Rooms

Al conectarse exitosamente, el usuario es unido automáticamente a:

```txt
taqueria:<taqueriaId>
```

Usuarios de diferentes taquerías nunca comparten room.

---

## Eventos del cliente → servidor

### `join-taqueria`

Confirma la room activa del usuario autenticado.

```js
socket.emit('join-taqueria');
// o con callback
socket.emit('join-taqueria', (response) => {
  console.log(response.data.room); // "taqueria:<id>"
});
```

Respuesta:

```json
{
  "event": "join-taqueria",
  "data": {
    "room": "taqueria:<taqueriaId>",
    "taqueriaId": "<taqueriaId>",
    "restaurantCode": "TM-4821"
  }
}
```

---

## Eventos del servidor → cliente

### `order-created`

Emitido a `taqueria:<taqueriaId>` cuando un WAITER crea un pedido nuevo (POST /orders).

```js
socket.on('order-created', ({ order }) => {
  // order contiene la orden completa
});
```

Payload:

```json
{
  "order": {
    "id": "uuid",
    "taqueriaId": "uuid",
    "waiterId": "uuid",
    "type": "DINE_IN",
    "reference": "Mesa 3",
    "deliveryAddress": null,
    "status": "PENDING",
    "revision": 1,
    "priorityTimestamp": "2024-01-01T12:00:00.000Z",
    "createdAt": "2024-01-01T12:00:00.000Z",
    "updatedAt": "2024-01-01T12:00:00.000Z",
    "plates": [
      {
        "id": "uuid",
        "plateNumber": 1,
        "isClosed": false,
        "createdInRevision": 1,
        "createdAt": "2024-01-01T12:00:00.000Z",
        "items": [
          {
            "id": "uuid",
            "productId": "uuid",
            "quantity": 2,
            "selectedComplements": ["Salsa verde"],
            "notes": null,
            "isNew": false,
            "createdInRevision": 1,
            "createdAt": "2024-01-01T12:00:00.000Z"
          }
        ]
      }
    ]
  }
}
```

---

### `order-updated`

Emitido a `taqueria:<taqueriaId>` cuando un WAITER agrega plates/items (PATCH /orders/:id).

La revisión se incrementa. Los nuevos items tienen `isNew: true` para highlight verde en cocina.

El status resultante depende del estado previo (ETAPA 4.5.6.1): PENDING→PENDING, PREPARING→PREPARING, READY→PENDING.

```js
socket.on('order-updated', ({ order }) => {
  // order contiene la orden completa con todos los plates (históricos + nuevos)
});
```

Payload: misma estructura que `order-created`. Campos clave:

```json
{
  "order": {
    "status": "PENDING",
    "revision": 2,
    "plates": [
      { "createdInRevision": 1, "items": [{ "isNew": false }] },
      { "createdInRevision": 2, "items": [{ "isNew": true }] }
    ]
  }
}
```

> **Nota — pre-4.5.6.1:** `status` siempre es `"UPDATED"` en la implementación actual.

---

### `order-status-changed`

Emitido a `taqueria:<taqueriaId>` cuando un COOK cambia el estado (PATCH /orders/:id/status).

Al transicionar a `READY`, todos los items con `isNew: true` se limpian automáticamente.

```js
socket.on('order-status-changed', ({ order }) => {
  // order contiene la orden con el nuevo status y isNew actualizado
});
```

Payload: misma estructura que `order-created`. Campo clave:

```json
{
  "order": {
    "status": "PREPARING"
  }
}
```

---

End of Document