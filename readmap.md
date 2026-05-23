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

## En Progreso

- 4.5.3 Orders API Migration

## Pendiente

- 4.5.4 Socket.IO Realtime Integration
- 4.5.5 Firebase Removal & Cleanup
- 4.6 Realtime Reliability
- 4.7 History & Filters
- 4.8 Performance Optimization
- 4.9 Product Management Improvements
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

⬜ PENDIENTE

---

## Objetivos

Migrar módulo de órdenes de Firestore a la API NestJS.

---

# ETAPA 4.5.4
# Socket.IO Realtime Integration

Estado:

⬜ PENDIENTE

---

## Objetivos

Conectar frontend a Socket.IO del backend.

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

# ETAPA 4.6
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

# ETAPA 4.7
# History & Filters

Estado:

⬜ PENDIENTE

---

## Objetivos

Filtros históricos.

---

## Opciones

### Hoy

Default.

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

# ETAPA 4.8
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

# ETAPA 4.9
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

ETAPA 4.5.3

Orders API Migration

Objetivo:

Migrar el módulo de órdenes de Firestore a la API NestJS.