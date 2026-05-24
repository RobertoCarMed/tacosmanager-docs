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
- 4.6.1 Backend Schema & API
- 4.6.2 Frontend Create/Edit Order

## En Progreso

- 4.6.3 Kitchen Integration 🟡

## Pendiente

- 4.5.6 Kitchen Queue Refinements
- 4.7 Realtime Reliability
- 4.8 History & Filters
- 4.9 Performance Optimization
- 4.10 Product Management Improvements
- Analytics
- Production Deployment

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

- UPDATED
- PENDING
- PREPARING
- READY
- DELIVERED
- CANCELLED

---

## Prioridad Global

1. UPDATED
2. PENDING
3. PREPARING
4. READY
5. DELIVERED
6. CANCELLED

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

Visible durante:

- UPDATED
- PREPARING

Desaparece:

- READY

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

⬜ PENDIENTE

---

## Contexto y Cambio de Dirección

Durante el análisis funcional de la cola de cocina se detectaron problemas estructurales con el estado `UPDATED` que generaban ambigüedad, ruptura de FIFO y comportamiento no determinista.

Después del análisis se tomó la decisión de **deprecar completamente el estado `UPDATED`** en lugar de parchar su comportamiento.

La estrategia aprobada reemplaza `UPDATED` como señal de modificación por un mecanismo de seguimiento de cambios a nivel de pedido o de ítem.

---

## Estado UPDATED — Deprecado

El estado `UPDATED` queda **oficialmente deprecado** y no debe considerarse parte del flujo futuro del sistema.

Mientras la migración no esté completa, `UPDATED` sigue existiendo en el schema como estado legado.

El flujo de estados oficiales pasa a ser:

```txt
PENDING → PREPARING → READY → DELIVERED
```

`CANCELLED` permanece disponible como salida en cualquier punto del flujo.

---

## Razón del Cambio

El estado UPDATED generaba:

- Ruptura de FIFO: pedidos PENDING saltaban por delante de otros PENDING al modificarse
- Priorización no determinista: la posición del pedido cambiaba por acciones del mesero, no del cocinero
- Ambigüedad en cocina: UPDATED y PENDING compartían la misma acción (Marcar preparando), duplicando semánticamente dos estados distintos
- Complejidad innecesaria en Realtime: el estado cambiaba sin intervención del cocinero
- UX degradada: el cocinero veía pedidos reorganizarse sin haberlos tocado

---

## Nuevo Mecanismo de Seguimiento de Cambios

Las modificaciones posteriores a la creación del pedido ya **no generan cambio de estado**.

En su lugar se introduce un mecanismo de tracking de cambios pendientes.

El mecanismo exacto queda por definir en la implementación, con posibles enfoques:

- Campo `hasPendingChanges` a nivel de Order
- Colección `pendingChanges` asociada al pedido
- Tracking a nivel de ítem por `createdInRevision`

Lo que debe garantizarse independientemente del mecanismo:

- Cocina puede identificar rápidamente qué productos son nuevos en un pedido
- Los productos nuevos se distinguen visualmente (color, badge, indicador)
- El cambio es visible sin que el pedido cambie de posición en la cola

---

## Reglas de Negocio Aprobadas

### CASO 1 — Pedido en PENDING recibe modificaciones

El pedido permanece en PENDING.

No cambia de prioridad.

No cambia de posición en la cola.

No altera el FIFO.

Los productos nuevos se marcan internamente como pendientes.

---

### CASO 2 — Pedido en PREPARING recibe modificaciones

El pedido permanece en PREPARING.

No cambia de prioridad.

No abandona la parte superior de la cola activa.

Los productos nuevos se destacan visualmente para el cocinero.

---

### CASO 3 — Pedido en READY recibe modificaciones

El pedido regresa automáticamente a PENDING.

Cocina debe preparar los productos nuevos antes de marcarlo listo nuevamente.

