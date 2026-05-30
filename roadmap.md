# TacosManager Development Roadmap

Version: 1.0

---

# Proyecto

TacosManager es una plataforma SaaS multi-tenant para taquerías.

Objetivo principal:

Permitir a taquerías administrar:

- Productos
- Pedidos
- Cocina
- Historial
- Operación diaria
- Realtime
- Analítica futura

Tecnologías principales:

- NestJS
- Prisma
- PostgreSQL
- Docker
- JWT
- Socket.IO
- React Native

---

# Estado General

## Completado

- Infraestructura Backend
- Autenticación
- Multi-Tenant
- Products Module
- Orders Core CRUD
- Kitchen Queue Logic
- Socket.IO Foundation
- Kitchen Realtime
- 4.5.1 Frontend Authentication Migration
- 4.5.2 Products API Migration
- 4.5.3 Orders API Migration
- 4.5.4 Socket.IO Realtime Integration
- 4.5.5 Firebase Removal & Cleanup
- 4.5.6.1 Backend Queue Rules
- 4.5.6.2 Frontend Kitchen Visualization
- 4.6.1 Backend Schema & API
- 4.6.2 Frontend Create/Edit Order
- 4.6.3 Kitchen Integration
- 4.7.1 Socket Reconnect
- 4.7.2 Resync After Reconnect
- 4.7.3 Multi-device Validation
- 4.7 Realtime Reliability
- 5.0.1 Environment Strategy
- 5.0.3.1 Android Flavors
- 5.0.3.2 Build Automation
- 5.0.3.3 Mobile CI/CD
- 5.0.3 Mobile Release Pipeline ✅
- 5.0.4.1 Mobile Pipeline Optimization ✅
- 5.0.4.2 Backend CI Pipeline ✅
- 5.0.4.3 Branch Protection & Status Checks ✅

## En Progreso

- 5.0 MVP Launch
- 5.0.2 Backend Deployment
- 5.0.4 CI/CD Automation

## Pendiente

- 4.8 History & Filters
- 4.9 Performance Optimization
- 4.10 Product Management Improvements
- 5.0.4.4 CI/CD Conventions & Documentation

## Post-Lanzamiento

- 6.0 Post Launch Features

---

# ETAPA 1
# Backend Foundation

Estado:

✅ COMPLETADA

---

## Objetivos

- Crear backend NestJS
- Configurar PostgreSQL
- Configurar Prisma
- Configurar Docker
- Definir arquitectura base

---

## Entregables

- NestJS inicializado
- PostgreSQL operativo
- Prisma configurado
- Docker funcionando
- Proyecto compilando

---

# ETAPA 2
# Authentication & Multi-Tenant

Estado:

✅ COMPLETADA

---

## Objetivos

Implementar:

- JWT
- Roles
- Ownership
- Multi-Tenant

---

## Entregables

### Usuarios

- COOK
- WAITER

---

### Seguridad

- JWT Authentication
- Role Guards
- Ownership Validation
- Tenant Isolation

---

### Taquerías

- restaurantCode
- Multi-tenant architecture
- Registro inteligente

---

# ETAPA 3
# Products Module

Estado:

✅ COMPLETADA

---

## Objetivos

Administrar catálogo.

---

## Funcionalidades

- Crear producto
- Editar producto
- Consultar producto
- Eliminar producto
- Ownership
- Multi-tenant

---

## Reglas

Máximo:

3 complementos por producto.

---

# ETAPA 4.1
# Orders Core CRUD

Estado:

✅ COMPLETADA

---

## Objetivos

Construir la base de órdenes.

---

## Entidades

### Order

- status
- revision
- priorityTimestamp

---

### Plate

- plateNumber
- createdInRevision
- isClosed

---

### Item

- quantity
- notes
- selectedComplements
- isNew

---

## Funcionalidades

### Crear pedido

POST /orders

---

### Consultar pedidos

GET /orders

---

### Consultar detalle

GET /orders/:id

---

### Editar pedido

PATCH /orders/:id

---

### Actualizar estado

PATCH /orders/:id/status

---

## Reglas

Append Only Editing.

Los pedidos no se modifican.

Se agregan nuevos Plates.

---

# ETAPA 4.2
# Kitchen Queue Logic

Estado:

🟡 EN VALIDACIÓN

---

## Objetivos

Mover toda la lógica de cocina al backend.

Backend como Source Of Truth.

---

## Estados

- PENDING
- PREPARING
- READY
- DELIVERED
- CANCELLED
- UPDATED ← `[DEPRECADO — ETAPA 4.5.6.1]`

> **Nota:** El estado UPDATED fue definido en esta etapa. Su deprecación y reemplazo por un mecanismo de seguimiento de cambios se implementa en ETAPA 4.5.6.1.

---

## Prioridad Global (implementación original)

1. UPDATED
2. PENDING
3. PREPARING
4. READY
5. DELIVERED
6. CANCELLED

> **Nota:** El reordenamiento a PREPARING > PENDING > READY (y la eliminación de UPDATED) se implementa en ETAPA 4.5.6.1.

---

## FIFO

Dentro de cada grupo:

First In First Out.

Ejemplo:

Pedido A 12:00

Pedido B 12:05

Resultado:

Pedido A

Pedido B

---

## Highlight Verde

Nuevos Items:

isNew = true

Visible durante (implementación original):

- UPDATED
- PREPARING

Desaparece:

- READY

> **Nota:** La visualización desacoplada del estado UPDATED se implementa en ETAPA 4.5.6.2.

---

## Revision System

Pedido nuevo:

revision = 1

Actualización:

revision++

---

## createdInRevision

Permite identificar cuándo apareció:

- Plate
- Item

---

## priorityTimestamp

Actualizado cuando:

- Se crea pedido
- Se agregan plates
- Se agregan items

---

# ETAPA 4.3
# Socket.IO Foundation

Estado:

✅ COMPLETADA

---

## Implementado

- `@nestjs/websockets` + `@nestjs/platform-socket.io` + `socket.io` instalados
- `RealtimeGateway` con `OnGatewayConnection` / `OnGatewayDisconnect`
- JWT validado en handshake — conexiones inválidas rechazadas
- Contexto de usuario cargado en `socket.data.user`
- `RealtimeAuthGuard` para handlers individuales
- Room multi-tenant: `taqueria:<taqueriaId>`
- Evento `join-taqueria` implementado
- `IoAdapter` configurado en `main.ts`
- Documentación actualizada

## Archivos

```txt
src/realtime/
├── interfaces/
│   └── authenticated-socket.interface.ts
├── realtime-auth.guard.ts
├── realtime.gateway.ts
└── realtime.module.ts
```

## Rooms

```txt
taqueria:<taqueriaId>
```

---

# ETAPA 4.4
# Kitchen Realtime

Estado:

✅ COMPLETADA

---

## Objetivos

Reemplazar Firebase realtime.

---

## Implementado

### Nuevos archivos

- `src/realtime/interfaces/order-payload.interface.ts`

### Archivos modificados

- `src/realtime/realtime.gateway.ts` — métodos `emitOrderCreated`, `emitOrderUpdated`, `emitOrderStatusChanged`
- `src/realtime/realtime.module.ts` — exporta `RealtimeGateway`
- `src/orders/orders.module.ts` — importa `RealtimeModule`
- `src/orders/orders.service.ts` — emite tras cada operación de BD

### Eventos implementados

order-created → emitido tras POST /orders

order-updated → emitido tras PATCH /orders/:id

order-status-changed → emitido tras PATCH /orders/:id/status

### Regla de persistencia

BD primero → confirmar → emitir WebSocket.

### Resultado

Sin polling.

Sin refresh manual.

Sin Firebase.

Actualización instantánea cocina y meseros.

---

# ETAPA 4.5.1
# Frontend Authentication Migration

Estado:

✅ COMPLETADA

---

## Objetivos

Eliminar Firebase Authentication del frontend.

Reemplazar por autenticación JWT del backend NestJS.

---

## Implementado

- POST /auth/login → Login exclusivo via API
- POST /auth/register (Fase 1 + Fase 2A + Fase 2B) → Registro multi-taquería via API
- GET /auth/me → Session Restore al iniciar la app
- Logout completo: elimina token, limpia contexto, redirige a Login
- Persistencia JWT con AsyncStorage
- AuthContext con signIn, signOut, taqueria
- Mapeo de roles API (WAITER/COOK) → frontend (waiter/cook)
- Manejo de múltiples coincidencias de taquería en el registro
- Firebase Auth eliminado de Login, Register, Session Restore y Logout

---

## Archivos creados

- src/services/storage/tokenStorage.ts
- (dependencia) @react-native-async-storage/async-storage

## Archivos modificados

- src/features/auth/services/authService.ts
- src/features/auth/context/AuthContext.tsx
- src/features/auth/hooks/useLogin.ts
- src/features/auth/hooks/useRegister.ts
- src/features/auth/screens/RegisterScreen.tsx
- src/features/auth/types.ts
- src/shared/types/domain.ts

---

# ETAPA 4.5.2
# Products API Migration

Estado:

✅ COMPLETADA

---

## Objetivos

Migrar módulo de productos de Firestore a la API NestJS.

Mantener Firebase Storage para imágenes.

---

## Implementado

- GET /products → fetchProducts + subscribeToProducts (cache-first, forceRefresh en cada focus)
- POST /products → createProduct (imagen a Firebase Storage → imageUrl al backend)
- PATCH /products/:id → updateProduct (sube nueva imagen a Firebase Storage si aplica)
- DELETE /products/:id → deleteProduct (implementado en servicio, pendiente de UI)
- Firestore eliminado del módulo Products
- Cache en memoria conservado (keyed por taqueriaId)
- subscribeToProducts migrado a fetch con cancellation flag (useProducts.ts sin cambios)
- taqueriaId extraído del JWT por el backend (no se envía en el body)
- Firebase Storage conservado para imágenes de productos

## Archivos modificados

- src/features/products/services/productService.ts

## Archivos sin cambios

- src/features/products/hooks/useProducts.ts
- src/features/products/hooks/useCreateProduct.ts
- src/features/products/hooks/useEditProduct.ts
- src/features/products/screens/CreateProductScreen.tsx
- src/features/products/screens/EditProductScreen.tsx
- src/features/products/types.ts

---

# ETAPA 4.5.3
# Orders API Migration

Estado:

✅ COMPLETADA

---

## Objetivos

Migrar módulo de órdenes de Firestore a la API NestJS.

---

## Implementado

### Archivos creados / modificados

- `src/shared/types/domain.ts` — OrderStatus UPPERCASE, OrderItem con productId/selectedComplements, Plate con plateNumber, Order con tableNumber + alias table
- `src/features/orders/services/ordersService.ts` — Reescrito completo, sin Firestore. Implementa createOrder, getOrder, appendPlatesToOrder, subscribeToOrders, updateOrderStatus usando apiClient
- `src/features/orders/hooks/useOrders.ts` — Eliminado taqueriaId/user.id de llamadas al servicio
- `src/features/orders/hooks/useCreateOrder.ts` — NewOrderItem con productId, saveOrder construye payload API con tableNumber + plateNumber
- `src/features/orders/hooks/useEditOrder.ts` — getOrder sin taqueriaId, appendPlatesToOrder con cálculo de plateNumber
- `src/features/kitchen/components/OrderCard.tsx` — Estados UPPERCASE
- `src/features/kitchen/screens/KitchenScreen.tsx` — statusPriority UPPERCASE, filtro DELIVERED/CANCELLED
- `src/features/kitchen/screens/KitchenDashboardScreen.tsx` — Comparaciones de estado UPPERCASE
- `src/shared/components/OrderCard.tsx` — statusLabels/statusColors UPPERCASE

