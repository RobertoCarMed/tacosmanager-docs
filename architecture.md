# TacosManager Backend Architecture

Version: 1.0

---

# Overview

TacosManager es una plataforma SaaS multi-tenant para la administración operativa de taquerías.

El backend está construido utilizando:

- NestJS
- Prisma ORM
- PostgreSQL
- JWT Authentication
- Docker
- pnpm

La arquitectura sigue principios de:

- Modular Architecture
- Multi-Tenant Isolation
- Domain Driven Design (lightweight)
- Ownership Based Security
- Backend as Source of Truth

---

# System Architecture

```txt
Client (React Native)
        │
        ├── HTTP (REST)          ├── WebSocket (Socket.IO)
        ▼                                ▼
 NestJS API                    NestJS WebSocket Gateway
        │                                │
 ├── Auth Module               ├── RealtimeGateway
 ├── Users Module              ├── RealtimeAuthGuard
 ├── Products Module           └── Rooms: taqueria:<taqueriaId>
 ├── Orders Module
 └── Realtime Module
        │
        ▼
 Prisma ORM
        │
        ▼
 PostgreSQL
```

---

# Multi-Tenant Architecture

Todas las entidades del sistema pertenecen a una taquería.

El aislamiento de datos se realiza mediante:

```txt
taqueriaId
```

Ningún usuario puede acceder a datos de otra taquería.

---

# Tenant Resolution

Identificador visual:

```txt
name
```

Identificador real:

```txt
restaurantCode
```

Ejemplo:

Taquería El Güero

```txt
restaurantCode = TQR-4821
```

---

# Roles

## COOK

Permisos:

- Consultar todos los pedidos de la taquería
- Cambiar estados de pedidos
- Administrar flujo de cocina
- Consultar historial

---

## WAITER

Permisos:

- Crear pedidos
- Consultar sus pedidos
- Editar pedidos propios
- Consultar catálogo

---

# Authentication Architecture

JWT Authentication.

Flujo REST:

```txt
Login
 ↓
JWT (generado por AuthModule → JwtService)
 ↓
Auth Guard
 ↓
Request User Context
 ↓
Ownership Validation
```

Flujo WebSocket:

```txt
socket.handshake.auth.token
 ↓
JwtService.verifyAsync (mismo servicio que REST — provisto por AuthModule)
 ↓
User context → socket.data.user
 ↓
Auto-join taqueria:<taqueriaId>
```

## Fuente de verdad JWT

`AuthModule` es la única fuente de verdad para la configuración JWT del sistema.

```txt
AuthModule
 ├── JwtModule.registerAsync(ConfigService → JWT_SECRET, JWT_EXPIRES_IN)
 ├── exports: [AuthService, JwtModule]
 └── Todos los módulos que necesiten JwtService importan AuthModule
```

`RealtimeModule` importa `AuthModule` — no registra su propio `JwtModule`.
Cualquier cambio futuro en `secret`, `expiresIn`, `issuer` o `algorithm` se aplica automáticamente a REST y Socket.IO.

JWT contiene:

```txt
userId
role
taqueriaId
restaurantCode
```

---

# Core Domain Models

## Taqueria

```txt
id
name
restaurantCode
createdAt
updatedAt
```

---

## User

```txt
id
name
email
passwordHash
role
taqueriaId
createdAt
updatedAt
```

---

## Product

```txt
id
name
price
complements
taqueriaId
createdAt
updatedAt
```

---

## Order

Campos actuales:

```txt
id
type           (OrderType: DINE_IN | TAKEAWAY | DELIVERY)
reference      (nullable — requerido para DINE_IN y TAKEAWAY)
deliveryAddress (nullable — requerido para DELIVERY)
status
revision
priorityTimestamp
waiterId
taqueriaId
createdAt
updatedAt
```

---

## Plate

```txt
id
plateNumber
createdInRevision
isClosed
orderId
createdAt
updatedAt
```

---

## Item

```txt
id
quantity
selectedComplements
notes
isNew
createdInRevision
plateId
productId
createdAt
updatedAt
```

---

# Orders Architecture

Order
 ├── Plate
 │     ├── Item
 │     ├── Item
 │     └── Item
 │
 ├── Plate
 │     ├── Item
 │     └── Item
 │
 └── Plate