Los productos nuevos se destacan visualmente.

---

## Ordenamiento de la Cola de Cocina

### Prioridad (implementación objetivo)

```txt
1. PREPARING  — trabajo activo del cocinero, siempre visible arriba
2. PENDING    — trabajo por iniciar, orden FIFO
3. READY      — listo para entregar
4. DELIVERED  — fuera de la cola activa
5. CANCELLED  — fuera de la cola activa
```

`UPDATED` eliminado del ordenamiento.

### FIFO

Dentro de cada grupo se mantiene FIFO por `priorityTimestamp ASC` (o `createdAt ASC` para PENDING).

Las modificaciones a un pedido PENDING no actualizan su `priorityTimestamp`.

---

## Visualización de Productos Nuevos

Los productos agregados después de la creación original deben diferenciarse visualmente en cocina.

Mecanismos posibles:

- Badge o indicador de color verde
- Highlight de fondo en el ítem
- Sección separada "Productos agregados" dentro del card

Objetivo: el cocinero identifica en segundos qué fue lo último que se agregó al pedido sin necesidad de releer todo el card.

---

## Objetivos de la Etapa

- Eliminar la ambigüedad del estado UPDATED
- Restaurar el FIFO consistente para pedidos PENDING
- Mantener PREPARING visible en la parte superior de la cola
- Mejorar la experiencia del cocinero evitando reordenamientos inesperados
- Facilitar la identificación de cambios recientes sin alterar el estado del pedido
- Lograr comportamiento determinista: la cola solo cambia por acciones del cocinero

---

## Archivos afectados (pendiente de definición técnica)

Backend:

- `src/orders/orders.service.ts`
- `prisma/schema.prisma` (si se agrega campo de tracking)
- DTOs de órdenes

Frontend:

- Lógica de visualización en Kitchen OrderCard
- Posiblemente lógica de filtro en KitchenScreen

La implementación exacta se definirá al iniciar esta etapa.

---

# ETAPA 4.6
# Order Classification System (Épica Principal)

Estado:

🟡 EN PROGRESO

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
  PENDING | UPDATED | PREPARING | READY | DELIVERED | CANCELLED

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

🟡 EN PROGRESO

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

⬜ PENDIENTE

---

## Objetivos

Preparar producción.

---

## Implementar

- Reconnection Strategy
- Heartbeats
- Connection Recovery
- Cleanup
- Memory Leak Prevention

---

## Resultado esperado

Realtime estable en producción.

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

# ETAPA 5
# Analytics & Reports

Estado:

⬜ FUTURO

---

## Objetivos

Métricas de negocio.

---

## Ejemplos

- Ventas por día
- Productos más vendidos
- Ticket promedio
- Mesas más activas
- Rendimiento de cocina

---

# ETAPA 6
# Production Infrastructure

Estado:

⬜ FUTURO

---

## Objetivos

Preparar despliegue profesional.

---

## Implementar

- CI/CD
- GitHub Actions
- VPS
- Reverse Proxy
- SSL
- Monitoring
- Logging
- Backups

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
- docs/architecture.md
- docs/api-reference.md
- docs/roadmap.md

---

# Próxima Etapa

ETAPA 4.6.3

Kitchen Integration

Objetivo:

Adaptar el Kitchen Display System (KDS) para mostrar correctamente los tipos de pedido con emoji + referencia.

```txt
DINE_IN   →  🍽 Mesa 4
TAKEAWAY  →  🥡 Roberto
DELIVERY  →  🛵 Av. Juárez #123...
```

Kitchen NO agrupa por tipo. FIFO y priorización de estados sin cambios.

---

Tras 4.6.3:

ETAPA 4.5.6

Kitchen Queue Refinements

Objetivo:

Implementar promoción condicional a UPDATED según el estado del pedido, y cambiar el orden de prioridad de cocina a PREPARING > UPDATED > PENDING > READY > DELIVERED > CANCELLED.