### Endpoints consumidos

- `POST /orders` — Crear pedido
- `GET /orders` — Listar pedidos (con filtro de fecha client-side)
- `GET /orders/:id` — Obtener pedido individual
- `PATCH /orders/:id` — Agregar plates (append-only)
- `PATCH /orders/:id/status` — Cambiar estado

### Reglas respetadas

- Backend extrae taqueriaId del JWT — nunca se envía en el body
- Backend es fuente de verdad para isNew, revision, createdInRevision
- Frontend NO genera lógica de kitchen ordering — respeta el orden de la API
- Append-only editing preservado
- Product cache se pre-carga en paralelo con orders para resolver nombres de productos en cocina

---

# ETAPA 4.5.4
# Socket.IO Realtime Integration

Estado:

✅ COMPLETADA

---

## Objetivos

Conectar frontend a Socket.IO del backend.

---

## Implementado

### Nuevos archivos

- `src/services/realtime/socketService.ts` — singleton Socket.IO manager (connect, disconnect, getSocket)
- `src/features/realtime/RealtimeProvider.tsx` — React provider que conecta el socket y sincroniza Redux
- `src/features/realtime/index.ts` — barrel export

### Archivos modificados

- `src/features/orders/store/ordersSlice.ts` — reducers `addOrder` y `upsertOrder` para actualizaciones incrementales
- `src/features/orders/services/ordersService.ts` — tipos `ApiOrder`, `ApiPlate`, `ApiItem` exportados; método `parseOrder` en el service
- `src/app/AppProviders.tsx` — `RealtimeProvider` integrado dentro de `AuthProvider`

### Dependencia instalada

- `socket.io-client@^4.8.3` (compatible con servidor `socket.io@^4.8.3`)

### Eventos integrados

- `order-created` → `addOrder` (inserta si no existe)
- `order-updated` → `upsertOrder` (reemplaza o inserta)
- `order-status-changed` → `upsertOrder` (reemplaza o inserta)

### Estrategia

- REST: carga inicial + sync al enfocar pantalla (sin cambios)
- Socket.IO: actualizaciones incrementales en tiempo real
- No se realiza refetch tras eventos realtime
- El payload del socket se mapea con `ordersService.parseOrder()` (misma lógica que REST)

---

## Funcionalidades

- Conexión Socket
- Reconnection
- Event listeners
- Store synchronization

---

## Resultado esperado

Actualización instantánea entre:

- Cocina
- Meseros

---

# ETAPA 4.5.5
# Firebase Removal & Cleanup

Estado:

✅ COMPLETADA

---

## Objetivos

Eliminar Firebase Auth y Firestore del proyecto frontend. Conservar Firebase Storage para imágenes de productos.

---

## Implementado

### Archivos eliminados

- `src/services/firebase/config.ts` — exportaba `firebaseModularAuth` y `firestoreModularDb` (Auth + Firestore)
- `src/services/firebase/firestoreOperations.ts` — helpers de Firestore (timeouts, logs, error mapping)
- `src/features/auth/services/taqueriaService.ts` — operaciones Firestore sobre colección `taquerias`
- `src/features/auth/services/userService.ts` — operaciones Firestore sobre colección `users` (incluyendo listener `onSnapshot`)
- `src/shared/constants/firebase.ts` — re-exportaba `firebaseConfig` de ENV (sin consumidores activos)

### Archivos modificados

- `src/services/index.ts` — eliminado `export * from './firebase/config'`
- `src/shared/constants/index.ts` — eliminado `export * from './firebase'`
- `src/features/auth/types.ts` — eliminados tipos legacy: `CreateTaqueriaParams`, `TaqueriaRecord`, `TaqueriaLookupResult`, `CreateUserProfileParams`, `RegisteredUserProfile`
- `src/config/env.ts` — eliminadas variables Firebase de `requiredEnvVars` y objeto `ENV.firebase` (no usados por JS — Firebase nativo se configura vía `google-services.json`)
- `package.json` — eliminadas dependencias `@react-native-firebase/auth@^24.0.0` y `@react-native-firebase/firestore@^24.0.0`

### Dependencias conservadas

- `@react-native-firebase/app@^24.0.0` — requerido como base de Firebase
- `@react-native-firebase/storage@^24.0.0` — requerido para upload de imágenes de productos

### Estado de dependencias Firebase

| Paquete | Antes | Después |
|---|---|---|
| `@react-native-firebase/app` | ✅ | ✅ conservado |
| `@react-native-firebase/auth` | ✅ | ❌ eliminado |
| `@react-native-firebase/firestore` | ✅ | ❌ eliminado |
| `@react-native-firebase/storage` | ✅ | ✅ conservado |

### Nativa Android — sin cambios

- `android/build.gradle`: `classpath("com.google.gms:google-services")` — conservado (requerido por Storage)
- `android/app/build.gradle`: `apply plugin: 'com.google.gms.google-services'` — conservado (requerido por Storage)

### Fuentes de verdad actuales

| Función | Antes (Firestore era) | Ahora |
|---|---|---|
| Autenticación | Firebase Auth + Firestore | NestJS JWT (`POST /auth/login`) |
| Perfil de usuario | Firestore `users` collection | NestJS API (`GET /auth/me`) |
| Taquerías | Firestore `taquerias` collection | NestJS API (JWT payload) |
| Pedidos | Firestore (migrado en 4.5.3) | NestJS API + PostgreSQL |
| Productos | Firestore (migrado en 4.5.2) | NestJS API + PostgreSQL |
| Realtime | Firebase (no implementado) | Socket.IO (ETAPA 4.5.4) |
| Imágenes | Firebase Storage | Firebase Storage (conservado) |

### Pasos adicionales requeridos por el desarrollador

Después de hacer `git pull` y `npm install`:

1. Limpiar la build de Android:

```bash
cd android && ./gradlew clean && cd ..
```

2. Rebuildar la app:

```bash
npx react-native run-android
```

El autolinking de React Native 0.84 eliminará automáticamente los módulos nativos de Auth y Firestore al hacer el rebuild.

---

# ETAPA 4.5.6
# Kitchen Queue Refinements

Estado:

✅ COMPLETADA (dividida en dos subetapas independientes, ambas completadas)

---

## División de la Etapa

La etapa 4.5.6 creció en alcance al análisis funcional y fue dividida para:

- Facilitar implementación incremental por capa
- Facilitar pruebas independientes de backend y frontend
- Reducir riesgo de regresión
- Separar reglas de negocio de UX
- Mejorar trazabilidad en el roadmap

```txt
4.5.6 Kitchen Queue Refinements
 ├── 4.5.6.1 Backend Queue Rules
 └── 4.5.6.2 Frontend Kitchen Visualization
```

4.5.6.1 ✅ completada. 4.5.6.2 ✅ completada.

---

## Razón del Cambio (contexto compartido)

El estado `UPDATED` generaba problemas estructurales:

- Ruptura de FIFO: pedidos PENDING saltaban por delante de otros PENDING al modificarse
- Priorización no determinista: la posición del pedido cambiaba por acciones del mesero, no del cocinero
- Ambigüedad en cocina: UPDATED y PENDING compartían la misma acción (Marcar preparando)
- Complejidad innecesaria en Realtime: el estado cambiaba sin intervención del cocinero
- UX degradada: el cocinero veía pedidos reorganizarse sin haberlos tocado

La decisión es **deprecar completamente el estado `UPDATED`** y reemplazarlo por un mecanismo de seguimiento de cambios independiente del estado.

---

# ETAPA 4.5.6.1
# Backend Queue Rules

Estado:

✅ COMPLETADA

Requiere: ETAPA 4.6.3 completada ✅

---

## Objetivo

Implementar en el backend las nuevas reglas de negocio para la cola de cocina:

- Deprecación y remoción funcional del estado UPDATED
- Nuevas transiciones de estado al recibir modificaciones
- Mecanismo de seguimiento de cambios independiente del estado
- Nueva prioridad de la cola de cocina
- Contratos API y payloads realtime actualizados

---

## Nuevo Flujo Oficial de Estados

```txt
PENDING → PREPARING → READY → DELIVERED
```

`CANCELLED` disponible como salida en cualquier punto.

`UPDATED` oficialmente deprecado — no forma parte del flujo futuro.

---

## Reglas de Modificación de Pedidos (Append Only)

### CASO 1 — Pedido en PENDING recibe modificación

El pedido permanece en **PENDING**.

`priorityTimestamp` no se actualiza — el pedido conserva su posición FIFO original.

Los productos nuevos se marcan mediante el mecanismo de seguimiento de cambios.

---

### CASO 2 — Pedido en PREPARING recibe modificación

El pedido permanece en **PREPARING**.

No cambia de prioridad ni de posición en la cola.

Los productos nuevos se marcan mediante el mecanismo de seguimiento de cambios.

---

### CASO 3 — Pedido en READY recibe modificación

El pedido **revierte automáticamente a PENDING**.

Cocina debe preparar los productos nuevos antes de marcarlo listo nuevamente.

---

## Mecanismo de Seguimiento de Cambios

Reemplaza al estado UPDATED como señal de modificación.

Mecanismo implementado: **`isNew: boolean` por item**.

- `isNew: true` en todos los items creados por `PATCH /orders/:id` (append)
- `isNew: false` en items creados en la orden original (`POST /orders`)
- `isNew` se limpia a `false` en todos los items al pasar la orden a `READY` (en la misma transacción de BD)
- Independiente del estado de la orden — aplica en PENDING, PREPARING y el revert READY→PENDING (CASO 3)

---

## Nueva Prioridad de Cola de Cocina

```txt
1. PREPARING  — trabajo activo del cocinero
2. PENDING    — trabajo por iniciar, FIFO
3. READY      — listo para entregar
4. DELIVERED  — fuera de la cola activa
5. CANCELLED  — fuera de la cola activa
```

UPDATED eliminado del ordenamiento.

FIFO por `priorityTimestamp ASC` dentro de cada grupo. Las modificaciones a un pedido PENDING no actualizan `priorityTimestamp`.

---

## Impacto en API y Realtime

`PATCH /orders/:id` — comportamiento condicional por estado:

| Estado actual | Status resultante | priorityTimestamp |
|---------------|-------------------|-------------------|
| PENDING       | PENDING           | Sin cambio        |
| PREPARING     | PREPARING         | Actualizado       |
| READY         | PENDING (revert)  | Sin cambio        |

`GET /orders` (COOK) — nuevo orden: PREPARING > PENDING > READY > DELIVERED > CANCELLED.

Payloads realtime `order-updated`: status reflejará el nuevo comportamiento condicional.

---

## Archivos afectados (backend)

- `src/orders/orders.service.ts` — lógica condicional de status al hacer append
- `prisma/schema.prisma` — posible campo de tracking de cambios
- `src/orders/dto/update-order.dto.ts` — si se agrega campo de tracking
- `src/realtime/interfaces/order-payload.interface.ts` — si se agrega campo de tracking al payload

