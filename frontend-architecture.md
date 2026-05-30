# TacosManager — Frontend Architecture

Version: 1.6
Última actualización: ETAPA 5.0.3 ✅ Completada — ETAPA 5.0.4 🟡 En Progreso

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
 ├── states: orderType (DINE_IN default), reference, deliveryAddress
 ├── local NewOrderItem { productId, name, price, quantity, selectedComplements }
 └── ordersService.createOrder({ type, reference?, deliveryAddress?, plates[{ plateNumber, items[{ productId, quantity, selectedComplements }] }] })
       └── POST /orders

useEditOrder(orderId)
 ├── ordersService.getOrder(orderId) → GET /orders/:id
 ├── states: orderType, reference, deliveryAddress (synced from existingOrder on load)
 └── ordersService.appendPlatesToOrder(orderId, plates[{ plateNumber, items }], classification?)
       └── PATCH /orders/:id
           (plateNumber = max(existing) + index + 1)
           (classification sent only when type/reference/deliveryAddress changed)

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

### ETAPA 4.6.1 — Backend Schema & API ✅ COMPLETADA

El backend agregó `type` (OrderType), `reference`, `deliveryAddress`.

El frontend recibe estos campos en los payloads REST y realtime.

### ETAPA 4.6.2 — Nuevos campos en CreateOrderPayload y Edit ✅ COMPLETADA

```txt
CreateOrderPayload
 ├── type: 'DINE_IN' | 'TAKEAWAY' | 'DELIVERY'
 ├── reference?: string        ← obligatorio para DINE_IN y TAKEAWAY
 ├── deliveryAddress?: string  ← obligatorio para DELIVERY; opcional reference para nombre cliente
 └── plates: [...]
```

### Selector UI en CreateOrderScreen ✅ COMPLETADA

```txt
CreateOrderScreen
 ├── OrderTypeSelector (3 Pressable buttons)
 │     ├── 🍽 Comer aquí  → type = DINE_IN
 │     ├── 🥡 Para llevar → type = TAKEAWAY
 │     └── 🛵 Delivery    → type = DELIVERY
 └── Campo dinámico según tipo
       ├── DINE_IN   → label: "Referencia",     placeholder: "Mesa 4"     (obligatorio)
       ├── TAKEAWAY  → label: "Nombre quien recogerá", placeholder: "Roberto" (obligatorio)
       └── DELIVERY  → label: "Dirección",       placeholder: "Av. Juárez #123" (obligatorio)
                       + campo opcional: reference (nombre del cliente que recibe)
```

### EditOrderScreen — Edición de tipo ✅ COMPLETADA

```txt
EditOrderScreen
 ├── Muestra tipo actual y permite editarlo (selector 3 opciones)
 ├── DINE_IN ↔ TAKEAWAY ↔ DELIVERY (validaciones dinámicas por tipo)
 ├── Pedido DELIVERY: deliveryAddress visible completa + campo opcional de reference
 └── canSave = isClassificationValid && (classificationChanged || hasNewItems)
```

### OrderCard waiter variant ✅ COMPLETADA

```txt
getOrderHeaderLabel(order)
 ├── DELIVERY  → 🛵 deliveryAddress (o reference, o tableNumber como fallback)
 ├── TAKEAWAY  → 🥡 reference (o tableNumber como fallback)
 └── DINE_IN   → 🍽 reference (o tableNumber como fallback)
```

### Kitchen OrderCard — getOrderDisplayLabel (ETAPA 4.6.3) ✅ COMPLETADA

```txt
src/shared/utils/orderDisplay.ts → getOrderDisplayLabel(order)
  ├── DINE_IN          → 🍽 {reference}
  ├── TAKEAWAY         → 🥡 {reference}
  ├── DELIVERY + ref   → 🛵 {reference} - Enviar
  └── DELIVERY sin ref → 🛵 {deliveryAddress truncada a 20 chars}...
```

Helper importado por:
- `src/features/kitchen/components/OrderCard.tsx` (KitchenScreen — paginación horizontal, 2 tarjetas por página)
- `src/shared/components/OrderCard.tsx` (KitchenDashboardScreen + WaiterOrdersScreen)

Kitchen NO agrupa por tipo. FIFO y priorización sin cambios.

---

## Shared Domain Types

Archivo: `src/shared/types/domain.ts`

Tipos principales:

```typescript
// ETAPA 4.5.6.2: UPDATED eliminado del tipo
export type OrderStatus =
  | 'PENDING' | 'PREPARING'
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
 ├── connect(token)   → crea/reutiliza socket; conecta a APP_CONFIG.socketUrl
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
- Cuando `user` cambia a `null` (logout): desconecta socket, resetea `hasConnectedRef`
- Registra handler `connect`: primera conexión → marca `hasConnectedRef = true`; reconexión → resync órdenes (ETAPA 4.7.2)
- Registra handlers para `order-created`, `order-updated`, `order-status-changed`
- Registra handler `disconnect`: si reason === `'io server disconnect'` → llama `signOut()` (ETAPA 4.7.1)
- Limpia todos los handlers al desmontar o re-ejecutar (no listeners duplicados)

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

### Reconexión (ETAPA 4.7.1)

`socketService.connect()` define opciones explícitas:

```txt
reconnection: true
reconnectionAttempts: Infinity
reconnectionDelay: 1000ms
reconnectionDelayMax: 5000ms
timeout: 20000ms
```

Cada reconexión ejecuta `handleConnection` en el servidor (re-valida JWT, re-une a room automáticamente).

Razón disconnect `'io server disconnect'` = servidor rechazó la conexión (JWT expirado o inválido) → `signOut()` en `RealtimeProvider` redirige al login.

Razones `'transport close'` y `'ping timeout'` = pérdida de red → Socket.IO reintenta reconexión automáticamente.

### Resync After Reconnect (ETAPA 4.7.2)

Al reconectar exitosamente, `RealtimeProvider` recupera el estado de órdenes perdido durante la desconexión.

```txt
Socket emite 'connect' (reconexión)
      ↓
onConnect() — hasConnectedRef.current === true → reconexión detectada
      ↓
resyncId = ++resyncIdRef.current
      ↓
resyncOrders(id): GET /orders
      ↓
Si id === resyncIdRef.current (no hay resync más reciente):
      ↓
Filtrar activos (excluir DELIVERED + CANCELLED)
      ↓
