# TacosManager — UI Flows

Version: 1.2
Última actualización: ETAPA 4.6.2 ✅ (4.6.1 ✅ completada / 4.6.2 ✅ completada / 4.6.3 siguiente etapa)

---

## Índice

1. [Authentication Flow](#authentication-flow)
2. [Create Order Flow](#create-order-flow)
3. [Edit Order Flow](#edit-order-flow)
4. [Kitchen Flow](#kitchen-flow)
5. [Settings Flow](#settings-flow)

---

## Authentication Flow

### Login

```txt
LoginScreen
 ├── Inputs: email, password
 ├── [Iniciar sesión] → POST /auth/login
 │     ├── success → AuthContext.signIn → navigate by role
 │     │     ├── cook   → KitchenStack
 │     │     └── waiter → WaiterStack
 │     └── failure → show error message
 └── [Registrarse] → RegisterScreen
```

### Register — Flujo de 2 fases

```txt
RegisterScreen
 ├── Phase 1 — Búsqueda
 │     ├── Inputs: nombre, email, password, rol, nombre de taquería
 │     └── [Continuar] → POST /auth/register (Phase 1 — sin escritura)
 │           ├── 0 coincidencias → mostrar formulario "Crear nueva taquería"
 │           │     ├── Campos opcionales: teléfono, dirección, ciudad, estado
 │           │     └── [Crear taquería] → POST /auth/register (Phase 2B)
 │           ├── 1 coincidencia → mostrar la taquería encontrada
 │           │     ├── [Unirme] → POST /auth/register (Phase 2A)
 │           │     └── [Crear nueva] → formulario nueva taquería (Phase 2B)
 │           └── N coincidencias → mostrar lista (nombre + restaurantCode)
 │                 ├── [Seleccionar] → POST /auth/register (Phase 2A)
 │                 └── [Crear nueva] → formulario nueva taquería (Phase 2B)
 │
 └── Phase 2 result
       ├── success → AuthContext.signIn → navigate by role
       └── failure → show error
```

---

## Create Order Flow

### Flujo actual — ETAPA 4.5.3

```txt
WaiterStack
 └── CreateOrderScreen
       ├── Input: tableNumber (ej. "Mesa 4")
       ├── Product selector
       │     ├── Lista de productos del catálogo
       │     ├── Seleccionar producto
       │     │     ├── Selector de complementos (checkboxes)
       │     │     └── Selector de cantidad
       │     └── Lista de items seleccionados
       │           ├── Precio por item y subtotal
       │           └── Total del pedido
       └── [Guardar pedido] → POST /orders
             ├── success → navigate back / update list
             └── failure → show error
```

### Flujo implementado — ETAPA 4.6.2 ✅ COMPLETADA

Se agrega un selector de tipo de pedido al inicio del flujo.

El campo de referencia es dinámico según el tipo seleccionado.

```txt
CreateOrderScreen (ETAPA 4.6.2)
 ├── [1] OrderType Selector (obligatorio, primer paso)
 │     ├── 🍽 Comer aquí  (DINE_IN)
 │     ├── 🥡 Para llevar (TAKEAWAY)
 │     └── 🛵 Delivery    (DELIVERY)
 │
 ├── [2] Campo dinámico según OrderType
 │     ├── DINE_IN
 │     │     label:       "Referencia"
 │     │     placeholder: "Mesa 4"
 │     │     obligatorio: sí
 │     ├── TAKEAWAY
 │     │     label:       "Nombre cliente"
 │     │     placeholder: "Roberto"
 │     │     obligatorio: sí
 │     └── DELIVERY
 │           label:       "Dirección"
 │           placeholder: "Av. Juárez #123"
 │           obligatorio: sí (deliveryAddress)
 │           + campo opcional: reference (nombre del cliente que recibe)
 │
 ├── [3] Product selector (sin cambios respecto al flujo actual)
 │     └── ...
 │
 └── [Guardar pedido] → POST /orders
       ├── body incluye: orderType + reference | deliveryAddress + plates
       ├── success → navigate back / update list
       └── failure → show error
```

#### Crear pedido DINE_IN

```txt
CreateOrderScreen
 ├── Selector: 🍽 Comer aquí  [seleccionado]
 ├── Campo: "Referencia"   placeholder: "Mesa 4"   (obligatorio)
 ├── Product selector
 └── [Guardar] → POST /orders { orderType: "DINE_IN", reference: "Mesa 4", plates: [...] }
```

#### Crear pedido TAKEAWAY

```txt
CreateOrderScreen
 ├── Selector: 🥡 Para llevar  [seleccionado]
 ├── Campo: "Nombre cliente"   placeholder: "Roberto"   (obligatorio)
 ├── Product selector
 └── [Guardar] → POST /orders { orderType: "TAKEAWAY", reference: "Roberto", plates: [...] }
```

#### Crear pedido DELIVERY

```txt
CreateOrderScreen
 ├── Selector: 🛵 Delivery  [seleccionado]
 ├── Campo: "Dirección"   placeholder: "Av. Juárez #123"   (obligatorio)
 ├── Campo: "Nombre cliente"   placeholder: "Roberto"   (opcional)
 ├── Product selector
 └── [Guardar] → POST /orders
       { orderType: "DELIVERY", deliveryAddress: "Av. Juárez #123", reference: "Roberto" | null, plates: [...] }
```

#### Validaciones UI por OrderType

```txt
DINE_IN
 ├── reference: required
 └── [Guardar] deshabilitado si reference está vacío

TAKEAWAY
 ├── reference: required
 └── [Guardar] deshabilitado si reference está vacío

DELIVERY
 ├── deliveryAddress: required
 ├── reference: opcional
 └── [Guardar] deshabilitado si deliveryAddress está vacío
```

#### Comportamiento del campo al cambiar de tipo

El campo se limpia al cambiar de OrderType para evitar confusión.

El placeholder y el label cambian dinámicamente.

---

## Waiter Orders Filter

```txt
WaiterOrdersScreen
 ├── Filtro inicial: 'active' (pedidos no terminados, sin límite de fecha)
 │     Opciones disponibles: Activos | Hoy | Últimos 7 días | Último mes | Últimos 3 meses
 │
 ├── Filtro 'active': muestra todos los pedidos cuyo status NO sea DELIVERED ni CANCELLED
 │     → Independiente de la fecha de creación
 │     → Un pedido de 23:55 sigue visible al día siguiente si aún está activo
 │
 └── Filtros históricos ('today', '7d', '1m', '3m'): filtran por createdAt
```

---

## Edit Order Flow

### Flujo actual — ETAPA 4.5.3

Append-only. Solo se pueden agregar nuevos plates.

```txt
WaiterOrdersScreen
 └── [Editar] en una orden → EditOrderScreen
       ├── Muestra plates existentes (readonly — no editables)
       ├── Formulario para agregar nuevo plate
       │     ├── Product selector
       │     │     ├── Seleccionar producto
       │     │     ├── Complementos
       │     │     └── Cantidad
       │     └── Lista de items del nuevo plate
       └── [Guardar cambios] → PATCH /orders/:id
             ├── plates[new].plateNumber = max(existing.plateNumbers) + index + 1
             ├── success → navigate back
             └── failure → show error
```

#### Regla de negocio

Los plates e items existentes son inmutables.

Solo se pueden agregar nuevos plates con nuevos items.

### Flujo implementado — ETAPA 4.6.2 ✅ COMPLETADA

Se agrega la capacidad de cambiar el tipo de pedido durante la edición.

```txt
EditOrderScreen (ETAPA 4.6.2)
 ├── Encabezado del pedido
 │     ├── Tipo actual (editable): 🍽 DINE_IN | 🥡 TAKEAWAY | 🛵 DELIVERY
 │     ├── Reference o deliveryAddress actual (visible y editable)
 │     └── [Cambiar tipo] → muestra selector de tipo
 │
 ├── Pedido DELIVERY — dirección visible
 │     └── deliveryAddress se muestra completa dentro del flujo actual
 │         (sin pantalla adicional)
 │
 ├── Plates existentes (readonly — no editables)
 │
 ├── Formulario para agregar nuevo plate (sin cambios)
 │     └── ...
 │
 └── [Guardar cambios] → PATCH /orders/:id
       ├── body incluye nuevos plates + cambios de tipo si aplica
       ├── success → navigate back
       └── failure → show error
```

#### Editar tipo de pedido

```txt
EditOrderScreen — usuario cambia tipo
 ├── Orden es DINE_IN → mesero selecciona DELIVERY
 │     ├── Campo cambia a "Dirección" (placeholder: Av. Juárez #123)
 │     ├── Campo anterior (reference) se limpia
 │     └── [Guardar] → envía orderType: "DELIVERY", deliveryAddress: "..."
 │
 └── Orden es DELIVERY → mesero selecciona TAKEAWAY
       ├── Campo cambia a "Nombre cliente" (placeholder: Roberto)
       ├── deliveryAddress anterior se descarta
       └── [Guardar] → envía orderType: "TAKEAWAY", reference: "..."
```

#### Visualización de dirección DELIVERY en edición

```txt
EditOrderScreen — pedido DELIVERY
 ├── Header muestra: 🛵 Delivery
 ├── Dirección visible: "Av. Juárez #123"  (texto completo, no truncado)
 └── Mesero puede editar la dirección antes de guardar cambios
```

---

## Kitchen Flow

### Cola de cocina — KitchenScreen

```txt
KitchenScreen
 ├── Filtro inicial: 'active' (pedidos no terminados, sin límite de fecha)
 │     Opciones disponibles: Activos | Hoy | Últimos 7 días | Último mes | Últimos 3 meses
 │
 ├── Lista de órdenes ordenada por prioridad (desde el backend)
 │     Prioridad objetivo (ETAPA 4.5.6.1): PREPARING > PENDING > READY
 │     (pre-4.5.6.1: UPDATED > PENDING > PREPARING > READY — UPDATED deprecado en 4.5.6.1)
 │
 └── OrderCard por cada orden activa
       ├── Encabezado
       │     ├── Identificador de pedido via getOrderDisplayLabel(order)
       │     │     🍽 Mesa 4 | 🥡 Roberto | 🛵 Roberto - Enviar | 🛵 Av. Juárez #123...
       │     ├── Estado (badge) — sin UPDATED (eliminado en ETAPA 4.5.6.2)
       │     └── Timestamp
       ├── Lista de plates e items
       │     ├── Items con isNew = true → fondo verde (cualquier estado activo — ETAPA 4.5.6.2 ✅)
       │     └── Items originales → sin highlight
       └── Acciones
             ├── PENDING   → [Marcar preparando]  → PATCH /orders/:id/status PREPARING
             ├── PREPARING → [Marcar listo]        → PATCH /orders/:id/status READY
             └── READY     → [Entregado]           → PATCH /orders/:id/status DELIVERED
```

### Kitchen OrderCard — ETAPA 4.6.3 🟡 / ETAPA 4.5.6.2 🟡

El encabezado del OrderCard muestra emoji + referencia via `getOrderDisplayLabel(order)`.

```txt
OrderCard header
 ├── DINE_IN
 │     🍽 Mesa 4
 │
 ├── TAKEAWAY
 │     🥡 Roberto
 │
 ├── DELIVERY (con reference)
 │     🛵 Roberto - Enviar
 │
 └── DELIVERY (sin reference)
       🛵 Av. Juárez #123...   (truncado a 20 chars)
```

Sin texto adicional. Sin etiquetas redundantes.

El cocinero identifica la modalidad a distancia con solo ver el emoji.

Kitchen NO agrupa pedidos por tipo. El FIFO y la priorización de estados no cambian.

Implementado en `src/shared/utils/orderDisplay.ts`. Aplicado a kitchen/components/OrderCard y shared/components/OrderCard (waiter y kitchen variants).

### Kitchen Dashboard — KitchenDashboardScreen

Vista horizontal optimizada para tablets.

```txt
KitchenDashboardScreen
 ├── FlatList horizontal de órdenes
 ├── Filtro: excluye DELIVERED y CANCELLED
 └── OrderCard compacto con acciones inline
```

### isNew Highlight Rules (ETAPA 4.5.6.2 🟡)

```txt
item.isNew === true  → fondo verde (#E8F5E9) + borde (#C8E6C9) en cualquier estado activo (PENDING, PREPARING)
item.isNew === false → sin highlight

Limpieza automática al pasar a READY:
  → isNew = false en todos los items (servidor, misma transacción)
  → No hay items verdes cuando order.status === 'READY'
```

Implementado: `kitchen/components/OrderCard.tsx` (estilo `itemRowUpdated`) y `shared/components/OrderCard.tsx` variante kitchen (nuevo estilo `itemRowNew`). Ambos leen `item.isNew` directamente, independiente del status de la orden.

---

## Settings Flow

```txt
SettingsScreen (accesible desde KitchenStack y WaiterStack)
 ├── [Agregar producto]  → CreateProductScreen
 ├── [Editar productos]  → lista → EditProductScreen
 └── [Cerrar sesión]     → authService.signOut → LoginScreen
```

---

## Estado global de navegación

```txt
RootNavigator
 ├── AuthStack (si user === null)
 │     ├── LoginScreen
 │     └── RegisterScreen
 ├── KitchenStack (si role === "cook")
 │     ├── KitchenScreen
 │     ├── KitchenDashboardScreen
 │     └── SettingsScreen
 └── WaiterStack (si role === "waiter")
       ├── WaiterOrdersScreen
       ├── CreateOrderScreen
       ├── EditOrderScreen
       └── SettingsScreen
```

---

## Reglas generales de UX

- El frontend nunca envía `taqueriaId` en el body — el backend lo extrae del JWT.
- Al salir de una pantalla de creación/edición, los cambios no guardados se descartan.
- Los errores de API se muestran como mensajes inline (no toasts) para mantener el contexto.
- Las pantallas de cocina están optimizadas para uso a distancia en tablets de 10 pulgadas (fuente grande, cards amplias, contraste alto).

---

*Última actualización: ETAPA 4.5.6.2 🟡 — 4.5.6.1 ✅ 4.6.1 ✅ 4.6.2 ✅ completadas. 4.5.6.2 Kitchen Visualization y 4.6.3 Kitchen Integration en progreso.*