---

## Objetivos de la Subetapa

- Eliminar la ambigüedad del estado UPDATED en el backend
- Restaurar FIFO consistente para pedidos PENDING
- Implementar reglas condicionales de modificación (CASO 1/2/3)
- Actualizar contratos API y payloads realtime
- Documentar el mecanismo de seguimiento de cambios

---

# ETAPA 4.5.6.2
# Frontend Kitchen Visualization

Estado:

✅ COMPLETADA

Requiere: ETAPA 4.5.6.1 completada ✅

---

## Objetivo

Adaptar la interfaz del Kitchen Display System (KDS) para visualizar correctamente los cambios introducidos por ETAPA 4.5.6.1:

- Productos nuevos destacados visualmente en la cola de cocina
- Indicadores visuales independientes del estado de la orden
- Consumo correcto de los nuevos payloads realtime
- Ordenamiento visual actualizado (PREPARING > PENDING > READY)
- UX de cocina y meseros actualizada

---

## Comportamiento Esperado

Los productos agregados después de la creación original del pedido deben diferenciarse visualmente.

El cocinero identifica en segundos qué fue lo último que se agregó al pedido sin necesidad de releer todo el card.

Mecanismos visuales posibles:

- Highlight de fondo verde en el ítem
- Badge o indicador de "nuevo"
- Sección separada "Agregado posteriormente" dentro del card

El indicador visual es independiente del estado: aplica en PENDING, PREPARING, y en el revert desde READY.

---

## Reglas de Visualización

### Highlight de ítem nuevo

```txt
isNew === true (u otro mecanismo de tracking)
  → destacar visualmente en cualquier estado activo
  → aplica en PENDING, PREPARING

isNew === false (o al pasar a READY)
  → sin highlight
```

### Ordenamiento visual en KitchenScreen

```txt
1. PREPARING
2. PENDING
3. READY
```

UPDATED eliminado del ordenamiento del frontend.

### PREPARING permanece visible

Los pedidos en PREPARING deben permanecer en la parte superior de la cola durante las modificaciones y el tiempo de preparación.

### FIFO preservado

El frontend respeta el orden que entrega el backend. No reordena localmente.

---

## Impacto en Waiter Orders

Los meseros también pueden beneficiarse de indicadores visuales al ver sus pedidos:

- Identificar si un pedido ya fue modificado
- Ver el estado actual correctamente (sin UPDATED como estado visible)

---

## Consumo de Realtime

Los eventos `order-updated` deben consumirse correctamente con el nuevo comportamiento:

- Si el status es PENDING → no asumir que el pedido cambió de posición
- Si hay items con `isNew: true` → mostrar highlight visual independientemente del status
- Si el status revierte a PENDING (CASO 3) → mostrar en la sección PENDING de la cola

---

## Implementado

- `src/shared/types/domain.ts` — `UPDATED` eliminado del tipo `OrderStatus`
- `src/features/kitchen/screens/KitchenScreen.tsx` — `statusPriority` actualizado: `PREPARING(1) > PENDING(2) > READY(3)`; `UPDATED` eliminado del mapa de prioridades
- `src/features/kitchen/components/OrderCard.tsx` — `UPDATED` eliminado de `statusLabels` y `statusColors`; `getActionForStatus` ya no trata UPDATED como PENDING
- `src/features/kitchen/screens/KitchenDashboardScreen.tsx` — condición `|| item.status === 'UPDATED'` eliminada del botón "Marcar preparando"
- `src/shared/components/OrderCard.tsx` — `UPDATED` eliminado de `statusLabels` y `statusColors`; variante kitchen agrega highlight verde (`itemRowNew`) cuando `item.isNew === true`

## Estrategia visual

Highlight de fondo verde (`#E8F5E9`) con borde verde (`#C8E6C9`) aplicado al ítem completo cuando `item.isNew === true`. Independiente del estado de la orden. Desaparece al pasar a READY (el backend limpia `isNew` en la misma transacción).

## Archivos modificados

- `src/shared/types/domain.ts`
- `src/features/kitchen/screens/KitchenScreen.tsx`
- `src/features/kitchen/components/OrderCard.tsx`
- `src/features/kitchen/screens/KitchenDashboardScreen.tsx`
- `src/shared/components/OrderCard.tsx`

---

## Objetivos de la Subetapa

- Visualizar correctamente pedidos modificados sin depender del estado UPDATED ✅
- Destacar productos nuevos en cualquier estado activo de la cola ✅
- Mantener PREPARING en la parte superior de la cola ✅
- Preservar el FIFO visible recibido del backend ✅
- Eliminar lógica de frontend que dependa de UPDATED como señal de modificación ✅

---

# ETAPA 4.6
# Order Classification System (Épica Principal)

Estado:

✅ COMPLETADA

---

## Justificación

Los pedidos actualmente solo tienen `tableNumber` como identificador visual y `status` para el estado de cocina.

No existe clasificación funcional que distinga:

- Pedidos para comer dentro del restaurante
- Pedidos para recoger y llevar
- Pedidos para entrega a domicilio

Esta clasificación aporta valor operativo para meseros, cocina, repartidores, reportes futuros y la operación diaria del restaurante.

La épica se divide en tres subetapas independientes para facilitar la entrega incremental y la validación por capas.

---

## OrderType vs OrderStatus — Conceptos Independientes

OrderType NO reemplaza OrderStatus.

Son dimensiones distintas de un mismo pedido.

```txt
OrderStatus — etapa de preparación:
  PENDING | PREPARING | READY | DELIVERED | CANCELLED
  UPDATED  [DEPRECADO — ETAPA 4.5.6.1]

OrderType — modalidad de consumo:
  DINE_IN | TAKEAWAY | DELIVERY
```

Un pedido puede ser DINE_IN y estar en PREPARING al mismo tiempo.

---

## Migración de datos existentes

Todos los pedidos existentes fueron migrados automáticamente:

```txt
tableNumber → reference (RENAME COLUMN, datos preservados)
tipo implícito → type = DINE_IN (default)
```

No se perdió información histórica.

---

# ETAPA 4.6.1
# Backend Schema & API

Estado:

✅ COMPLETADA

---

## Implementado

- `enum OrderType { DINE_IN, TAKEAWAY, DELIVERY }`
- `tableNumber` renombrado a `reference String?` (nullable, datos preservados)
- `deliveryAddress String?` agregado al modelo `Order`
- `type OrderType @default(DINE_IN)` agregado al modelo `Order`
- Migración con `RENAME COLUMN` para preservar datos existentes
- Validación condicional en `CreateOrderDto` con `@ValidateIf`:
  - DINE_IN / TAKEAWAY → `reference` requerido
  - DELIVERY → `deliveryAddress` requerido
- `UpdateOrderDto`: plates opcionales, type/reference/deliveryAddress opcionales con validación condicional
- `OrdersService.validateClassification()` como helper privado
- `OrderRealtimePayload` actualizado: `reference`, `deliveryAddress`, `type`
- Tests: 12 casos (3 FIFO + 1 SQL + 7 OrderType + 1 definición)

## Archivos modificados

```
prisma/schema.prisma
prisma/migrations/20260523000000_.../migration.sql
src/orders/dto/create-order.dto.ts
src/orders/dto/update-order.dto.ts
src/orders/orders.service.ts
src/orders/orders.service.spec.ts
src/realtime/interfaces/order-payload.interface.ts
```

## Reglas de clasificación

| type      | reference  | deliveryAddress |
|-----------|------------|-----------------|
| DINE_IN   | requerido  | ignorado        |
| TAKEAWAY  | requerido  | ignorado        |
| DELIVERY  | ignorado   | requerido       |

---

# ETAPA 4.6.2
# Frontend Create/Edit Order

Estado:

✅ COMPLETADA

---

## Implementado

- Selector de tipo de pedido (🍽 Comer aquí / 🥡 Para llevar / 🛵 Delivery)
- Formularios dinámicos por tipo (label, placeholder y campo cambian según el tipo)
- Validaciones dinámicas: DINE_IN y TAKEAWAY bloquean sin reference; DELIVERY bloquea sin deliveryAddress
- Campo opcional de nombre de referencia para pedidos DELIVERY
- Creación de pedidos con type, reference, deliveryAddress en el payload
- Edición de pedidos: permite cambiar DINE_IN ↔ TAKEAWAY ↔ DELIVERY sin agregar plates nuevos
- Visualización de dirección DELIVERY completa (campo multiline) en el flujo de edición
- OrderCard (variante mesero): muestra emoji + reference o deliveryAddress según type
- Compatibilidad con pedidos históricos migrados (type = DINE_IN, reference = tableNumber anterior)
- 10 pruebas manuales ejecutadas exitosamente

## Archivos modificados

```
src/shared/types/domain.ts
src/features/orders/services/ordersService.ts
src/features/orders/hooks/useCreateOrder.ts
src/features/orders/hooks/useEditOrder.ts
src/features/orders/screens/CreateOrderScreen.tsx
src/features/orders/screens/EditOrderScreen.tsx
src/shared/components/OrderCard.tsx
```

---

## Objetivo

Permitir a los meseros crear y editar pedidos clasificados por tipo.

Requiere que ETAPA 4.6.1 esté completada.

---

## Pantalla Crear Pedido

Selector de tipo (obligatorio, primer paso):

```txt
🍽 Comer aquí  →  DINE_IN
🥡 Para llevar  →  TAKEAWAY
🛵 Delivery     →  DELIVERY
```

Campo dinámico según tipo seleccionado:

```txt
DINE_IN
  label:       "Referencia"
  placeholder: "Mesa 4"
  obligatorio: sí

TAKEAWAY
  label:       "Nombre cliente"
  placeholder: "Roberto"
  obligatorio: sí

DELIVERY
  label:       "Dirección"
  placeholder: "Av. Juárez #123"
  obligatorio: sí (deliveryAddress)
  reference:   campo adicional opcional
```

El placeholder cambia dinámicamente al cambiar el tipo.

El campo se limpia al cambiar de tipo para evitar confusión.

---

## Edición de pedidos

La edición de un pedido existente permite cambiar el tipo:

```txt
DINE_IN ↔ TAKEAWAY ↔ DELIVERY
```

Manteniendo validaciones correspondientes al nuevo tipo seleccionado.

---

## Visualización de dirección DELIVERY

Cuando un mesero abre un pedido DELIVERY para editarlo:

La dirección completa se muestra dentro del flujo de edición actual.

No se requiere pantalla adicional.

---

## Archivos afectados

Frontend:

- `src/shared/types/domain.ts` — tipo `OrderType`, campos en `Order`, `CreateOrderPayload`
- `src/features/orders/hooks/useCreateOrder.ts`
- `src/features/orders/hooks/useEditOrder.ts`
- `src/features/orders/services/ordersService.ts`
- `src/features/orders/screens/CreateOrderScreen.tsx`
- `src/features/orders/screens/EditOrderScreen.tsx`
- `src/shared/components/OrderCard.tsx` (visualización en vista mesero)

---

# ETAPA 4.6.3
# Kitchen Integration

Estado:

✅ COMPLETADA

---

## Objetivo

Adaptar el Kitchen Display System (KDS) para mostrar correctamente los tipos de pedido.

Requiere que ETAPA 4.6.1 y 4.6.2 estén completadas. ✅ Ambas completadas.

---