---

# Order Editing Strategy

Append Only Editing.

Regla:

Los pedidos NO se modifican.

Se agregan nuevos Plates.

Ejemplo:

Pedido original:

Plate 1
- Taco Pastor
- Taco Asada

Actualización:

Plate 2
- Horchata
- Quesadilla

Plate 1 permanece intacto.

---

# Kitchen Queue Architecture

Flujo oficial (implementado ETAPA 4.5.6.1 ✅):

```txt
PENDING → PREPARING → READY → DELIVERED
```

Estados activos soportados:

```txt
PENDING
PREPARING
READY
DELIVERED
CANCELLED
UPDATED  [DEPRECADO — ETAPA 4.5.6.1]
```

---

# Kitchen Priority

Orden global (implementado ETAPA 4.5.6.1 ✅):

```txt
PREPARING  (trabajo activo del cocinero)
PENDING    (trabajo nuevo a tomar)
READY      (terminado, pendiente de entregar)
DELIVERED
CANCELLED
```

> **Implementado en ETAPA 4.5.6.1:** Ordenamiento activo: `PREPARING > PENDING > READY > DELIVERED > CANCELLED`. `UPDATED` eliminado del flujo operativo (conservado en el enum para registros históricos).

---

# FIFO Policy

Dentro de cada grupo:

First In First Out.

Ejemplo:

Pedido A
12:00

Pedido B
12:05

Resultado:

Pedido A
Pedido B

---

# Revision System

Pedido nuevo:

```txt
revision = 1
```

Actualización:

```txt
revision++
```

Objetivo:

- Auditoría
- Realtime futuro
- Historial de cambios

---

# Highlight System

Los Items agregados posteriormente:

```txt
isNew = true
```

Frontend:

Mostrar en verde independientemente del estado de la orden (PENDING, PREPARING — implementado en ETAPA 4.5.6.2).

Estrategia visual (ETAPA 4.5.6.2): fondo `#E8F5E9` + borde `#C8E6C9` en el ítem cuando `isNew === true`.

Persistencia:

Cualquier estado activo mientras isNew === true.

Desaparición:

READY — el servidor limpia isNew en la misma transacción antes de emitir. Sin items verdes cuando status === READY.

---

# Security Layers

Layer 1

JWT Authentication

---

Layer 2

Role Validation

---

Layer 3

Ownership Validation

---

Layer 4

Tenant Isolation

---

# Environment Configuration (ETAPA 5.0.1 ✅)

`@nestjs/config` (ConfigModule) registrado globalmente en `AppModule`.

Carga de archivos:

```txt
1. .env.${NODE_ENV}   — ej. .env.development, .env.qa, .env.production
2. .env               — fallback
```

Variables requeridas (validadas al arranque):

```txt
DATABASE_URL   — cadena de conexión PostgreSQL
JWT_SECRET     — clave secreta JWT
```

Variables opcionales con defaults:

```txt
NODE_ENV       — development (default)
JWT_EXPIRES_IN — 1d (default)
PORT           — 3000 (default)
CORS_ORIGIN    — * (default)
SOCKET_ORIGIN  — * (default)
```

CORS HTTP: `app.enableCors({ origin: CORS_ORIGIN })` en `main.ts`.

Socket.IO CORS: `ConfiguredSocketIoAdapter` (`src/realtime/socket-io.adapter.ts`) lee `SOCKET_ORIGIN` de ConfigService al iniciar.

Scripts:

```bash
pnpm run start:dev   # NODE_ENV=development
pnpm run start:qa    # NODE_ENV=qa
pnpm run start:prod  # NODE_ENV=production
```

---

# Realtime Architecture Frontend (Etapa 4.5.4 — actualizado ETAPA 4.7 ✅)

