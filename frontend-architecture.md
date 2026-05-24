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
- Firebase Storage (imágenes de productos — temporal, pendiente eliminación en 4.5.5)

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
       ├── GET /orders → filter by dateFilter client-side
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

## Orders Architecture — ETAPA 4.6 (planificado)

### Nuevos campos en CreateOrderPayload

```txt
CreateOrderPayload (ETAPA 4.6)
 ├── orderType: 'DINE_IN' | 'TAKEAWAY' | 'DELIVERY'
 ├── reference?: string        ← obligatorio para DINE_IN y TAKEAWAY
 ├── deliveryAddress?: string  ← obligatorio para DELIVERY
 └── plates: [...]
```

### Selector UI en CreateOrderScreen

```txt
CreateOrderScreen (ETAPA 4.6)
 ├── OrderTypeSelector
 │     ├── 🍽 Comer aquí  → orderType = DINE_IN
 │     ├── 🥡 Para llevar → orderType = TAKEAWAY
 │     └── 🛵 Delivery    → orderType = DELIVERY
 └── ReferenceInput (dynamic based on orderType)
       ├── DINE_IN   → label: "Referencia",     placeholder: "Mesa 4"
       ├── TAKEAWAY  → label: "Nombre cliente",  placeholder: "Roberto"
       └── DELIVERY  → label: "Dirección",       placeholder: "Av. Juárez #123"
```

### Kitchen OrderCard (ETAPA 4.6)

```txt
OrderCard
 └── OrderTypeBadge
       ├── DINE_IN   → 🍽 + reference
       ├── TAKEAWAY  → 🥡 + reference
       └── DELIVERY  → 🛵 + deliveryAddress
```

---

## Shared Domain Types

Archivo: `src/shared/types/domain.ts`

Tipos principales:

```typescript
export type OrderStatus =
  | 'UPDATED' | 'PENDING' | 'PREPARING'
  | 'READY' | 'DELIVERED' | 'CANCELLED';

// ETAPA 4.6 (planificado)
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

## Realtime Architecture (ETAPA 4.5.4 — planificado)

Ver `docs/backend-realtime.md` para el contrato del servidor.

El frontend se conectará via Socket.IO:

```typescript
const socket = io(BACKEND_URL, {
  auth: { token: accessToken }
});

socket.on('order-created', ({ order }) => { ... });
socket.on('order-updated', ({ order }) => { ... });
socket.on('order-status-changed', ({ order }) => { ... });
```

---

*Última actualización: ETAPA 4.5.3*