## Visualización por tipo en cocina

```txt
DINE_IN   →  🍽 Mesa 4
TAKEAWAY  →  🥡 Roberto

DELIVERY (con reference):
  🛵 Roberto - Enviar

DELIVERY (sin reference):
  🛵 Av. Juárez #123...   (con truncamiento si el texto es largo)
```

---

## Reglas de visualización Kitchen

- Kitchen NO agrupa pedidos por tipo.
- Se mantiene el FIFO existente.
- Se mantiene la priorización actual de estados.
- Los pedidos continúan mezclados en la misma cola.
- El emoji identifica el tipo a distancia sin texto adicional.

---

## Regla READY — Significado unificado

READY tiene el mismo significado para todos los tipos de pedido:

"Pedido completamente preparado y listo para ser entregado."

```txt
DINE_IN   → mesero puede llevarlo a la mesa
TAKEAWAY  → cliente puede recogerlo
DELIVERY  → repartidor puede salir a entregarlo
```

No se agregan estados adicionales por tipo en ETAPA 4.6.

---

## Alcance MVP — Delivery

Los pedidos DELIVERY son capturados exclusivamente por personal interno.

```txt
Cliente llama al restaurante
      ↓
Mesero captura el pedido en el sistema
      ↓
Sistema registra pedido DELIVERY con deliveryAddress
```

No existe en ETAPA 4.6:

- Self Ordering
- QR Ordering
- Portal Web
- Pedidos realizados por clientes directamente
- App de repartidores

Estas funcionalidades podrán evaluarse en etapas posteriores a producción.

---

## Implementado

- `src/shared/utils/orderDisplay.ts` — helper `getOrderDisplayLabel(order)` con reglas de visualización por tipo y truncamiento de dirección (máx. 20 chars)
- `src/features/kitchen/components/OrderCard.tsx` — reemplaza `Mesa {order.table}` y bloque `orderType` crudo con `getOrderDisplayLabel`
- `src/shared/components/OrderCard.tsx` — reemplaza `getOrderHeaderLabel` local y `Mesa ${order.table}` (variante kitchen) con `getOrderDisplayLabel`; waiter y kitchen usan ahora el mismo helper

## Archivos afectados

Frontend:

- `src/shared/utils/orderDisplay.ts` (nuevo)
- `src/shared/utils/index.ts`
- `src/features/kitchen/components/OrderCard.tsx`
- `src/shared/components/OrderCard.tsx`

---

# ETAPA 4.7
# Realtime Reliability

Estado:

✅ COMPLETADA

---

## Sub-etapas

- 4.7.1 Socket Reconnect — ✅ COMPLETADA
- 4.7.2 Resync After Reconnect — ✅ COMPLETADA
- 4.7.3 Multi-device Validation — ✅ COMPLETADA

---

# ETAPA 4.7.1
# Socket Reconnect

Estado:

✅ COMPLETADA

---

## Objetivos

Robustez de la conexión Socket.IO en el cliente.

---

## Alcance

Únicamente frontend. El backend ya soporta JWT authentication, rooms por taquería, handleConnection() con re-validación automática y join a taqueria:<id> en cada reconexión.

---

## Implementar

- Opciones explícitas de reconexión en `socketService.connect()`: `reconnection: true`, `reconnectionAttempts: Infinity`, `reconnectionDelay: 1000`, `reconnectionDelayMax: 5000`, `timeout: 20000`
- Handler `disconnect` en `RealtimeProvider`: si reason === 'io server disconnect' → `signOut()` automático
- Cleanup del listener `disconnect` en el return del `useEffect`

---

## Resultado esperado

- El cliente se reconecta automáticamente tras pérdida de red o timeout.
- Si el servidor rechaza la conexión (JWT expirado), el usuario es redirigido al login sin intervención manual.
- No hay listeners duplicados ni memory leaks.

---

# ETAPA 4.7.2
# Resync After Reconnect

Estado:

✅ COMPLETADA

---

## Objetivos

Recuperar pedidos perdidos durante la desconexión.

---

## Implementar

- Handler `connect` en `RealtimeProvider`: detecta reconexiones vs primera conexión via `hasConnectedRef`
- En reconexión: `GET /orders` directo via `apiClient`, filtra activos, dispatch `setOrders(active)`
- Protección anti-concurrencia: `resyncIdRef` (ID incremental) — si llegan múltiples `connect` rápidos, solo el último resync actualiza el store
- Error silencioso en resync: si `GET /orders` falla, el realtime sigue actualizando el store via eventos

---

## Decisión: productos NO se resincronizan

Los productos se gestionan con cache in-memory (`productService`). No existen eventos realtime para productos. El cache se calienta en el inicio de sesión via `subscribeToOrders`. En resync, `ordersService.parseOrder()` usa el cache existente correctamente. No hay valor en refetch de productos al reconectar.

---

## Resultado esperado

Al reconectar, el frontend recupera el estado completo de órdenes activas desde el servidor y descarta cualquier desincronización acumulada durante la desconexión.

---

# ETAPA 4.7.3
# Multi-device Validation

Estado:

✅ COMPLETADA

---

## Objetivos

Validar comportamiento con múltiples dispositivos simultáneos en la misma taquería.

---

## Resultados validados

### Kitchen (COOK)

Visualiza correctamente todos los pedidos de la taquería en tiempo real.

### Meseros (WAITER)

Visualizan únicamente sus propios pedidos. El aislamiento por rol se mantiene.

### Realtime

Actualizaciones de estado y creación de pedidos sincronizadas correctamente en todos los dispositivos conectados.

### Reconexión

Recuperación correcta de estado post-reconexión. La resincronización automática (4.7.2) funciona en todos los dispositivos.

### Order Classification

Validado end-to-end en múltiples dispositivos:

- 🍽 DINE_IN — referencia de mesa visible y correcta en cocina y meseros
- 🥡 TAKEAWAY — nombre de cliente visible y correcto
- 🛵 DELIVERY — dirección visible y truncamiento correcto en KDS

### Validaciones adicionales

- Reconexión automática verificada en modo avión y cambios de red
- Resincronización de órdenes verificada tras desconexión
- Cambios de estado propagados correctamente a todos los dispositivos
- Edición de pedidos (Append Only) reflejada en cocina y meseros
- isNew highlight verde funciona correctamente en múltiples sesiones simultáneas

---

## Garantías de confiabilidad verificadas

- Sin conflictos entre múltiples dispositivos conectados
- Sin eventos perdidos en condiciones normales de red
- Consistencia eventual garantizada mediante resync post-reconexión
- Aislamiento multi-tenant confirmado (cada taquería recibe solo sus propios eventos)

---

# ETAPA 4.8
# History & Filters

Estado:

⬜ PENDIENTE

---

## Objetivos

Filtros históricos.

---

## Opciones

### Activos

Default. Muestra pedidos cuyo status no es DELIVERED ni CANCELLED, sin límite de fecha.

---

### Hoy

---

### Últimos 7 días

---

### Último mes

---

### Últimos 3 meses

---

## Roles

WAITER

Solo sus pedidos.

---

COOK

Todos los pedidos de la taquería.

---

# ETAPA 4.9
# Performance Optimization

Estado:

⬜ PENDIENTE

---

## Objetivos

Optimizar sistema completo.

---

## Implementar

- Prisma Indexes
- Query Optimization
- Pagination
- Efficient Includes
- Socket Optimization

---

## Resultado esperado

Capacidad para operar múltiples taquerías simultáneamente.

---

# ETAPA 4.10
# Product Management Improvements

Estado:

⬜ PENDIENTE

---

## Contexto

Durante las pruebas manuales de ETAPA 4.5.2 se verificó que:

- La API soporta edición de complements vía PATCH /products/:id.
- La API soporta eliminación de productos vía DELETE /products/:id.
- El servicio frontend (productService) ya implementa ambas operaciones.
- El frontend NO tiene interfaz de usuario para editar complements de un producto existente.
- El frontend NO tiene interfaz de usuario para eliminar un producto.

No existe un bug ni problema de integración.

Se trata de funcionalidades pendientes de UI que nunca fueron implementadas en el frontend.

---

## Pendiente

- Agregar edición de complements en EditProductScreen
- Agregar botón o flujo de eliminación de producto en EditProductScreen o SettingsScreen

---

## Notas técnicas

- productService.updateProduct() admite complements en el payload — solo requiere exponer el campo en el formulario.
- productService.deleteProduct() está implementado y listo — solo requiere UI.
- No se requieren cambios en backend ni en el service layer.

---

# ETAPA 5.0
# MVP Launch

Estado:

🟡 EN PROGRESO

---

## Objetivo

Lanzamiento productivo de TacosManager.

Sin agregar nuevas funcionalidades de negocio — el foco es infraestructura y despliegue.

Estrategia comercial y costos: docs/business-model.md

---

## Subetapas

```txt
5.0.1 — Environment Strategy
5.0.2 — Backend Deployment
5.0.3 — Mobile Release Pipeline
5.0.4 — CI/CD Automation
5.0.5 — Monitoring & Recovery
5.0.6 — Production Validation
5.0.7 — Play Store Release
```

---

# ETAPA 5.0.1
# Environment Strategy

Estado:

✅ COMPLETADA

---

## Objetivo

Definir y configurar ambientes de operación separados para backend y frontend.

Backend: variables de entorno por archivo `.env.*` cargadas por `@nestjs/config`.
Frontend: variables por `react-native-config` (ver sección Frontend).

---

## Ambientes

- DEV — desarrollo local (`localhost:3000`)
- QA — Servidor QA (Railway)
- PROD — Servidor de producción (Railway)

---

## Implementación Backend ✅

### Módulo de configuración

`@nestjs/config` (ConfigModule) registrado globalmente en `AppModule`.

Carga de archivos en orden de prioridad:

```txt
1. .env.${NODE_ENV}   (ej. .env.development, .env.qa, .env.production)
2. .env               (fallback — valores por defecto locales)
```

Validación al arranque: si `DATABASE_URL` o `JWT_SECRET` no están definidos, la aplicación falla con mensaje claro.

### Variables soportadas

| Variable | Descripción | Requerida |
|----------|-------------|-----------|
| `NODE_ENV` | Ambiente activo (`development` / `qa` / `production`) | No (default: `development`) |
| `DATABASE_URL` | Cadena de conexión PostgreSQL | ✅ |
| `JWT_SECRET` | Clave secreta para firmar JWT | ✅ |
| `JWT_EXPIRES_IN` | Tiempo de expiración JWT | No (default: `1d`) |
| `PORT` | Puerto HTTP | No (default: `3000`) |
| `CORS_ORIGIN` | Origen permitido para HTTP CORS | No (default: `*`) |
| `SOCKET_ORIGIN` | Origen permitido para Socket.IO | No (default: `*`) |

### Archivos de entorno

```txt
.env.development  — DEV local
.env.qa           — QA
.env.production   — PROD (plantilla — Railway inyecta las variables reales)
.env.example      — plantilla documentada ← único archivo commiteado
.env              — fallback local (gitignoreado)
```

Todos gitignoreados excepto `.env.example`.

### Scripts de inicio

```bash
pnpm run start:dev   # NODE_ENV=development
pnpm run start:qa    # NODE_ENV=qa
pnpm run start:prod  # NODE_ENV=production
```

### Estrategia de bases de datos