```txt
AppProviders
 └── AuthProvider
       └── RealtimeProvider
             ├── socketService.connect(token) → io(baseApiUrl, {auth:{token}, reconnection:true, reconnectionAttempts:Infinity, reconnectionDelayMax:5000, timeout:20000})
             ├── socket.on('connect')              → primera conexión: hasConnectedRef=true; reconexión: GET /orders → setOrders(active)  [4.7.2]
             ├── socket.on('disconnect', reason)   → 'io server disconnect' → signOut()  [4.7.1]
             ├── socket.on('order-created')        → dispatch(addOrder(parseOrder(payload)))
             ├── socket.on('order-updated')        → dispatch(upsertOrder(parseOrder(payload)))
             └── socket.on('order-status-changed') → dispatch(upsertOrder(parseOrder(payload)))
```

Reglas:
- Conexión creada cuando user deja de ser null (post-login).
- Desconexión cuando user vuelve a ser null (logout).
- Listeners registrados con referencias named para cleanup limpio (sin duplicados).
- En reconexión: `GET /orders` automático — resyncIdRef protege contra requests concurrentes.
- No se realiza refetch REST tras eventos realtime normales.
- REST mantiene responsabilidad de carga inicial y sync al re-enfocar pantallas.

---

# Realtime Architecture (Etapa 4.3)

## WebSocket Gateway

Implementado con `@nestjs/websockets` + `socket.io`.

Clase: `RealtimeGateway` en `src/realtime/realtime.gateway.ts`

```txt
Cliente conecta → handleConnection
                      │
              extractToken (handshake.auth.token / Authorization header)
                      │
              jwtService.verifyAsync(token)
                      │
              usersService.findAuthUserById(payload.sub)
                      │
              socket.data.user = { id, name, email, role, taqueriaId, restaurantCode }
                      │
              socket.join(`taqueria:${taqueriaId}`)
```

## Autenticación WebSocket

El JWT utilizado en WebSocket es el mismo que en la API REST.

Fuentes aceptadas para el token (en orden de prioridad):

```txt
1. socket.handshake.auth.token        ← recomendado para React Native
2. socket.handshake.headers.authorization (Bearer <token>)
```

JWT inválido o ausente → `client.disconnect()` inmediato.

## Rooms Multi-Tenant

Formato de room:

```txt
taqueria:<taqueriaId>
```

Ejemplo:

```txt
taqueria:b3e2c1d4-...
```

Todos los usuarios de la misma taquería comparten room.
El aislamiento entre taquerías es garantizado por el JWT — `taqueriaId` viene del token, nunca del cliente.

## RealtimeAuthGuard

Guard para handlers individuales de WebSocket.

```txt
Verifica que socket.data.user exista (seteado en handleConnection).
Lanza WsException('Unauthorized') si no existe.
```

## Eventos Disponibles

| Evento                | Dirección        | Descripción                                         |
|-----------------------|------------------|-----------------------------------------------------|
| `connection`          | cliente → server | Handshake + validación JWT + join room              |
| `disconnect`          | cliente → server | Limpieza de conexión                                |
| `join-taqueria`       | cliente → server | Confirma la room activa del usuario                 |
| `order-created`       | server → room    | Orden nueva creada (POST /orders)                   |
| `order-updated`       | server → room    | Orden actualizada con Append Only (PATCH /orders/:id) |
| `order-status-changed`| server → room    | Estado de orden cambiado (PATCH /orders/:id/status) |

---

# Realtime Architecture (Etapa 4.4)

## Flujo de Emisión de Eventos

```txt
REST Request (WAITER / COOK)
 ↓
OrdersController
 ↓
OrdersService
 ↓
prisma.order.create / update      ← DB es la fuente de verdad
 ↓
Confirm DB persistence
 ↓
realtimeGateway.emit*(taqueriaId, order)
 ↓
server.to(`taqueria:${taqueriaId}`).emit(event, { order })
 ↓
Todos los clientes conectados en la room reciben el evento
```

**Regla invariante:** nunca emitir antes de confirmar persistencia en PostgreSQL.

## Integración OrdersModule → RealtimeModule

```txt
OrdersModule
 ├── imports: [RealtimeModule]
 └── OrdersService
       └── RealtimeGateway (inyectado)

RealtimeModule
 ├── imports: [AuthModule, UsersModule]
 ├── providers: [RealtimeGateway, RealtimeAuthGuard]
 └── exports: [RealtimeGateway]
```

No existe dependencia circular: `RealtimeModule` no importa `OrdersModule`.

## Payload de Eventos

