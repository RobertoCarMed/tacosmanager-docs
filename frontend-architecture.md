# TacosManager — Frontend Architecture

Version: 1.0
Última actualización: ETAPA 4.5.3

---

## Overview

El frontend es una aplicación **React Native** con TypeScript.

Plataformas objetivo:
- Android (primario)
- Tablets de 10 pulgadas (cocina)
- Teléfonos (meseros)

Stack principal:
- React Native
- TypeScript
- Redux Toolkit (estado global de órdenes)
- React Navigation (navegación)
- Axios (HTTP via apiClient)
- AsyncStorage (persistencia de token)
- Socket.IO client (realtime — ETAPA 4.5.4)
- Firebase Storage (imágenes de productos — temporal, sin endpoint de upload en backend)

---

## Estructura de carpetas

```txt
src/
├── config/
│   └── env.ts                          ← variables de entorno (API URL, etc.)
├── features/
│   ├── auth/
│   │   ├── context/AuthContext.tsx     ← AuthProvider, signIn, signOut
│   │   ├── hooks/
│   │   │   ├── useLogin.ts
│   │   │   └── useRegister.ts
│   │   ├── screens/
│   │   │   ├── LoginScreen.tsx
│   │   │   └── RegisterScreen.tsx
│   │   ├── services/authService.ts
│   │   └── types.ts
│   ├── kitchen/
│   │   ├── components/OrderCard.tsx    ← KDS order card
│   │   └── screens/
│   │       ├── KitchenScreen.tsx       ← cola de cocina principal
│   │       └── KitchenDashboardScreen.tsx
│   ├── orders/
│   │   ├── hooks/
│   │   │   ├── useOrders.ts
│   │   │   ├── useCreateOrder.ts
│   │   │   └── useEditOrder.ts
│   │   ├── screens/
│   │   │   ├── CreateOrderScreen.tsx
│   │   │   └── EditOrderScreen.tsx
│   │   ├── services/ordersService.ts
│   │   └── store/ordersSlice.ts
│   └── products/
│       ├── hooks/
│       │   ├── useProducts.ts
│       │   ├── useCreateProduct.ts
│       │   └── useEditProduct.ts
│       ├── screens/
│       │   ├── CreateProductScreen.tsx
│       │   └── EditProductScreen.tsx
│       └── services/productService.ts
├── services/
│   ├── api/client.ts                   ← instancia axios (apiClient)
│   ├── realtime/socketService.ts       ← singleton Socket.IO manager
│   └── storage/tokenStorage.ts        ← AsyncStorage token persistence
├── shared/
│   ├── components/OrderCard.tsx        ← shared order card (waiter view)
│   └── types/domain.ts                ← tipos de dominio compartidos
└── store/
    ├── hooks.ts
    └── store.ts                        ← Redux store
```

---

## Auth Architecture

```txt
AppProviders
 └── AuthProvider (AuthContext)
       ├── restoreSession() on mount → GET /auth/me
       ├── signIn(user, taqueria)    → called by useLogin / useRegister
       └── signOut()                 → clears token + context

useLogin
 ├── authService.login(email, password) → POST /auth/login
 └── signIn(user, taqueria)

useRegister
 ├── authService.registerDiscoverTaqueria(values) → POST /auth/register (Phase 1)
 ├── authService.registerJoinTaqueria(values, restaurantCode) → POST /auth/register (Phase 2A)
 ├── authService.registerCreateTaqueria(values) → POST /auth/register (Phase 2B)
 └── signIn(user, taqueria)
```

### Token Management

```txt
Login / Register success
      ↓
authService.applyToken(accessToken)
      ├── memoryToken = accessToken
      └── apiClient.defaults.headers.Authorization = "Bearer <token>"
      ↓
tokenStorage.setToken(accessToken)   ← AsyncStorage
      ↓
AuthContext.signIn(user, taqueria)   ← context update → navigation

App start
      ↓
tokenStorage.getToken()              ← AsyncStorage read
      ↓
apiClient.defaults.headers.Authorization = "Bearer <token>"
      ↓
GET /auth/me
      ├── success → signIn(user, taqueria)
      └── failure → clearToken() + removeToken() → Login screen
```

### Navigation after auth

```txt
AuthContext.user === null  →  AuthStack (Login / Register)
user.role === "cook"       →  KitchenStack
user.role === "waiter"     →  WaiterStack
```

### Role Mapping

```txt
API (backend)   →   Frontend (app)
"WAITER"        →   "waiter"
"COOK"          →   "cook"
```

---

## Products Architecture