| Ambiente | Base de datos | Propósito |
|----------|---------------|-----------|
| DEV | PostgreSQL local (`localhost:5432`) | Desarrollo y pruebas locales |
| QA | PostgreSQL Railway (instancia independiente) | Pruebas de integración |
| PROD | PostgreSQL Railway (instancia independiente) | Producción — datos reales |

Aislamiento total entre ambientes. Ninguna base comparte datos con otra.

### CORS

- HTTP: `app.enableCors({ origin: CORS_ORIGIN })` en `main.ts`
- Socket.IO: `ConfiguredSocketIoAdapter` lee `SOCKET_ORIGIN` desde ConfigService

### Archivos nuevos / modificados

```txt
src/config/env.validation.ts        — función de validación de vars requeridas
src/realtime/socket-io.adapter.ts   — adaptador Socket.IO con CORS configurable
src/main.ts                         — CORS HTTP + socket adapter configurable + ConfigService
src/app.module.ts                   — ConfigModule.forRoot global
src/auth/auth.module.ts             — ConfigService en lugar de process.env
src/auth/strategies/jwt.strategy.ts — ConfigService en lugar de process.env
src/prisma/prisma.service.ts        — ConfigService en lugar de process.env
src/realtime/realtime.gateway.ts    — cors removido del decorador (maneja el adapter)
```

---

## Variables de entorno Frontend

| Variable | Descripción |
|----------|-------------|
| `API_URL` | URL base del backend REST |
| `SOCKET_URL` | URL del servidor Socket.IO |
| `ENVIRONMENT` | Identificador del ambiente (`development` / `qa` / `production`) |

---

## Archivos de configuración Frontend

```txt
.env              — Ambiente activo por defecto (desarrollo local)
.env.development  — DEV (Android emulator)
.env.qa           — QA
.env.production   — PROD

Todos gitignoreados excepto .env.example
```

Selección de ambiente en tiempo de ejecución:

```bash
ENVFILE=.env.qa npx react-native run-android
ENVFILE=.env.production npx react-native run-android
```

La selección automática por flavor de Android se implementa en ETAPA 5.0.3.1 ✅ COMPLETADA.

---

## Implementación Frontend

Punto de entrada único: `src/config/env.ts`

- Valida que `API_URL`, `SOCKET_URL` y `ENVIRONMENT` estén presentes al iniciar
- Lanza error descriptivo si falta alguna variable
- Exporta `ENV` con los valores validados

`APP_CONFIG` en `src/shared/constants/app.ts` expone:

- `baseApiUrl` — URL base para el cliente Axios
- `socketUrl` — URL para la conexión Socket.IO
- `environment` — nombre del ambiente activo

Servicios actualizados:

- `src/services/api/client.ts` — Axios usa `APP_CONFIG.baseApiUrl`
- `src/services/realtime/socketService.ts` — Socket.IO usa `APP_CONFIG.socketUrl`

---

## Validaciones realizadas

Verificadas en la nueva arquitectura de configuración (ambientes DEV / QA / PROD):

- ✅ Login y Auth (JWT firmado por `JWT_SECRET` desde ConfigService)
- ✅ Products (CRUD completo)
- ✅ Orders — DINE_IN, TAKEAWAY, DELIVERY
- ✅ Kitchen (cola FIFO: PREPARING > PENDING > READY)
- ✅ Realtime (order-created, order-updated, order-status-changed)
- ✅ Reconnect y Resync after reconnect
- ✅ Multi-device con múltiples roles simultáneos

El sistema opera sin modificar código al cambiar de ambiente. Toda la configuración depende exclusivamente del entorno seleccionado vía `NODE_ENV` + archivos `.env.*`.

---

# ETAPA 5.0.2
# Backend Deployment

Estado:

🟡 EN PROGRESO

---

## Objetivo

Desplegar backend en infraestructura de producción con base de datos administrada.

---

## Infraestructura

- Railway (API + PostgreSQL para QA y PROD)
- Firebase Storage (imágenes de productos)
- Dominio: Railway default (`*.up.railway.app`) — sin dominio custom en MVP

---

## Production Readiness — Implementado

Auditoría de producción completada y correcciones aplicadas.

### Hallazgos resueltos

**Crítico**
- `GET /` exponía `prisma.taqueria.findMany()` sin autenticación → convertido a health status sin DB

**Alto**
- Implementado health check endpoint `GET /health` → `{ status, timestamp, environment }`
- Eliminado `dotenv` de dependencies (ya no se usa desde ETAPA 5.0.1 con `@nestjs/config`)
- `socket.io-client` movido a devDependencies (solo se necesita en testing)

**Medio**
- Eliminado `PrismaService.isConnected` estático → `$connect()` idempotente de Prisma es suficiente

**Bajo**
- Agregado `postinstall: "prisma generate"` en package.json → Railway genera el cliente Prisma automáticamente después de `pnpm install`

### Archivos modificados

```
src/app.service.ts       — eliminada dependencia de Prisma, retorna health status
src/app.controller.ts    — GET / y GET /health retornan { status, timestamp, environment }
src/app.controller.spec.ts — test actualizado al nuevo contrato
src/prisma/prisma.service.ts — eliminado isConnected estático
package.json             — postinstall, dotenv removido, socket.io-client → devDeps
railway.json             — configuración de despliegue Railway (nuevo archivo)
```

---

## railway.json — Configuración de despliegue

```json
{
  "build": { "buildCommand": "pnpm run build" },
  "deploy": {
    "startCommand": "node dist/main",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

---

## Variables de entorno requeridas en Railway

Configurar en el dashboard de Railway para cada ambiente (QA / PROD):

| Variable      | Descripción                              | Ejemplo PROD                 |
|---------------|------------------------------------------|------------------------------|
| NODE_ENV      | Ambiente activo                          | `production`                 |
| DATABASE_URL  | Connection string PostgreSQL Railway     | `postgresql://...`           |
| JWT_SECRET    | Secret JWT — string aleatorio seguro     | `<random-256-bit-string>`    |
| JWT_EXPIRES_IN| Duración del token                       | `1d`                         |
| PORT          | Puerto HTTP (Railway lo inyecta solo)    | `3000`                       |
| CORS_ORIGIN   | Origen permitido para HTTP               | `https://app.up.railway.app` |
| SOCKET_ORIGIN | Origen permitido para Socket.IO          | `https://app.up.railway.app` |

> En Railway, `PORT` es inyectado automáticamente por la plataforma. No hace falta configurarlo manualmente.

---

## Railway Readiness Checklist

```txt
✅ PORT leído de env var (ConfigService.get('PORT', 3000))
✅ DATABASE_URL leído de env var (ConfigService.getOrThrow)
✅ JWT_SECRET leído de env var (ConfigService.getOrThrow)
✅ CORS configurado desde env var
✅ Socket.IO CORS configurado desde env var
✅ app.listen(port) — Node.js enlaza en 0.0.0.0 por defecto
✅ Health check en GET /health
✅ railway.json con startCommand, healthcheckPath, restartPolicy
✅ postinstall: prisma generate — cliente Prisma disponible post-install
✅ Build: pnpm run build → dist/main.js (verificado)
✅ Tests: 19/19 pasan
✅ Sin valores hardcodeados de entorno en código fuente
✅ .env.* gitignoreado — variables se inyectan externamente en Railway
```

---

## Pendiente (próximos pasos de 5.0.2)

- Crear proyecto en Railway (QA)
- Provisionar PostgreSQL en Railway
- Configurar variables de entorno en Railway dashboard
- Ejecutar migraciones: `pnpm prisma migrate deploy`
- Validar health check en URL de Railway
- Smoke test de endpoints principales

---

# ETAPA 5.0.3
# Mobile Release Pipeline

Estado:

✅ COMPLETADA

Fecha de cierre: 2026-05-27

---

## Objetivo

Preparar build y distribución del app móvil por ambiente.

---

## Subetapas

```txt
5.0.3.1 ✅ — Android Flavors (productFlavors DEV / QA / PROD)
5.0.3.2 ✅ — Build Automation (scripts compuestos build:qa / build:prod)
5.0.3.3 ✅ — Mobile CI/CD (GitHub Actions: PR validate + main release)
5.0.3.4 ⬜ — Play Store Internal Track (primera subida) [DIFERIDO a ETAPA 5.0.7]
```

## Resultado Final

Pipeline completo Mobile funcionando en GitHub Actions:

- Pull Request → lint + typecheck + build QA (validación automática)
- Push a main → lint + typecheck + build QA + build Production (artefactos firmados)
- APK QA y AAB Production publicados como GitHub Artifacts
- Firma con keystore validada en CI
- Soporte Linux (gradlew con permisos correctos)
- GitHub Secrets configurados (KEYSTORE_PASSWORD, KEY_PASSWORD)

---

# ETAPA 5.0.3.1
# Android Flavors

Estado:

✅ COMPLETADA

---

## Objetivo

Implementar `productFlavors` Android para seleccionar automáticamente el archivo `.env` correcto según el ambiente, sin modificar código.

---

## Flavors implementados

| Flavor | applicationId | App Name | Env file |
|--------|---------------|----------|----------|
| `development` | `com.tacosmanager.dev` | TacosManager Dev | `.env.development` |
| `qa` | `com.tacosmanager.qa` | TacosManager QA | `.env.qa` |
| `production` | `com.tacosmanager` | TacosManager | `.env.production` |

---

## Variantes generadas

```txt
developmentDebug    — desarrollo local con Metro
developmentRelease  — build firmado con .env.development

qaDebug             — QA con Metro (testing en dispositivo)
qaRelease           — APK firmado para distribución QA

productionDebug     — producción con Metro (diagnóstico)
productionRelease   — AAB firmado para Play Store
```

---

## Archivos modificados

```txt
android/app/build.gradle
  ├── project.ext.envConfigFiles  — mapeo flavor → .env.*
  ├── react.debuggableVariants    — todas las variantes *Debug
  ├── flavorDimensions "environment"
  └── productFlavors { development, qa, production }

android/app/src/development/res/values/strings.xml  — "TacosManager Dev"
android/app/src/qa/res/values/strings.xml           — "TacosManager QA"
android/app/src/main/res/values/strings.xml         — "TacosManager" (sin cambios)

package.json
  ├── android       → --flavor development (default)
  ├── android:dev   → --flavor development
  ├── android:qa    → --flavor qa
  ├── android:prod  → --flavor production
  ├── build:android:dev  → assembleDevelopmentDebug
  ├── build:android:qa   → assembleQaRelease
  └── build:android:prod → bundleProductionRelease
```

---

## Cómo selecciona react-native-config el archivo .env

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

Las claves son los nombres de variante en **minúsculas** (`{flavor}{buildType}`), tal como los procesa Gradle. `dotenv.gradle` de react-native-config los lee automáticamente y expone las variables vía `Config.*` en JS.

---

## Keystore (sin cambios)

El `signingConfig.release` sigue leyendo las credenciales del `.env` raíz (que contiene las contraseñas reales y está gitignoreado). Los flavors no modifican la configuración de firma.

---

## Comandos de ejecución

### Desarrollo (debug, Metro)

```bash
npm run android:dev       # com.tacosmanager.dev — Metro
npm run android:qa        # com.tacosmanager.qa  — Metro
npm run android:prod      # com.tacosmanager      — Metro
```

### APK QA (firmado release)