Todos los eventos emiten la orden completa — el frontend no necesita hacer llamadas REST adicionales.

```txt
{
  order: {
    id, taqueriaId, waiterId,
    type, reference, deliveryAddress,
    status, revision, priorityTimestamp,
    createdAt, updatedAt,
    plates: [
      {
        id, plateNumber, isClosed, createdInRevision, createdAt,
        items: [
          {
            id, productId, quantity,
            selectedComplements, notes,
            isNew, createdInRevision, createdAt
          }
        ]
      }
    ]
  }
}
```

## Manejo de Errores en Emisión

Si Socket.IO falla al emitir:

- La transacción de DB **NO** se revierte.
- El error se registra via `Logger.error`.
- La respuesta REST al cliente es exitosa.
- La persistencia en BD tiene prioridad absoluta.

---

# Frontend Architecture (React Native)

## Auth Module — ETAPA 4.5.1

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

authService
 ├── API calls via apiClient (axios)
 ├── token management (applyToken → apiClient.defaults.headers)
 └── tokenStorage (AsyncStorage persistence)
```

## Token Management

```txt
Login / Register success
        ↓
authService.applyToken(accessToken)
        ├── memoryToken = accessToken
        └── apiClient.defaults.headers.Authorization = "Bearer <token>"
        ↓
tokenStorage.setToken(accessToken)  ← AsyncStorage persistence
        ↓
AuthContext.signIn(user, taqueria)  ← context update → navigation

App start
        ↓
tokenStorage.getToken()             ← AsyncStorage read
        ↓
apiClient.defaults.headers.Authorization = "Bearer <token>"
        ↓
GET /auth/me
        ├── success → signIn(user, taqueria)
        └── failure → clearToken() + removeToken() → Login screen

Logout
        ↓
authService.signOut()
        ├── clearToken() → remove Authorization header
        └── tokenStorage.removeToken() ← AsyncStorage clear
        ↓
AuthContext → user = null, taqueria = null → Login screen
```

## Role Mapping

```txt
API (backend)   →   Frontend (app)
"WAITER"        →   "waiter"
"COOK"          →   "cook"
```

## Navigation after auth

```txt
AuthContext.user === null  →  AuthStack (Login / Register)
user.role === "cook"       →  KitchenStack
user.role === "waiter"     →  WaiterStack
```

---

## Products Module — ETAPA 4.5.2

```txt
useProducts(taqueriaId)
 └── productService.subscribeToProducts(taqueriaId, onData, onError)
       ├── onData(cached) immediately if cache hit
       ├── GET /products → fresh data → onData(products)
       └── returns cancellation function (no realtime)

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
 └── Firebase Storage (image uploads only — @react-native-firebase/storage, sin endpoint de upload en backend)
```

## Image Strategy — ETAPA 4.5.2

```txt
createProduct / updateProduct
        ↓
uploadProductImage(imageUri)
        ↓
Firebase Storage → putFile → getDownloadURL → imageUrl
        ↓
POST /products  { name, price, complements, imageUrl }
PATCH /products/:id  { name, price, imageUrl? }
        ↓
NestJS persists imageUrl in PostgreSQL
```

taqueriaId is never sent in the request body — backend extracts it from JWT.

---

## Orders Module — ETAPA 4.5.3

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
       └── PATCH /orders/:id/status { status: "PREPARING" | "READY" | "DELIVERED" | "CANCELLED" }
```

## OrderStatus Values — ETAPA 4.5.3 (actualizado 4.5.6)

API uses UPPERCASE values:

```txt
PENDING    → kitchen priority 2 (objetivo 4.5.6.1)
PREPARING  → kitchen priority 1 (objetivo 4.5.6.1)
READY      → kitchen priority 3 (objetivo 4.5.6.1)
DELIVERED  → filtered out of active kitchen view
CANCELLED  → filtered out of active kitchen view
UPDATED    → [DEPRECADO — ETAPA 4.5.6.1] pre-4.5.6.1 priority 1
```

UPDATED cannot be set manually — backend sets it when plates are appended (pre-4.5.6.1 only).

ETAPA 4.5.6.1: UPDATED reemplazado por mecanismo de seguimiento de cambios independiente del estado.