```txt
useProducts(taqueriaId)
 └── productService.subscribeToProducts(taqueriaId, onData, onError)
       ├── onData(cached) immediately if cache hit
       ├── GET /products → fresh data → onData(products)
       └── returns cancellation function

useCreateProduct
 ├── uploadProductImage(imageUri) → Firebase Storage → imageUrl
 └── productService.createProduct(payload) → POST /products

useEditProduct
 ├── useProducts(taqueriaId) → product list
 ├── uploadProductImage(newImageUri) → Firebase Storage → imageUrl
 └── productService.updateProduct(payload) → PATCH /products/:id

productService
 ├── API calls via apiClient (axios, JWT auto-injected)
 ├── in-memory cache (Map<taqueriaId, Product[]>, sorted by name)
 └── Firebase Storage (image uploads only — temporal, ETAPA 4.5.5 lo elimina)
```

---

## Orders Architecture

```txt
useOrders(options)
 └── ordersService.subscribeToOrders({ dateFilter, taqueriaId }, onData, onError)
       ├── GET /products (cache warm — parallel, cache-first)
       ├── GET /orders → filter client-side según dateFilter
       │     ├── 'active' → excluye DELIVERED y CANCELLED (sin límite de fecha)
       │     ├── 'today'  → createdAt >= inicio del día actual
       │     ├── '7d'     → createdAt >= hace 7 días
       │     ├── '1m'     → createdAt >= hace 1 mes
       │     └── '3m'     → createdAt >= hace 3 meses
       ├── mapApiOrder() → resolves product name/price/complements from cache
       └── returns cancellation function

useCreateOrder
 ├── local NewOrderItem { productId, name, price, quantity, selectedComplements }
 └── ordersService.createOrder({ tableNumber, plates[{ plateNumber, items[{ productId, quantity, selectedComplements }] }] })
       └── POST /orders

useEditOrder(orderId)
 ├── ordersService.getOrder(orderId) → GET /orders/:id
 └── ordersService.appendPlatesToOrder(orderId, plates[{ plateNumber, items }])
       └── PATCH /orders/:id
           (plateNumber = max(existing) + index + 1)

useOrders.updateOrderStatus
 └── ordersService.updateOrderStatus(orderId, status)
       └── PATCH /orders/:id/status { status }
```

### Redux State (Orders)

```txt
ordersSlice
 ├── state: { orders: Order[], isLoading: boolean, error: string | null }
 ├── setOrders(orders)
 ├── setOrdersLoading(bool)
 ├── setOrdersError(message)
 └── resetOrdersState()
```

---

## Orders Architecture — ETAPA 4.6 (épica — tres subetapas)

### ETAPA 4.6.1 — Backend Schema & API (sin cambios en frontend)

El backend agrega `orderType`, `reference`, `deliveryAddress`.

El frontend recibe estos campos en los payloads REST y realtime desde esta etapa,
pero no los usa aún en la UI hasta ETAPA 4.6.2.

### ETAPA 4.6.2 — Nuevos campos en CreateOrderPayload y Edit

```txt
CreateOrderPayload (ETAPA 4.6.2)
 ├── orderType: 'DINE_IN' | 'TAKEAWAY' | 'DELIVERY'
 ├── reference?: string        ← obligatorio para DINE_IN y TAKEAWAY
 ├── deliveryAddress?: string  ← obligatorio para DELIVERY
 └── plates: [...]
```

### Selector UI en CreateOrderScreen (ETAPA 4.6.2)

```txt
CreateOrderScreen
 ├── OrderTypeSelector
 │     ├── 🍽 Comer aquí  → orderType = DINE_IN
 │     ├── 🥡 Para llevar → orderType = TAKEAWAY
 │     └── 🛵 Delivery    → orderType = DELIVERY
 └── Campo dinámico según tipo
       ├── DINE_IN   → label: "Referencia",     placeholder: "Mesa 4"     (obligatorio)
       ├── TAKEAWAY  → label: "Nombre cliente",  placeholder: "Roberto"    (obligatorio)
       └── DELIVERY  → label: "Dirección",       placeholder: "Av. Juárez #123" (obligatorio)
                       + campo opcional: reference (nombre del cliente)
```

### EditOrderScreen — Edición de tipo (ETAPA 4.6.2)

```txt
EditOrderScreen
 ├── Muestra y permite editar tipo actual
 ├── DINE_IN ↔ TAKEAWAY ↔ DELIVERY (con validaciones por tipo)
 └── Pedido DELIVERY: deliveryAddress visible completa en el flujo actual
```

### Kitchen OrderCard (ETAPA 4.6.3)

```txt
OrderCard
 └── OrderTypeBadge
       ├── DINE_IN          → 🍽 Mesa 4
       ├── TAKEAWAY         → 🥡 Roberto
       ├── DELIVERY + ref   → 🛵 Roberto - Enviar
       └── DELIVERY sin ref → 🛵 Av. Juárez #123... (truncado)
```

Kitchen NO agrupa por tipo. FIFO y priorización sin cambios.

---

## Shared Domain Types