```bash
npm run build:android:qa
# equivalente Gradle:
cd android && gradlew assembleQaRelease
# Output: android/app/build/outputs/apk/qa/release/app-qa-release.apk
```

### AAB Production (Play Store)

```bash
npm run build:android:prod
# equivalente Gradle:
cd android && gradlew bundleProductionRelease
# Output: android/app/build/outputs/bundle/productionRelease/app-production-release.aab
```

### Tareas Gradle individuales

```bash
cd android && gradlew assembleDevelopmentDebug
cd android && gradlew assembleQaDebug
cd android && gradlew assembleProductionDebug

cd android && gradlew assembleDevelopmentRelease
cd android && gradlew assembleQaRelease
cd android && gradlew assembleProductionRelease

cd android && gradlew bundleProductionRelease
```

---

## Criterios de validación

```txt
✅ Instalar developmentDebug → app_name "TacosManager Dev"
✅ Instalar qaDebug          → app_name "TacosManager QA"
✅ Instalar productionDebug  → app_name "TacosManager"

✅ Pueden coexistir en el mismo dispositivo (applicationId diferente)
   com.tacosmanager.dev
   com.tacosmanager.qa
   com.tacosmanager

✅ Verificar Config.ENVIRONMENT en cada flavor:
   development → "development"
   qa          → "qa"
   production  → "production"

✅ Verificar Config.API_URL en cada flavor:
   development → http://10.0.2.2:3000
   qa          → https://api-qa.tacosmanager.com
   production  → https://api.tacosmanager.com

✅ assembleQaRelease genera APK firmado
✅ bundleProductionRelease genera AAB firmado
✅ Login, Órdenes, Cocina, Realtime funcionan en dev flavor
```

---

# ETAPA 5.0.3.2
# Build Automation

Estado:

✅ COMPLETADA

---

## Objetivo

Automatizar el proceso de compilación Android para que cualquier desarrollador pueda generar artefactos reproducibles con un único comando, con validación previa de calidad de código.

---

## Scripts implementados

### Verificación de calidad

```bash
npm run typecheck     # tsc --noEmit — verifica tipos TypeScript sin emitir archivos
npm run lint          # eslint . — verifica reglas ESLint
```

### Limpieza

```bash
npm run clean         # alias de clean:android
npm run clean:android # cd android && gradlew clean
                      # Elimina: android/build/, android/app/build/
                      # No afecta: node_modules, .env, keystore
```

### Builds individuales (sin verificación previa)

```bash
npm run build:android:dev   # assembleDevelopmentDebug
npm run build:android:qa    # assembleQaRelease
npm run build:android:prod  # bundleProductionRelease
```

### Builds compuestos (con verificación previa ✅)

```bash
npm run build:qa
# Ejecuta en secuencia:
#   1. npm run lint       → 0 errores requerido
#   2. npm run typecheck  → 0 errores requerido
#   3. npm run build:android:qa → assembleQaRelease

npm run build:prod
# Ejecuta en secuencia:
#   1. npm run lint       → 0 errores requerido
#   2. npm run typecheck  → 0 errores requerido
#   3. npm run build:android:prod → bundleProductionRelease
```

Si cualquier paso falla, el pipeline se detiene y no genera artefactos.

---

## Artefactos generados

### APK QA

```txt
Comando: npm run build:android:qa
Output:  android/app/build/outputs/apk/qa/release/app-qa-release.apk

Firma: signingConfig.release (tacosmanager.keystore)
applicationId: com.tacosmanager.qa
App name: TacosManager QA
Env: .env.qa
```

### AAB Production

```txt
Comando: npm run build:android:prod
Output:  android/app/build/outputs/bundle/productionRelease/app-production-release.aab

Firma: signingConfig.release (tacosmanager.keystore)
applicationId: com.tacosmanager
App name: TacosManager
Env: .env.production
```

---

## Guía de release local

### QA APK

```txt
1. Actualizar versionCode y versionName en android/app/build.gradle si corresponde
2. Confirmar que .env.qa tiene API_URL y SOCKET_URL correctas
3. npm run clean:android         ← limpieza opcional pero recomendada
4. npm run build:qa              ← lint + typecheck + assembleQaRelease
5. Instalar en dispositivo:
   adb install android/app/build/outputs/apk/qa/release/app-qa-release.apk
6. Validar login con credenciales de QA
7. Validar creación de orden → cocina la recibe en tiempo real
8. Validar reconexión (modo avión y vuelta)
```

### Production AAB

```txt
1. Actualizar versionCode y versionName en android/app/build.gradle
2. Confirmar que .env.production tiene API_URL y SOCKET_URL de producción
3. npm run clean:android         ← limpieza obligatoria para release
4. npm run build:prod            ← lint + typecheck + bundleProductionRelease
5. Verificar firma del AAB:
   cd android
   gradlew signingReport
   (confirmar que productionRelease usa tacosmanager.keystore)
6. Subir .aab a Google Play Console → Internal Testing track
7. Ejecutar checklist de validación post-subida
```

---

## Validaciones realizadas

```txt
✅ tsc --noEmit  → 0 errores TypeScript
✅ eslint .      → 0 errores ESLint (2 warnings de estilo — no bloquean build)
✅ npm run build:qa   → pipeline lint → typecheck → assembleQaRelease operativo
✅ npm run build:prod → pipeline lint → typecheck → bundleProductionRelease operativo
✅ npm run clean:android → gradlew clean elimina build/ sin tocar node_modules
```

### Correcciones de lint incluidas

Dos errores ESLint preexistentes fueron corregidos para que el pipeline no se bloquee:

```txt
src/features/auth/types.ts
  → Eliminado import 'AppUser' (importado pero nunca usado)

src/features/orders/hooks/useOrders.ts
  → Eliminado 'createdBy' de dependencias useCallback (variable asignada pero no usada)
  → Eliminada declaración 'const createdBy' (valor no consumido por subscribeToOrders)
```

Ninguna de estas correcciones modifica comportamiento de negocio.

---

## Checklist de validación de release

```txt
AUTH
  ✅ Login con credenciales válidas → navega a pantalla principal
  ✅ Login con credenciales inválidas → muestra error
  ✅ Logout → regresa a Login, socket desconectado

PRODUCTS
  ✅ Lista de productos carga correctamente
  ✅ Crear producto con imagen → imagen visible
  ✅ Editar producto → cambios persistidos

ORDERS
  ✅ Crear orden DINE_IN con referencia
  ✅ Crear orden TAKEAWAY con referencia
  ✅ Crear orden DELIVERY con dirección
  ✅ Editar orden (agregar items)

KITCHEN
  ✅ Kitchen recibe orden creada en tiempo real
  ✅ Prioridad: PREPARING > PENDING > READY
  ✅ Cambio de estado → mesero lo ve en tiempo real
  ✅ Highlight verde en items nuevos

REALTIME
  ✅ Múltiples dispositivos ven la misma cola
  ✅ order-created emitido y recibido correctamente
  ✅ order-updated emitido y recibido correctamente
  ✅ order-status-changed emitido y recibido correctamente

RECONNECT & RESYNC
  ✅ Modo avión → app espera
  ✅ Reconexión → resync automático de órdenes activas
  ✅ Servidor reiniciado → cliente reconecta solo
  ✅ JWT expirado → signOut() automático

LOGOUT
  ✅ signOut limpia token de AsyncStorage
  ✅ Socket desconectado en logout
  ✅ Navegación regresa a AuthStack
```

---

# ETAPA 5.0.3.3
# Mobile CI/CD

Estado:

✅ COMPLETADA

---

## Objetivo

Pipeline GitHub Actions que valida automáticamente cada Pull Request y genera artefactos firmados en cada push a `main`.

---

## Archivo creado

```txt
.github/workflows/mobile-ci.yml
```

---

## Triggers

| Evento | Jobs ejecutados |
|--------|-----------------|
| `pull_request` | Validate & Build QA (sin artefactos) |
| `push → main` | Validate & Build QA + Build Production (con artefactos) |

---

## Jobs

### Job 1: `validate-and-build-qa`

Ejecutado en: todos los triggers.

```txt
1. Checkout
2. Setup Java 17 (Temurin)
3. Setup Node LTS (con cache npm)
4. Setup Gradle (con cache Gradle)
5. npm ci
6. Crear .env.qa (API URLs QA)
7. Crear .env (signing credentials desde secrets)
8. Accept Android SDK licenses
9. npm run lint
10. npm run typecheck
11. npm run build:android:qa   → assembleQaRelease
12. Upload APK artifact (solo si push a main)
```

Si cualquier paso falla → workflow falla → no se genera artefacto.

### Job 2: `build-production`

Ejecutado solo en: `push → main`, después de que Job 1 exitoso.

```txt
1. Checkout
2. Setup Java 17 (Temurin)
3. Setup Node LTS (con cache npm)
4. Setup Gradle (con cache Gradle)
5. npm ci
6. Crear .env.production (API URLs Producción)
7. Crear .env (signing credentials desde secrets)
8. Accept Android SDK licenses
9. npm run build:android:prod  → bundleProductionRelease
10. Upload AAB artifact
```

---

## Artefactos generados (push a main)

| Job | Artefacto | Retención |
|-----|-----------|-----------|
| Job 1 | `app-qa-release-<sha>.apk` | 30 días |
| Job 2 | `app-production-release-<sha>.aab` | 30 días |

Descarga: GitHub → pestaña Actions → workflow run → sección Artifacts.

---

## GitHub Secrets requeridos

Configurar en: `GitHub → Settings → Secrets and variables → Actions`

| Secret | Descripción |
|--------|-------------|
| `KEYSTORE_PASSWORD` | `MYAPP_UPLOAD_STORE_PASSWORD` del keystore |
| `KEY_PASSWORD` | `MYAPP_UPLOAD_KEY_PASSWORD` del keystore |

No se necesita el archivo keystore como secret — `android/app/tacosmanager.keystore` está en el repositorio.

No se necesita `KEY_ALIAS` como secret — el valor `tacosmanager-key` es público en `gradle.properties`.

---

## Archivos en CI (no en git, creados en runtime)

| Archivo | Origen | Contenido |
|---------|--------|-----------|
| `.env.qa` | Inline en workflow | `API_URL`, `SOCKET_URL`, `ENVIRONMENT=qa` |
| `.env.production` | Inline en workflow | `API_URL`, `SOCKET_URL`, `ENVIRONMENT=production` |
| `.env` | GitHub Secrets | `MYAPP_UPLOAD_STORE_FILE`, `KEY_ALIAS`, passwords |

---

## Fix incluido: compatibilidad Linux en scripts npm

Los scripts de Gradle se corrigieron de `gradlew` a `./gradlew` para compatibilidad con Linux (CI) y Windows (local):

```txt
build:android:dev   → cd android && ./gradlew assembleDevelopmentDebug
build:android:qa    → cd android && ./gradlew assembleQaRelease
build:android:prod  → cd android && ./gradlew bundleProductionRelease
clean:android       → cd android && ./gradlew clean
```

---

## Cómo validar el pipeline

```txt
1. Hacer push del branch con .github/workflows/mobile-ci.yml
2. Abrir GitHub → pestaña Actions
3. Verificar que "Mobile CI" aparece en la lista
4. Abrir el workflow run
5. Confirmar que los jobs pasan:
   - "Validate & Build QA" → verde ✅
   - "Build Production" → verde ✅ (solo en main)
6. En el run de main, desplazarse a sección "Artifacts"
7. Confirmar que aparecen:
   - app-qa-release-<sha>
   - app-production-release-<sha>
8. Descargar y verificar los artefactos
```