## Product Name Resolution — ETAPA 4.5.3

API items contain only productId (not name/price).

Resolution strategy:
```txt
subscribeToOrders
 ├── GET /products (parallel, cache-first — warms productService cache)
 └── mapApiOrder
       └── productMap.get(apiItem.productId)
             ├── hit  → item.name = product.name, item.price = product.price
             └── miss → item.name = productId (fallback)
```

---

# OrderType Enum — ETAPA 4.6.1

```txt
enum OrderType {
  DINE_IN
  TAKEAWAY
  DELIVERY
}
```

Clasifica la modalidad de consumo del pedido.

Independiente de OrderStatus.

OrderStatus = etapa de preparación de cocina.
OrderType = modalidad de consumo del pedido.

---

# Order Classification System — Impacto por capa

## Impacto Backend (ETAPA 4.6.1) ✅ COMPLETADA

- Prisma Schema: nuevo enum `OrderType`, campos `type`, `reference`, `deliveryAddress`
- DTOs: validaciones condicionales según `type`
- Servicios y controladores: aplican reglas por tipo
- Realtime payload: incluye los tres nuevos campos
- Migración automática: `tableNumber → reference`, `type = DINE_IN`

## Impacto Frontend — Crear y Editar Pedido (ETAPA 4.6.2) ✅ COMPLETADA

- `CreateOrderScreen`: selector de tipo (3 botones) + campo dinámico por tipo
- `EditOrderScreen`: muestra tipo actual; permite cambiar tipo (DINE_IN ↔ TAKEAWAY ↔ DELIVERY); muestra `deliveryAddress` para DELIVERY
- `useCreateOrder` / `useEditOrder`: gestionan `orderType`, `reference`, `deliveryAddress` con validaciones dinámicas
- `ordersService.appendPlatesToOrder`: acepta `classification?` opcional para cambios de tipo sin nuevos plates
- `domain.ts`: `OrderType`, `reference`, `deliveryAddress` en `Order` y `CreateOrderPayload`
- `OrderCard` (waiter): `getOrderHeaderLabel` muestra emoji + referencia según tipo

## Impacto Kitchen (ETAPA 4.6.3) ✅ COMPLETADA

- `src/shared/utils/orderDisplay.ts`: nuevo helper `getOrderDisplayLabel(order)` con reglas por tipo y truncamiento
- `kitchen/components/OrderCard.tsx`: reemplaza `Mesa {order.table}` con `getOrderDisplayLabel`
- `shared/components/OrderCard.tsx`: ambas variantes (waiter y kitchen) usan `getOrderDisplayLabel`
- DINE_IN: `🍽 {reference}`
- TAKEAWAY: `🥡 {reference}`
- DELIVERY con reference: `🛵 {reference} - Enviar`
- DELIVERY sin reference: `🛵 {deliveryAddress truncada a 20 chars}...`
- No se agrupan pedidos por tipo — el FIFO y la priorización no cambian

## Impacto Realtime

- Los eventos `order-created`, `order-updated`, `order-status-changed` incluirán `orderType`, `reference`, `deliveryAddress` a partir de ETAPA 4.6.1
- El frontend en ETAPA 4.6.2 y 4.6.3 usará estos campos para actualizar el store y la UI

---

# Future Architecture

Etapa 4.5.6.1 ✅ COMPLETADA

Kitchen Queue Refinements (Backend) — UPDATED deprecado. Nuevo flujo: PENDING → PREPARING → READY → DELIVERED. Reglas de modificación condicionales por estado (CASO 1/2/3). Nueva prioridad: PREPARING > PENDING > READY. Mecanismo de seguimiento de cambios independiente del estado.

---

Etapa 4.5.6.2 ✅ COMPLETADA

Kitchen Visualization (Frontend) — `UPDATED` eliminado de `OrderStatus`. `statusPriority` corregido a `PREPARING(1) > PENDING(2) > READY(3)`. Highlight verde por `isNew` en ambos OrderCard (kitchen y shared variante kitchen). Waiter Orders UX sin dependencia de UPDATED.

---

Etapa 4.6 (Épica) ✅ COMPLETADA — Order Classification System:
- 4.6.1 ✅ — Backend Schema & API (completada)
- 4.6.2 ✅ — Frontend Create/Edit Order (completada)
- 4.6.3 ✅ — Kitchen Integration (completada)

