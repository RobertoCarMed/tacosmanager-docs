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

## En Progreso

- 4.5.4 Socket.IO Realtime Integration

## Pendiente

- 4.5.4 Socket.IO Realtime Integration
- 4.5.5 Firebase Removal & Cleanup
- 4.5.6 Kitchen Queue Refinements
- 4.6 Order Classification System
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

🟡 EN PROGRESO

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

⬜ PENDIENTE

---

## Objetivos

Eliminar completamente Firebase del proyecto.

---

## Acciones

- Remover @react-native-firebase/auth
- Remover @react-native-firebase/firestore (si se migró en 4.5.2-4.5.3)
- Remover @react-native-firebase/storage
- Remover @react-native-firebase/app
- Eliminar src/services/firebase/
- Limpiar src/config/env.ts (variables Firebase)
- Eliminar servicios Firestore de features/auth/

---

# ETAPA 4.5.6
# Kitchen Queue Refinements

Estado:

⬜ PENDIENTE

---

## Contexto

Durante las pruebas funcionales posteriores a la migración de Orders (ETAPA 4.5.3) se detectaron dos problemas en la lógica de priorización de la cola de cocina.

Los problemas no bloquean la operación actual pero generan comportamientos subóptimos detectables en uso real.

Los cambios requeridos son exclusivamente en el backend (`src/orders/orders.service.ts`). El frontend no requiere modificaciones.

---

## Problema 1 — Promoción incorrecta a UPDATED para pedidos PENDING

### Descripción

Cuando un mesero agrega productos a un pedido en estado PENDING (el cocinero aún no lo ha comenzado), el backend actualmente siempre cambia el status a UPDATED y actualiza el `priorityTimestamp`.

Esto causa que el pedido salte por delante de otros pedidos PENDING que llegaron antes, rompiendo el orden FIFO dentro del grupo PENDING.

### Ejemplo del problema

Pedido A → PENDING (12:00)

Pedido B → PENDING (12:05)

Pedido C → PENDING (12:10) — el mesero le agrega productos a las 12:11

Resultado actual (incorrecto):

1. Pedido C (UPDATED — promovido incorrectamente, priorityTimestamp = 12:11)
2. Pedido A (PENDING)
3. Pedido B (PENDING)

Resultado esperado:

1. Pedido A (PENDING — más antiguo, priorityTimestamp = 12:00)
2. Pedido B (PENDING — priorityTimestamp = 12:05)
3. Pedido C (PENDING — sigue en PENDING, priorityTimestamp = 12:10)

### Regla propuesta

Si el status actual es PENDING cuando se llama PATCH /orders/:id:

- Mantener status PENDING
- No activar isNew en los items agregados
- No actualizar priorityTimestamp

Si el status actual es PREPARING (o superior) cuando se llama PATCH /orders/:id:

- Cambiar status a UPDATED
- Activar isNew en los items nuevos
- Actualizar priorityTimestamp a now()

---

## Problema 2 — Prioridad incorrecta para pedidos PREPARING

### Descripción

Los pedidos en PREPARING (que el cocinero ya comenzó a preparar) tienen actualmente menor prioridad que UPDATED y PENDING, lo que hace que se desplacen hacia abajo de la cola mientras el cocinero los trabaja.

### Prioridad actual (problemática)

1. UPDATED
2. PENDING
3. PREPARING
4. READY
5. DELIVERED
6. CANCELLED

### Prioridad propuesta

1. PREPARING
2. UPDATED
3. PENDING
4. READY
5. DELIVERED
6. CANCELLED

### Justificación

Un pedido en PREPARING representa trabajo activo del cocinero. Debe mantenerse visible en la parte superior hasta que pase a READY. UPDATED y PENDING representan trabajo pendiente de iniciar.

---

## FIFO dentro de cada grupo

El orden FIFO por priorityTimestamp ASC se mantiene de forma independiente dentro de cada grupo de estado.

---

## Archivos afectados

Backend:

- `src/orders/orders.service.ts`

Frontend:

Ninguno. El frontend ya respeta el orden retornado por la API.

---

# ETAPA 4.6
# Order Classification System

Estado:

⬜ PENDIENTE

---

## Justificación

Los pedidos actualmente solo tienen `tableNumber` como identificador visual y `status` para el estado de cocina.

No existe clasificación funcional que distinga:

- Pedidos para comer dentro del restaurante
- Pedidos para recoger y llevar
- Pedidos para entrega a domicilio

Esta clasificación aporta valor operativo para meseros, cocina, repartidores, reportes futuros y la operación diaria del restaurante.

---

## Nuevo campo — OrderType

```txt
enum OrderType {
  DINE_IN
  TAKEAWAY
  DELIVERY
}
```

OrderType NO reemplaza OrderStatus.

Son conceptos independientes.

---

## Evolución del modelo Order

El campo `tableNumber` se reemplaza conceptualmente por:

```txt
reference: string | null
```

Representa el identificador visual utilizado por el personal para localizar el pedido.

Se agrega además:

```txt
deliveryAddress: string | null
```

Para pedidos tipo DELIVERY.

---

## Validaciones

DINE_IN:

- reference: obligatorio (ej. "Mesa 4", "Terraza 2")
- deliveryAddress: no aplica

TAKEAWAY:

- reference: obligatorio — nombre del cliente (ej. "Roberto", "Juan Pérez")
- deliveryAddress: no aplica

DELIVERY:

- deliveryAddress: obligatoria (ej. "Av. Juárez #123")
- reference: opcional

---

## Comportamiento UI

Selector al crear pedido:

```txt
🍽 Comer aquí  →  campo "Referencia"     placeholder: Mesa 4
🥡 Para llevar  →  campo "Nombre cliente" placeholder: Roberto
🛵 Delivery     →  campo "Dirección"      placeholder: Av. Juárez #123
```

---

## Comportamiento Kitchen

Los pedidos se identifican visualmente mediante emoji + referencia:

```txt
🍽 Mesa 4
🥡 Roberto
🛵 Av. Juárez #123
```

No se muestra el tipo de forma textual explícita.

El emoji y la referencia visual son suficientes para identificar la modalidad.

---

## Regla READY

READY mantiene el mismo significado para todos los tipos:

"Pedido completamente preparado y listo para ser entregado."

- Mesero puede llevarlo a la mesa (DINE_IN).
- Cliente puede recogerlo (TAKEAWAY).
- Repartidor puede salir a entregarlo (DELIVERY).

No se agregan estados adicionales para ningún tipo en esta etapa.

---

## Alcance MVP

Los pedidos DELIVERY son capturados exclusivamente por personal interno.

No existe:

- Integración con clientes externos
- Portal web
- QR Ordering
- Self-ordering

Estas funcionalidades podrán evaluarse en etapas posteriores a producción.

---

## Archivos afectados

Backend:

- `src/orders/orders.service.ts`
- `src/orders/orders.controller.ts`
- `src/orders/dto/create-order.dto.ts`
- `prisma/schema.prisma`
- Nueva migración Prisma

Frontend:

- `src/shared/types/domain.ts`
- `src/features/orders/hooks/useCreateOrder.ts`
- `src/features/orders/screens/CreateOrderScreen.tsx`
- `src/features/kitchen/components/OrderCard.tsx`

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

ETAPA 4.5.4

Socket.IO Realtime Integration

Objetivo:

Conectar el frontend a Socket.IO del backend para actualización en tiempo real entre cocina y meseros.