### Interpretar fallos del pipeline

| Fallo | Causa | Solución |
|-------|-------|---------|
| `Lint` falla | Error ESLint en código | Corregir el error en el archivo indicado |
| `TypeCheck` falla | Error TypeScript | Corregir el tipo indicado en la traza |
| `Build QA APK` falla (signing) | Secrets no configurados | Agregar `KEYSTORE_PASSWORD` y `KEY_PASSWORD` en GitHub Secrets |
| `Build QA APK` falla (Gradle) | Dependencia faltante o error de compilación | Revisar logs de Gradle en el step |
| `Build Production` falla | Job 1 falló (needs) | Arreglar Job 1 primero |

---

## Checklist de mantenimiento del pipeline

```txt
□ Al actualizar compileSdkVersion o buildToolsVersion → verificar que el runner de CI los descarga
□ Al agregar dependencia con Gradle → verificar que el cache Gradle sigue funcionando
□ Al cambiar API URLs de QA o PROD → actualizar los pasos "Create .env.*" en el workflow
□ Al renovar el keystore → actualizar los secrets en GitHub Settings
□ Al rotar contraseñas → actualizar KEYSTORE_PASSWORD y KEY_PASSWORD en GitHub Settings
□ Periodicamente revisar retención de artefactos (30 días actualmente)
```

---

# ETAPA 5.0.4
# CI/CD Automation

Estado:

🟡 EN PROGRESO

---

## Objetivo

Expandir el pipeline CI/CD existente para cubrir validaciones técnicas completas de Mobile y Backend, con enfoque MVP Production Ready: simple, mantenible, económico y profesional.

---

## Contexto

La ETAPA 5.0.3.3 entregó un pipeline Mobile funcional en GitHub Actions. La ETAPA 5.0.4 extiende ese trabajo en dos frentes:

1. **Mobile** — optimizar y estructurar mejor el pipeline existente.
2. **Backend** — crear pipeline CI para el repositorio NestJS.

No se implementará en esta etapa: deploy automático a producción, Play Store publishing, Fastlane, Docker registry, Kubernetes, Terraform, AWS, Sentry ni Analytics.

---

## Subetapas

```txt
5.0.4.1 ⬜ — Mobile Pipeline Optimization
5.0.4.2 ✅ — Backend CI Pipeline
5.0.4.3 ✅ — Branch Protection & Status Checks
5.0.4.4 ⬜ — CI/CD Conventions & Documentation
```

---

# ETAPA 5.0.4.1
# Mobile Pipeline Optimization

Estado:

✅ COMPLETADA

Fecha de cierre: 2026-05-28

---

## Objetivo

Optimizar y profesionalizar el pipeline móvil para mantenibilidad, velocidad, observabilidad e integración futura con Branch Protection. SIN romper la funcionalidad actual.

---

## Entregables

### Arquitectura final del pipeline

```txt
Mobile • Lint & TypeCheck   ← todos los triggers (PRs y push a dev/qa/main)
        ↓
Mobile • Build QA APK       ← push a qa y main
        ↓
Mobile • Build Production AAB ← push a main únicamente
```

### Estrategia de ramas

| Evento | Lint & TypeCheck | Build QA APK | Build Production AAB |
|--------|:---:|:---:|:---:|
| PR → dev / qa / main | ✅ | — | — |
| Push → dev | ✅ | — | — |
| Push → qa | ✅ | ✅ + artifact | — |
| Push → main | ✅ | ✅ + artifact | ✅ + artifact |

**Objetivo de PR:** validación rápida de código sin compilar — reviewers ven el check verde en segundos.

**Objetivo de push a dev:** igual que PR — integración sin costo de compilación.

**Objetivo de push a qa:** APK instalable para pruebas funcionales en dispositivo real.

**Objetivo de push a main:** pipeline completo para producción.

### Estrategia de ambientes

`.env.qa` y `.env.production` generados dinámicamente desde GitHub Repository Variables. Sin URLs hardcodeadas en el workflow.

| Variable | Ambiente | Uso |
|----------|----------|-----|
| `QA_API_URL` | QA | URL base del backend QA |
| `QA_SOCKET_URL` | QA | URL Socket.IO QA |
| `PROD_API_URL` | Production | URL base del backend Production |
| `PROD_SOCKET_URL` | Production | URL Socket.IO Production |

### Estrategia de artefactos

| Artefacto | Trigger | Retención |
|-----------|---------|-----------|
| `app-qa-release-<sha>.apk` | push → qa, push → main | 30 días |
| `app-production-release-<sha>.aab` | push → main | 30 días |

### Estrategia de cache

- **Node:** `actions/setup-node@v4` con `cache: npm` basado en `package-lock.json`
- **Gradle + Android SDK:** `gradle/actions/setup-gradle@v4`
- **Optimización clave:** `lint-typecheck` no instala Java ni Gradle — tiempo de ejecución reducido

### Nombres de jobs (Branch Protection ready)

```txt
Mobile • Lint & TypeCheck
Mobile • Build QA APK
Mobile • Build Production AAB
```

### Composite Action

No implementada. Con solo 2 jobs de build, el overhead de un archivo `action.yml` adicional supera el beneficio. Decisión documentada en `docs/cicd-mobile.md`.

---

## Validaciones ejecutadas

### Pull Requests (feature→dev, dev→qa, qa→main)

```txt
✅ Mobile • Lint & TypeCheck ejecutado
✅ Build QA APK NO ejecutado (correcto)
✅ Build Production AAB NO ejecutado (correcto)
```

### Push a dev

```txt
✅ Mobile • Lint & TypeCheck ejecutado
✅ Build QA APK NO ejecutado (correcto)
```

### Push a qa

```txt
✅ Mobile • Lint & TypeCheck ejecutado
✅ Mobile • Build QA APK ejecutado
✅ APK QA artifact generado y disponible en GitHub Actions
✅ Build Production AAB NO ejecutado (correcto)
```

### Push a main

```txt
✅ Mobile • Lint & TypeCheck ejecutado
✅ Mobile • Build QA APK ejecutado
✅ Mobile • Build Production AAB ejecutado
✅ APK QA artifact generado
✅ AAB Production artifact generado
```

### Variables GitHub

```txt
✅ QA_API_URL configurada y consumida correctamente
✅ QA_SOCKET_URL configurada y consumida correctamente
✅ PROD_API_URL configurada y consumida correctamente
✅ PROD_SOCKET_URL configurada y consumida correctamente
```

### Generación de archivos de ambiente

```txt
✅ .env.qa generado dinámicamente con valores de QA_API_URL y QA_SOCKET_URL
✅ .env.production generado dinámicamente con valores de PROD_API_URL y PROD_SOCKET_URL
✅ Sin URLs hardcodeadas en el workflow
```

### Cache

```txt
✅ npm cache operativo (node_modules cacheados por package-lock.json)
✅ Gradle cache operativo (dependencias Android cacheadas)
✅ Job lint-typecheck sin Java/Gradle — ejecución más rápida confirmada
```

### Artefactos

```txt
✅ app-qa-release-<sha>.apk disponible en push a qa y main
✅ app-production-release-<sha>.aab disponible solo en push a main
```

---

## Lecciones aprendidas

### Submodule en detached HEAD

El submódulo `docs` estaba en HEAD detached al momento de crear los cambios. Al hacer `git checkout main` en el submódulo con cambios pendientes, se generaron conflictos de merge con commits previos de ETAPA 5.0.4.2. Solución: `git stash` → `checkout main` → resolver conflictos manualmente partiendo del estado upstream y re-aplicando solo los cambios relevantes.

**Aplicar en futuro:** siempre verificar que el submódulo `docs` esté en la rama `main` antes de crear archivos nuevos, para evitar conflictos de merge al momento del commit.

### Estrategia de `needs` + `if` en GitHub Actions

Para implementar la ejecución condicional por rama, se combinaron `needs` (dependencias entre jobs) con condiciones `if` explícitas. Puntos clave:
- Si un job es saltado por su `if`, los jobs dependientes también son saltados automáticamente.
- La condición `if` en `build-production` evalúa el ref de forma independiente — no depende de que `build-qa` haya corrido para decidir si ejecutar.
- Para push a main: los 3 jobs corren en cascada. Para push a qa: solo corren los primeros 2. Para PRs y dev: solo corre el primero.

### GitHub Repository Variables vs Secrets

Las Repository Variables (no secretas) son la herramienta correcta para URLs de ambiente — son visibles en logs, editables sin rotación, y no requieren aprobación de org. Los Secrets (`KEYSTORE_PASSWORD`, `KEY_PASSWORD`) se mantienen para credenciales sensibles.

---

## Archivos

### Modificados

```txt
.github/workflows/mobile-ci.yml
docs/roadmap.md
docs/frontend-architecture.md
docs/architecture.md
```

### Creados

```txt
docs/cicd-mobile.md
```

---

## Documentación

Ver: docs/cicd-mobile.md

---

# ETAPA 5.0.4.2
# Backend CI Pipeline

Estado:

✅ COMPLETADA

Fecha de cierre: 2026-05-28

---

## Objetivo

Crear pipeline GitHub Actions para el repositorio NestJS que valide automáticamente la calidad del código en cada etapa del ciclo de promoción de ramas, y verifique el estado del servicio QA al promover código a ese ambiente.

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

## Archivo creado

```txt
.github/workflows/backend-ci.yml
```

---

## Triggers

| Evento | Rama destino | Jobs ejecutados |
|--------|-------------|-----------------|
| `pull_request` | `dev` | Lint · Build · Validate |
| `pull_request` | `qa` | Lint · Build · Validate |
| `pull_request` | `main` | Lint · Build · Validate |
| `push` | `dev` | Lint · Build · Validate |
| `push` | `qa` | Lint · Build · Validate · **Health Check QA** |
| `push` | `main` | Lint · Build · Validate |

---

## Validaciones implementadas

### Job: validate (todos los triggers)

```txt
1. Checkout
2. Setup pnpm (latest) + Node.js LTS con cache pnpm
3. pnpm install --frozen-lockfile
4. pnpm lint      — ESLint sobre src/
5. pnpm build     — nest build (TypeScript completo)
6. prisma validate — valida schema.prisma sin conexión a BD
```

### Job: health-check-qa (solo push → qa)

```txt
7. Health Check QA
   GET $QA_API_URL/health → valida { status: "ok" }
```

---

## Decisiones de implementación

- **Flujo `feature/* → dev → qa → main`**: el CI está alineado con el ciclo de promoción real del proyecto.
- **Health Check QA en `push → qa`**: el push a `qa` dispara el despliegue a Railway QA — verificar el servicio en ese evento es semánticamente correcto.
- **Sin Health Check en `main`**: producción no tiene infraestructura activa todavía. Placeholder documentado en el workflow para cuando esté disponible.
- **DATABASE_URL dummy en CI**: `prisma generate` (postinstall) y `prisma validate` leen `prisma.config.ts` → `env('DATABASE_URL')`. El valor dummy satisface la resolución sin conexión real.
- **Sin tests en esta etapa**: los tests unitarios existentes (19) no se corren en este pipeline MVP — se incluirán en optimizaciones futuras.
- **Sin artefactos**: el alcance es solo validación de calidad, no publicación de builds.
- **Dos jobs separados**: `validate` y `health-check-qa` — separación clara de responsabilidades entre validación de código y verificación de ambiente.