dispatch(setOrders(active)) → Redux actualizado con estado fresco
```

Refs utilizadas:
- `hasConnectedRef` — distingue primera conexión (skip resync) de reconexiones (trigger resync)
- `resyncIdRef` — protección anti-concurrencia: si múltiples `connect` se disparan antes de que el fetch complete, solo el más reciente actualiza el store

Comportamiento de filtro en resync:
- Usa filtro `'active'` (PENDING, PREPARING, READY) — el estado operacional de la taquería
- Pedidos DELIVERED / CANCELLED no se incluyen (no son operacionales)
- Si un usuario tenía un filtro histórico abierto (7d, 1m), `useFocusEffect` lo restaura al navegar

Productos NO se resincronizan:
- No existen eventos realtime para productos
- El cache de `productService` está caliente desde el inicio de sesión
- `ordersService.parseOrder()` resuelve nombres correctamente desde el cache existente

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

---

## Kitchen Visualization — ETAPA 4.5.6.2 ✅ COMPLETADA

Adaptación de la Kitchen UI tras la implementación de ETAPA 4.5.6.1.

Requiere: ETAPA 4.5.6.1 completada ✅

### Cambios implementados en KitchenScreen

```txt
KitchenScreen (ETAPA 4.5.6.2)
 ├── Orden de prioridad actualizado: PREPARING(1) > PENDING(2) > READY(3)
 │     UPDATED eliminado de statusPriority
 │
 └── OrderCard — visualización de items nuevos
       ├── isNew === true
       │     → fondo verde (#E8F5E9) + borde (#C8E6C9) sobre el ítem
       │     → aplica en PENDING, PREPARING (cualquier estado activo)
       └── isNew === false (o tras pasar a READY)
             → sin highlight
```

### Archivos modificados (4.5.6.2)

```txt
src/shared/types/domain.ts                        ← OrderStatus sin UPDATED ✅
src/features/kitchen/screens/KitchenScreen.tsx    ← statusPriority PREPARING > PENDING > READY ✅
src/features/kitchen/components/OrderCard.tsx     ← UPDATED eliminado de labels/colors/action ✅
src/features/kitchen/screens/KitchenDashboardScreen.tsx ← condición UPDATED eliminada ✅
src/shared/components/OrderCard.tsx               ← highlight isNew en variante kitchen ✅
```

---

---

## Environment Strategy — ETAPA 5.0.1 ✅ COMPLETADA

### Herramienta

`react-native-config@^1.6.1` — inyecta variables de `.env` en tiempo de build.

### Archivos de entorno

```txt
.env              — Ambiente activo por defecto (local dev, gitignoreado)
.env.development  — DEV (Android emulator: 10.0.2.2:3000)
.env.qa           — QA (Railway QA)
.env.production   — PROD (Railway PROD)
.env.example      — Plantilla pública (en git)

Todos gitignoreados excepto .env.example
```

Selección automática por Android flavor: ETAPA 5.0.3.1 ✅ COMPLETADA (ver sección abajo).

### Variables de entorno

| Variable | Descripción |
|----------|-------------|
| `API_URL` | URL base del backend REST (usada por Axios) |
| `SOCKET_URL` | URL del servidor Socket.IO |
| `ENVIRONMENT` | Identificador del ambiente (`development` / `qa` / `production`) |

### Flujo de configuración

```txt
.env.<ambiente>
  └── react-native-config (Config)
        └── src/config/env.ts
              ├── Valida que API_URL, SOCKET_URL, ENVIRONMENT existan
              ├── Lanza error descriptivo si falta alguna variable
              └── Exporta ENV { apiUrl, socketUrl, environment }
                    └── src/shared/constants/app.ts (APP_CONFIG)
                          ├── baseApiUrl  → src/services/api/client.ts (Axios)
                          ├── socketUrl   → src/services/realtime/socketService.ts (Socket.IO)
                          └── environment → disponible para cualquier uso futuro
```

### Validación de variables

`src/config/env.ts` lanza error en startup si alguna variable falta:

```typescript
// Error en startup si falta variable
throw new Error(
  `[TacosManager] Missing required environment variable: ${envVar}\n` +
  'Configure your .env file or run with ENVFILE=.env.<environment>',
);
```

### Separación API_URL / SOCKET_URL

Aunque en todos los ambientes actuales apuntan al mismo host, se mantienen como variables independientes para soportar topologías futuras donde el servidor Socket.IO y el API REST puedan estar en hosts distintos.

---

---

## Android Flavors — ETAPA 5.0.3.1 ✅ COMPLETADA

### productFlavors

Tres flavors definidos en `android/app/build.gradle`:

| Flavor | applicationId | App Name | .env file |
|--------|---------------|----------|-----------|
| `development` | `com.tacosmanager.dev` | TacosManager Dev | `.env.development` |
| `qa` | `com.tacosmanager.qa` | TacosManager QA | `.env.qa` |
| `production` | `com.tacosmanager` | TacosManager | `.env.production` |

### Selección automática de .env

`react-native-config` lee `project.ext.envConfigFiles` en `build.gradle`:

```gradle
project.ext.envConfigFiles = [
    developmentdebug: ".env.development",
    developmentrelease: ".env.development",
    qadebug: ".env.qa",
    qarelease: ".env.qa",
    productiondebug: ".env.production",
    productionrelease: ".env.production",
]
```

El código TypeScript (`src/config/env.ts`) no necesita cambios — `Config.API_URL`, `Config.SOCKET_URL`, `Config.ENVIRONMENT` son inyectados automáticamente por el flavor activo.

### App names por flavor

Cada flavor tiene su propio source set de recursos:

```txt
android/app/src/
├── main/res/values/strings.xml        → "TacosManager"       (production hereda esto)
├── development/res/values/strings.xml → "TacosManager Dev"
└── qa/res/values/strings.xml          → "TacosManager QA"
```

### Variantes Android generadas

```txt
developmentDebug    qaDebug    productionDebug
developmentRelease  qaRelease  productionRelease
```

`debuggableVariants = ["developmentDebug", "qaDebug", "productionDebug"]` — las variantes debug usan Metro; las release bundlean JS.

### Scripts npm

```bash
npm run android:dev    # developmentDebug — Metro, .env.development
npm run android:qa     # qaDebug          — Metro, .env.qa
npm run android:prod   # productionDebug  — Metro, .env.production

npm run build:android:qa    # assembleQaRelease   → APK firmado
npm run build:android:prod  # bundleProductionRelease → AAB para Play Store
```

### Coexistencia en dispositivo

Los tres flavors pueden instalarse simultáneamente porque tienen `applicationId` distinto:

```txt
com.tacosmanager.dev   ← development
com.tacosmanager.qa    ← qa
com.tacosmanager       ← production
```

---

---

## Build Automation — ETAPA 5.0.3.2 ✅ COMPLETADA

### Scripts de calidad

```bash
npm run typecheck   # tsc --noEmit — 0 errores TypeScript requerido
npm run lint        # eslint .     — 0 errores ESLint requerido
```

### Scripts de limpieza

```bash
npm run clean         # alias → clean:android
npm run clean:android # gradlew clean → elimina android/build/ y android/app/build/
```

### Builds compuestos

```bash
npm run build:qa    # lint → typecheck → assembleQaRelease
npm run build:prod  # lint → typecheck → bundleProductionRelease
```

El pipeline falla si lint o typecheck tienen errores — el artefacto no se genera.

### Artefactos

| Script | Artefacto | Ubicación |
|--------|-----------|-----------|
| `build:android:qa` | APK QA release | `android/app/build/outputs/apk/qa/release/app-qa-release.apk` |
| `build:android:prod` | AAB Production | `android/app/build/outputs/bundle/productionRelease/app-production-release.aab` |

---

---

## Mobile CI/CD — ETAPA 5.0.3.3 ✅ COMPLETADA

Workflow: `.github/workflows/mobile-ci.yml`

| Trigger | Jobs | Artefactos |
|---------|------|------------|
| `pull_request` | Validate & Build QA | Ninguno |
| `push → main` | Validate & Build QA + Build Production | APK QA + AAB Production |

### Flujo Pull Request

```txt
checkout → java 17 → node LTS → gradle cache → npm ci
  → create .env.qa → create .env (secrets)
  → lint → typecheck → build:android:qa
Si cualquier paso falla → PR bloqueado
```

### Flujo Push a main

```txt
Job 1 (igual que PR) + upload APK artifact
Job 2 (después de Job 1):
  checkout → setup → npm ci → create .env.production → create .env (secrets)
  → build:android:prod → upload AAB artifact
```

### Descargar artefactos

```txt
GitHub → Actions → workflow run (main) → Artifacts
  app-qa-release-<sha>          → APK QA instalable
  app-production-release-<sha>  → AAB para Play Store
```

### GitHub Secrets necesarios

```txt
KEYSTORE_PASSWORD   → contraseña del keystore (MYAPP_UPLOAD_STORE_PASSWORD)
KEY_PASSWORD        → contraseña de la clave  (MYAPP_UPLOAD_KEY_PASSWORD)
```

Configurar en: `GitHub → Settings → Secrets and variables → Actions → New repository secret`

---

---

## CI/CD Automation — ETAPA 5.0.4 ✅ COMPLETADA (2026-05-29)

La ETAPA 5.0.3 entregó el pipeline Mobile base. La ETAPA 5.0.4 lo extiende y profesionaliza.

### Mobile CI/CD — ETAPA 5.0.4.1 ✅ COMPLETADA

Workflow: `.github/workflows/mobile-ci.yml` — Documentación completa: `docs/cicd-mobile.md`

```txt
Mobile • Lint & TypeCheck    ← todos los triggers (PRs y push a dev/qa/main)
        ↓
Mobile • Build QA APK        ← push a qa y main
        ↓
Mobile • Build Production AAB ← push a main únicamente
```

| Evento | Lint & TypeCheck | Build QA APK | Build Production AAB |
|--------|:---:|:---:|:---:|
| PR → dev / qa / main | ✅ | — | — |
| Push → dev | ✅ | — | — |
| Push → qa | ✅ | ✅ + artifact | — |
| Push → main | ✅ | ✅ + artifact | ✅ + artifact |

**Environment:** `.env.qa` y `.env.production` generados desde GitHub Repository Variables (`QA_API_URL`, `QA_SOCKET_URL`, `PROD_API_URL`, `PROD_SOCKET_URL`). Sin URLs hardcodeadas.

**Artefactos:**

```txt
app-qa-release-<sha>.apk        → push qa y main (30 días)
app-production-release-<sha>.aab → push main (30 días)
```

### Pipeline Backend — ETAPA 5.0.4.2 ✅ COMPLETADA

Ver: repositorio NestJS + `docs/cicd-backend.md`

### Branch Protection — ETAPA 5.0.4.3 ✅ COMPLETADA (2026-05-29)

GitHub Rulesets activos en dev, qa y main — ambos repositorios.

| Repositorio | Required check (PR) | Reglas adicionales |
|-------------|---------------------|--------------------|
| Mobile | `Mobile • Lint & TypeCheck` | PR required · Block force pushes · Restrict deletions |
| Backend | `Backend • Lint, Build & Validate` | PR required · Block force pushes · Restrict deletions |

Quality gates post-merge: APK QA (push a qa/main) · AAB Production (push a main) · Health Check QA (push a qa).

Configuración completa: `docs/cicd-governance.md`

Estrategia de ramas: `docs/branch-strategy.md`

### Relación Mobile ↔ Backend en CI

Pipelines independientes (repos separados). La coordinación es manual: el backend se despliega en Railway y el mobile apunta a las URLs correctas via GitHub Repository Variables.

---

*Última actualización: ETAPA 5.0.4 ✅ COMPLETADA (2026-05-29) — ETAPA 4.5 ✅, ETAPA 4.6 ✅, ETAPA 4.7 ✅, ETAPA 5.0.1 ✅, ETAPA 5.0.3 ✅, ETAPA 5.0.4 ✅ completadas.*