---

Etapa 4.7 ✅ COMPLETADA

Realtime Reliability — confiabilidad operativa para producción.

4.7.1 ✅ Socket Reconnect — `socketService` con opciones explícitas de reconexión (`reconnectionAttempts: Infinity`, `reconnectionDelayMax: 5000ms`, `timeout: 20000ms`). Handler `disconnect` → `'io server disconnect'` → `signOut()` automático. Sin listeners duplicados.

4.7.2 ✅ Resync After Reconnect — Handler `connect` en `RealtimeProvider`. Primera conexión excluida (`hasConnectedRef`). Reconexión → `GET /orders` → `setOrders(active)`. Protección anti-concurrencia via `resyncIdRef`.

4.7.3 ✅ Multi-device Validation — Validado con Kitchen + Waiters + múltiples dispositivos. Order Classification (DINE_IN, TAKEAWAY, DELIVERY) end-to-end. Consistencia eventual garantizada.

---

Etapa 5.0 🟡 EN PROGRESO

MVP Launch — despliegue productivo en Railway + Play Store.

5.0.1 ✅ Environment Strategy — Backend: `@nestjs/config` global, `ConfigModule.forRoot`, `ConfiguredSocketIoAdapter`, CORS configurable, validación al arranque, scripts `start:dev/qa/prod`. Frontend: `react-native-config` con `API_URL`, `SOCKET_URL`, `ENVIRONMENT`. Ambientes DEV/QA/PROD operativos. Ver docs/roadmap.md ETAPA 5.0.1.

5.0.2 🟡 Backend Deployment — EN PROGRESO. Production Readiness Audit completada: health check (`GET /health`), dotenv eliminado, socket.io-client a devDeps, PrismaService simplificado, postinstall prisma generate, railway.json creado. Pendiente: provisionar Railway QA, migrar DB, smoke test.

5.0.3 ✅ Mobile Release Pipeline — COMPLETADA (2026-05-27).

5.0.3.1 ✅ Android Flavors — `productFlavors` (development/qa/production) en `android/app/build.gradle`. `project.ext.envConfigFiles` mapea cada variante a su `.env.*`. Flavor source sets para `app_name` diferenciado (TacosManager Dev / QA / TacosManager). applicationId: `.dev` / `.qa` / sin suffix. Scripts npm: `android:dev`, `android:qa`, `android:prod`, `build:android:qa`, `build:android:prod`.

5.0.3.2 ✅ Build Automation — Scripts compuestos `build:qa` y `build:prod` (lint → typecheck → Gradle release). Scripts `typecheck` (`tsc --noEmit`), `clean`/`clean:android` (`gradlew clean`). Pipeline: 0 errores TypeScript + 0 errores ESLint requeridos antes de generar artefacto. Correcciones lint preexistentes aplicadas (import unused en `auth/types.ts`, dep innecesaria en `useOrders.ts`).

5.0.3.3 ✅ Mobile CI/CD — `.github/workflows/mobile-ci.yml`. Job 1 (`validate-and-build-qa`): todos los triggers → lint + typecheck + assembleQaRelease, APK artifact en main. Job 2 (`build-production`): solo main, después de Job 1 → bundleProductionRelease, AAB artifact. Java 17 + Node LTS + Gradle cache. Secrets: `KEYSTORE_PASSWORD`, `KEY_PASSWORD`. Scripts corregidos: `./gradlew` (Linux compatible).

---

Etapa 5.0.4 ✅ COMPLETADA (2026-05-29)

CI/CD Automation — pipeline CI/CD completo para Mobile y Backend, branch protection, convenciones y runbooks operativos.