---

## Variables requeridas en GitHub

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `QA_API_URL` | Variable (no Secret) | URL base del backend Railway QA |

Configurar en: GitHub → Settings → Secrets and variables → Actions → Variables

---

## Documentación

Ver: `docs/cicd-backend.md`

---

## Entregables

| Entregable | Descripción |
|-----------|-------------|
| `.github/workflows/backend-ci.yml` | Workflow GitHub Actions con job `validate` y job `health-check-qa` |
| `docs/cicd-backend.md` | Documentación completa del pipeline: triggers, jobs, variables, troubleshooting |
| `GET /health` | Endpoint implementado en ETAPA 5.0.2, consumido por el Health Check QA |
| `QA_API_URL` | Repository Variable configurada en GitHub Actions |
| `DATABASE_URL` dummy | Valor hardcodeado en el workflow para resolver `prisma.config.ts` sin BD real |

---

## Lecciones aprendidas

### prisma.config.ts requiere DATABASE_URL aunque no haya conexión

`prisma generate` y `prisma validate` cargan `prisma.config.ts` antes de ejecutar cualquier operación. La función `env('DATABASE_URL')` lanza `PrismaConfigEnvError` si la variable no está definida, independientemente de si se abre o no una conexión. La solución es definir un valor dummy a nivel de job en el workflow.

### postinstall como vector de fallo en CI

El script `postinstall` en `package.json` ejecuta `prisma generate` automáticamente al instalar dependencias. En entornos CI sin variables de entorno completas, este hook puede fallar con errores difíciles de trazar si no se anticipan las dependencias implícitas del comando.

### El Health Check QA debe vivir en `push → qa`, no en `push → main`

Ejecutar el health check en `main` valida el ambiente QA en un momento posterior al despliegue — la verificación pierde relevancia inmediata. El trigger correcto es `push → qa` porque ese evento corresponde al momento en que el código llega al ambiente QA.

### DATABASE_URL dummy no debe ser Secret

Un Secret de GitHub enmascara el valor en los logs y agrega fricción operativa. Dado que el valor es intencionalmente falso y no contiene credenciales reales, hardcodearlo en el workflow es más legible y auto-documentado.

---

# ETAPA 5.0.4.3
# Branch Protection & Status Checks

Estado:

✅ COMPLETADA

Fecha de cierre: 2026-05-29

---

## Objetivo

Configurar Branch Protection Rules en GitHub para los repositorios Mobile y Backend, garantizando que ningún PR pueda mergearse sin pasar los pipelines de CI definidos, y documentar la estrategia de protección de ramas.

---

## Implementación

Herramienta utilizada: **GitHub Rulesets** (Settings → Rules → Rulesets).

### Repositorio Backend (`tacos-manager-api`)

Ramas protegidas: `dev`, `qa`, `main`

Reglas activas por rama:
- Require Pull Request before merging
- Require status checks to pass
- Block force pushes
- Restrict deletions

Status Check requerido:
```txt
Backend • Lint, Build & Validate
```

### Repositorio Mobile (`TacosManager`)

Ramas protegidas: `dev`, `qa`, `main`

Reglas activas por rama:
- Require Pull Request before merging
- Require status checks to pass
- Block force pushes
- Restrict deletions

Status Check requerido:
```txt
Mobile • Lint & TypeCheck
```

---

## Estrategia final de protección de ramas

```txt
feature/* → dev → qa → main
```

| Rama | PR required | Force push | Delete | Status check (PR) |
|------|:-----------:|:----------:|:------:|-------------------|
| `dev` | ✅ | Bloqueado | Bloqueado | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` |
| `qa` | ✅ | Bloqueado | Bloqueado | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` |
| `main` | ✅ | Bloqueado | Bloqueado | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` |

Quality gates post-merge (no configurables como status checks de PR):

| Rama | Post-merge (Mobile) | Post-merge (Backend) |
|------|---------------------|----------------------|
| `dev` | lint + typecheck | lint + build + validate |
| `qa` | + APK QA | + Health Check QA |
| `main` | + APK QA + AAB Production | lint + build + validate |

---

## Status Checks obligatorios

| Repositorio | Status Check | Tipo |
|-------------|--------------|------|
| Mobile | `Mobile • Lint & TypeCheck` | PR check (branch protection) |
| Backend | `Backend • Lint, Build & Validate` | PR check (branch protection) |
| Mobile | `Mobile • Build QA APK` | Quality gate post-merge |
| Mobile | `Mobile • Build Production AAB` | Quality gate post-merge |
| Backend | `Backend • Health Check QA` | Quality gate post-merge (push a qa) |

---

## Riesgos mitigados

| Riesgo | Mitigación aplicada |
|--------|---------------------|
| Push directo a ramas compartidas | Bloqueado por Rulesets en dev/qa/main |
| Force-push que sobreescribe historial | Bloqueado por Rulesets |
| Eliminar ramas accidentalmente | Bloqueado por Rulesets |
| Merge sin CI verde | Require status checks to pass |
| Código de baja calidad llegando a QA | Lint + typecheck obligatorio en PR |
| Código de baja calidad llegando a main | Mismo check + quality gate post-merge |

---

## Lecciones aprendidas

### GitHub Rulesets vs Branch Protection (legacy)

GitHub ofrece dos sistemas: Branch Protection Rules (legacy) y Rulesets (nuevo). Se optó por **Rulesets** por ser el sistema activo recomendado, con mejor visibilidad en la UI y soporte para múltiples ramas en una sola regla.

### Los builds no son viables como PR checks

Los jobs `Mobile • Build QA APK` y `Mobile • Build Production AAB` son `skipped` en eventos `pull_request`. Un check `skipped` bloquea el PR si está configurado como requerido. La solución correcta es documentarlos como quality gates post-merge, no como PR checks.

Documentado en `docs/cicd-governance.md` sección "Limitaciones actuales".

### Prerrequisito: workflows deben haber corrido

Los status check names solo aparecen en el selector de GitHub después de que el workflow haya corrido al menos una vez en el repositorio. Verificar antes de configurar.

---

## Archivos

### Creados

```txt
docs/branch-strategy.md
docs/cicd-governance.md
```

### Modificados

```txt
docs/roadmap.md
docs/architecture.md
docs/cicd-backend.md
docs/cicd-mobile.md
docs/frontend-architecture.md
```

---

## Documentación

- `docs/branch-strategy.md` — estrategia de ramas completa
- `docs/cicd-governance.md` — configuración y guía paso a paso

---

# ETAPA 5.0.4.4
# CI/CD Conventions & Documentation

Estado:

⬜ PENDIENTE

---

## Objetivo

Documentar la estrategia CI/CD completa del proyecto para que sea mantenible sin depender del conocimiento tácito del desarrollador.

---

## Alcance

- Documento `docs/cicd-strategy.md` con:
  - Flujo PR → QA → Production (Mobile y Backend)
  - Relación entre repositorios Mobile ↔ Backend en CI
  - Convenciones de naming para workflows, jobs y artefactos
  - Guía de mantenimiento: cuándo actualizar secrets, cuándo tocar workflows
  - Riesgos identificados y mitigaciones
  - Decisiones arquitectónicas (por qué no Fastlane, por qué no Docker en CI, etc.)

---

## Flujo CI/CD Objetivo (post-5.0.4)

```txt
Pull Request abierto
  ├── Mobile:  lint → typecheck → build:qa  ──→ ✅/❌ Status Check
  └── Backend: lint → typecheck → tests → prisma validate ──→ ✅/❌ Status Check

Merge a main
  ├── Mobile:  validate + build:qa (APK artifact) → build:prod (AAB artifact)
  └── Backend: validate + tests + build dist

Artifacts disponibles en GitHub Actions:
  ├── app-qa-release-<sha>.apk      (30 días)
  └── app-production-release-<sha>.aab  (30 días)
```

---

# ETAPA 5.0.5
# Monitoring & Recovery

Estado:

⬜ PENDIENTE

---

## Objetivo

Instrumentar el sistema para detectar y recuperar errores en producción.

---

## Implementar

- Sentry (error tracking)
- Logging estructurado
- Alertas críticas

---

# ETAPA 5.0.6
# Production Validation

Estado:

⬜ PENDIENTE

---

## Objetivo

Validar operación completa del sistema en entorno productivo antes del release.

---

## Implementar

- Pruebas operativas completas
- Validación de flujos críticos (pedido → cocina → entrega)
- Verificación de multi-tenancy en producción

---

# ETAPA 5.0.7
# Play Store Release

Estado:

⬜ PENDIENTE

---

## Objetivo

Publicar la app en Google Play Store de forma gradual.

---

## Fases

- Internal Testing
- Closed Testing
- Production

---

# ETAPA 6.0
# Post Launch Features

Estado:

⬜ FUTURO

---

## Objetivo

Funcionalidades evaluadas para después del lanzamiento productivo.

Decisiones estratégicas y comerciales: docs/business-model.md

---

## QR Ordering

Pedidos iniciados por el cliente escaneando un código QR en la mesa.

---

## Customer Self Ordering

Portal o app para que los clientes realicen pedidos directamente.

---

## Analytics & Reports

Métricas de negocio:

- Ventas por día
- Productos más vendidos
- Ticket promedio
- Mesas más activas
- Rendimiento de cocina

---

## Advanced Delivery Management

Gestión avanzada de domicilios:

- Seguimiento de entrega
- App de repartidores
- Estados adicionales de DELIVERY

---

## Reporting

Reportes avanzados para administración y toma de decisiones.

---

## History & Filters Avanzado

Extensiones al historial y filtros de pedidos (ex-ETAPA 4.8).

---

## Performance Optimization

Índices Prisma, paginación, optimización de queries para múltiples taquerías (ex-ETAPA 4.9).

---

## Product Management Improvements

Edición de complementos y eliminación de productos desde UI (ex-ETAPA 4.10).

---

# Definition of Done

Una etapa se considera completada cuando:

- Todas las reglas de negocio funcionan
- Ownership validado
- Multi-tenant validado
- Tests manuales aprobados
- Documentación actualizada
- Feature list actualizado
- Sin errores críticos

---

# Documentos Relacionados

- docs/business-rules.md
- docs/business-model.md
- docs/architecture.md
- docs/api-reference.md
- docs/roadmap.md

---

# Próxima Etapa

ETAPA 5.0.4 🟡 CI/CD Automation — etapa activa actual.

Expandir pipeline CI/CD para Mobile y Backend con enfoque MVP Production Ready.

Paralelo activo: ETAPA 5.0.2 Backend Deployment (Railway + PostgreSQL).

Sin nuevas funcionalidades de negocio — el foco es infraestructura y despliegue.

Ver estrategia comercial y costos en: docs/business-model.md
Ver estrategia CI/CD en: docs/cicd-strategy.md (se crea en ETAPA 5.0.4.4)

ETAPA 4.5 ✅ completada. ETAPA 4.6 ✅ completada. ETAPA 4.7 ✅ completada.
ETAPA 5.0.3 ✅ completada (2026-05-27).