Archivo: `src/shared/types/domain.ts`

Tipos principales:

```typescript
export type OrderStatus =
  | 'UPDATED' | 'PENDING' | 'PREPARING'
  | 'READY' | 'DELIVERED' | 'CANCELLED';

export type OrderDateFilter = 'active' | 'today' | '7d' | '1m' | '3m';

// ETAPA 4.6.1 (backend) — ETAPA 4.6.2 (frontend UI)
export type OrderType = 'DINE_IN' | 'TAKEAWAY' | 'DELIVERY';

export type OrderItem = { ... };
export type Plate = { ... };
export type Order = { ... };
export type CreateOrderPayload = { ... };
```

---

## Backend Communication

Todos los requests HTTP pasan por `apiClient` (Axios):

```txt
src/services/api/client.ts
 ├── baseURL: env.API_URL
 └── headers.Authorization: "Bearer <token>" (inyectado por authService)
```

Regla: el `taqueriaId` nunca se envía desde el frontend — el backend lo extrae del JWT.

---

## Realtime Architecture (ETAPA 4.5.4)

### Dependencia

`socket.io-client@^4.8.3`

### Estructura

```txt
src/
├── services/
│   └── realtime/
│       └── socketService.ts      ← singleton Socket.IO manager
└── features/
    └── realtime/
        ├── RealtimeProvider.tsx  ← React provider
        └── index.ts
```

### socketService

Singleton que gestiona la conexión Socket.IO.

```txt
socketService
 ├── connect(token)   → crea/reutiliza socket; conecta a APP_CONFIG.baseApiUrl
 ├── disconnect()     → desconecta y limpia listeners
 └── getSocket()      → retorna socket actual o null
```

Reglas:
- Si el socket ya está conectado, `connect()` lo reutiliza.
- `disconnect()` llama `removeAllListeners()` antes de desconectar para evitar leaks.

### RealtimeProvider

Componente React que vive dentro de `AuthProvider` en el árbol de providers.

```txt
AppProviders
 └── AuthProvider
       └── RealtimeProvider   ← nuevo
             └── children (RootNavigator)
```

Ciclo de vida:
- Cuando `user` cambia de `null` → authenticated: conecta socket con token de `authService.getMemoryToken()`
- Cuando `user` cambia a `null` (logout): desconecta socket
- Registra handlers para `order-created`, `order-updated`, `order-status-changed`
- Limpia handlers al desmontar o re-ejecutar (no listeners duplicados)

### Flujo de evento

```txt
Backend emite evento (ej. order-created)
      ↓
socket.on('order-created', handler)
      ↓
handler({ order: ApiOrder })
      ↓
ordersService.parseOrder(order)   ← mapea ApiOrder → Order (resuelve nombres de producto del cache)
      ↓
dispatch(addOrder(mapped))        ← Redux actualizado
      ↓
KitchenScreen re-renderiza con LayoutAnimation
```

### Redux — nuevos reducers

```txt
addOrder(order)    → inserta si el id no existe (idempotente para order-created)
upsertOrder(order) → reemplaza si existe, inserta si no (para order-updated y order-status-changed)
```

### Estrategia REST + Socket.IO

```txt
Pantalla se enfoca
      ↓
useOrders → useFocusEffect → GET /orders (estado completo desde BD)
      ↓
setOrders(orders) → reemplaza todo en Redux

En paralelo (permanente):
Socket.IO recibe eventos → addOrder / upsertOrder → actualizaciones incrementales
```

No se realiza refetch REST después de eventos realtime.

### Reconexión

Socket.IO client tiene reconexión automática habilitada por defecto:
- `reconnectionAttempts: Infinity`
- `reconnectionDelay: 1000ms → 5000ms` (con jitter)

Cada reconexión ejecuta `handleConnection` en el servidor (re-valida JWT, re-une a room).

### Cleanup

`socket.removeAllListeners()` se llama en `socketService.disconnect()`.

`socket.off(event, handler)` se llama en el cleanup del `useEffect` del provider.

---

### Estructura de carpetas actualizada

```txt
src/
├── config/
│   └── env.ts
├── features/
│   ├── auth/
│   ├── kitchen/
│   ├── orders/
│   │   ├── hooks/
│   │   ├── screens/
│   │   ├── services/
│   │   │   └── ordersService.ts    ← parseOrder exportado
│   │   └── store/
│   │       └── ordersSlice.ts      ← addOrder, upsertOrder agregados
│   ├── products/
│   └── realtime/                   ← nuevo
│       ├── RealtimeProvider.tsx
│       └── index.ts
├── services/
│   ├── api/client.ts
│   ├── realtime/                   ← nuevo
│   │   └── socketService.ts
│   └── storage/tokenStorage.ts
├── shared/
└── store/
```

---

*Última actualización: ETAPA 4.5.4*