5.0.4.1 ✅ Mobile Pipeline Optimization — `.github/workflows/mobile-ci.yml` reestructurado en 3 jobs: `Mobile • Lint & TypeCheck` → `Mobile • Build QA APK` → `Mobile • Build Production AAB`. Estrategia por rama: PRs y push a dev → solo lint+typecheck; push a qa → APK QA; push a main → pipeline completo. GitHub Repository Variables para URLs. Validado 2026-05-28. Ver `docs/cicd-mobile.md`.
5.0.4.2 ✅ Backend CI Pipeline — `.github/workflows/backend-ci.yml`. Job `validate` (lint + build + prisma validate) en todos los triggers. Job `health-check-qa` solo en `push → qa`. `DATABASE_URL` dummy en CI. Ver `docs/cicd-backend.md`.
5.0.4.3 ✅ Branch Protection & Status Checks — GitHub Rulesets activos en dev/qa/main para ambos repositorios. Reglas: PR required, status checks, block force pushes, restrict deletions. Ver `docs/cicd-governance.md`.
5.0.4.4 ✅ CI/CD Conventions & Documentation — `docs/cicd-strategy.md` (commits, PRs, releases, hotfix, IA), `docs/contributing.md` (onboarding), `docs/deployment-runbook.md` (deploy, rollback, emergencias).

Flujo CI/CD objetivo post-5.0.4:

```txt
PR abierto (→ dev / qa / main)
  Mobile:  lint → typecheck → build:qa  ──→ ✅/❌ Status Check
  Backend: lint → build → prisma validate ──→ ✅/❌ Status Check

Push a qa
  Mobile:  validate + build:qa (APK artifact)
  Backend: validate + Backend • Health Check QA

Push a main
  Mobile:  validate + build:qa (APK artifact) → build:prod (AAB artifact)
  Backend: validate  [Production Health Check — pendiente infraestructura]
```

No incluye: deploy automático, Play Store publishing, Fastlane, Docker registry, Kubernetes, Terraform, Sentry.

Estrategia y costos: docs/business-model.md

---

Etapa 6.0 ⬜ FUTURO

Post Launch Features — QR Ordering, Analytics, Advanced Delivery, Self Ordering.

---

# Backend CI/CD

Etapa: 5.0.4.2 ✅ COMPLETADA (2026-05-28)

---

## Archivo

```txt
.github/workflows/backend-ci.yml
```

---

## Flujo de ramas

```txt
feature/*
    ↓  (PR → dev)
   dev
    ↓  (PR → qa)
   qa
    ↓  (PR → main)
  main
```

---

## Triggers y jobs

| Evento | Rama destino | Jobs ejecutados |
|--------|-------------|-----------------|
| `pull_request` | `dev` | validate |
| `pull_request` | `qa` | validate |
| `pull_request` | `main` | validate |
| `push` | `dev` | validate |
| `push` | `qa` | validate → health-check-qa |
| `push` | `main` | validate |

---

## Job: validate

```txt
pnpm install --frozen-lockfile
pnpm lint       (ESLint)
pnpm build      (nest build — TypeScript completo)
prisma validate (schema.prisma sin conexión a BD)
```

Variable de entorno: `DATABASE_URL=postgresql://prisma:prisma@localhost:5432/ci_dummy`

La `DATABASE_URL` dummy es necesaria porque `postinstall` ejecuta `prisma generate`, que carga `prisma.config.ts`. La función `env('DATABASE_URL')` lanza `PrismaConfigEnvError` si la variable no está definida, incluso sin conexión real.

## Job: health-check-qa

```txt
GET $QA_API_URL/health → valida { status: "ok" }
```

Solo se ejecuta en `push → qa`. Requiere que `validate` haya pasado.

Variable de repositorio GitHub: `QA_API_URL` (no Secret — valor público de Railway QA).

---

## Production Health Check (pendiente)

Trigger: `push → main`
Variable: `PROD_API_URL`
Endpoint: `GET $PROD_API_URL/health`

Placeholder documentado en el workflow. Se activará cuando el ambiente de producción en Railway esté disponible.

---

## Decisiones de diseño

- **Health Check QA en `push → qa`**: semánticamente correcto — ese push es el que promueve código al ambiente QA.
- **Sin tests unitarios en esta etapa**: los 19 tests existentes se incorporarán en una optimización futura.
- **Dos jobs separados**: separan validación de código (siempre) de verificación de ambiente (solo en qa).
- **DATABASE_URL hardcodeada en workflow**: valor fake, auto-documentado, sin credenciales reales — no justifica un Secret.

Ver: docs/business-model.md y docs/roadmap.md

---

End of Document