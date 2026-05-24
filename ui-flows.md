# TacosManager — UI Flows

Version: 1.0
Última actualización: ETAPA 4.5.3 (incluye diseño ETAPA 4.6)

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

### Flujo planificado — ETAPA 4.6

Se agrega un selector de tipo de pedido al inicio del flujo.

```txt
CreateOrderScreen (ETAPA 4.6)
 ├── [1] OrderType Selector (obligatorio, primer paso)
 │     ├── 🍽 Comer aquí  (DINE_IN)
 │     ├── 🥡 Para llevar (TAKEAWAY)
 │     └── 🛵 Delivery    (DELIVERY)
 │
 ├── [2] Reference Input (dinámico según OrderType)
 │     ├── DINE_IN
 │     │     label: "Referencia"
 │     │     placeholder: "Mesa 4"
 │     │     obligatorio: sí
 │     ├── TAKEAWAY
 │     │     label: "Nombre cliente"
 │     │     placeholder: "Roberto"
 │     │     obligatorio: sí
 │     └── DELIVERY
 │           label: "Dirección"
 │           placeholder: "Av. Juárez #123"
 │           obligatorio: sí (deliveryAddress)
 │
 ├── [3] Product selector (igual al flujo actual)
 │     └── ... (sin cambios)
 │
 └── [Guardar pedido] → POST /orders
       ├── body incluye: orderType, reference / deliveryAddress, plates
       ├── success → navigate back / update list
       └── failure → show error
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
 └── [Guardar] deshabilitado si deliveryAddress está vacío
```

#### Comportamiento del placeholder

El placeholder cambia dinámicamente cuando el usuario cambia el OrderType.

El campo se limpia al cambiar de tipo para evitar confusión.

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

---

## Kitchen Flow

### Cola de cocina — KitchenScreen

```txt
KitchenScreen
 ├── Lista de órdenes ordenada por prioridad (desde el backend)
 │     Prioridad actual: UPDATED > PENDING > PREPARING > READY
 │     (ETAPA 4.5.6 planificado: PREPARING > UPDATED > PENDING > READY)
 │
 └── OrderCard por cada orden activa
       ├── Encabezado
       │     ├── Identificador de pedido (tableNumber / reference — ETAPA 4.6)
       │     ├── Estado (badge)
       │     └── Timestamp
       ├── Lista de plates e items
       │     ├── Items nuevos (isNew = true) → highlight verde
       │     └── Items originales → sin highlight
       └── Acciones
             ├── PENDING | UPDATED → [Marcar preparando]  → PATCH /orders/:id/status PREPARING
             ├── PREPARING         → [Marcar listo]       → PATCH /orders/:id/status READY
             └── READY             → [Entregado]          → PATCH /orders/:id/status DELIVERED
```

### Kitchen OrderCard — ETAPA 4.6 (planificado)

El encabezado del OrderCard mostrará el badge de tipo con emoji:

```txt
OrderCard header (ETAPA 4.6)
 ├── DINE_IN   → 🍽 Mesa 4
 ├── TAKEAWAY  → 🥡 Roberto
 └── DELIVERY  → 🛵 Av. Juárez #123
```

Sin texto adicional. Sin etiquetas redundantes.

El cocinero identifica la modalidad a distancia con solo ver el emoji.

### Kitchen Dashboard — KitchenDashboardScreen

Vista horizontal optimizada para tablets.

```txt
KitchenDashboardScreen
 ├── FlatList horizontal de órdenes
 ├── Filtro: excluye DELIVERED y CANCELLED
 └── OrderCard compacto con acciones inline
```

### isNew Highlight Rules

```txt
item.isNew === true && order.status === 'UPDATED'   → verde
item.isNew === true && order.status === 'PREPARING' → verde
item.isNew === true && order.status === 'READY'     → no verde (isNew ya fue limpiado por el servidor)
item.isNew === false → sin highlight
```

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

*Última actualización: ETAPA 4.5.3 (diseño ETAPA 4.6 incluido)*
