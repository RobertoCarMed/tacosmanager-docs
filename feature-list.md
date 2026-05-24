# 🌮 TacosManager — Feature List

## 📌 Project Overview

TacosManager is a real-time restaurant management system focused on taquerías.

The app is designed to manage:
- waiter order creation
- kitchen order visualization
- realtime order synchronization
- product management
- restaurant staff organization

The project currently works as a:
- POS-like system
- Kitchen Display System (KDS)
- realtime operational workflow for restaurants

---

# 🧑‍💼 User Roles

The system currently supports two roles:

## 👨‍🍳 Cook (`cook`)
Responsible for:
- viewing all restaurant orders
- changing order statuses
- managing products
- monitoring realtime updates

---

## 🧑‍🍽️ Waiter (`waiter`)
Responsible for:
- creating orders
- editing existing orders
- adding products to existing orders
- viewing only their own orders

---

# 🔐 Authentication System

## ✅ Email & Password Login (NestJS JWT — ETAPA 4.5.1)
Users authenticate using:
- email
- password

Authentication is handled exclusively by the NestJS backend via `POST /auth/login`.

On success, the backend returns:
- `accessToken` (JWT, 1 day expiration)
- `user` (id, name, email, role, taqueriaId)
- `taqueria` (id, name, restaurantCode, address, city, state)

The token is persisted locally with AsyncStorage for session restore.

## ✅ Session Restore
On app start, the frontend:
- Reads the stored accessToken from AsyncStorage
- Calls `GET /auth/me` to validate the session
- Restores user and taqueria context if token is valid
- Redirects to Login if token is missing or expired

## ✅ Logout
On logout:
- accessToken is removed from AsyncStorage
- User and taqueria are cleared from AuthContext
- App navigates to Login screen

---

# 🏪 Taquería System

## ✅ Taquería Relationship Rules

- A user belongs to ONE taquería
- A taquería can have MANY users

---

## ✅ Taquería Registration Flow (Smart Multi-Match — ETAPA 4.5.1)

During registration, the backend is called in 2 phases:

**Phase 1 — Discovery (no side effects):**
- User fills: name, email, password, role, taqueriaName
- Backend returns match count and available taquerías

**Phase 2A — Join existing taquería:**
- User selects a taquería by restaurantCode
- Backend creates the user linked to the existing taquería
- Returns accessToken + user + taquería

**Phase 2B — Create new taquería:**
- User fills optional: address, city, state
- Backend creates a new taquería with unique restaurantCode
- Returns accessToken + user + taquería

**Match scenarios:**
- 0 matches → directly go to create flow
- 1 match → show the match, offer join or create new
- N matches → show list with restaurantCode, user selects

## ✅ Taquería Fields

Each taquería contains:

- id
- name
- restaurantCode (unique tenant identifier)
- address (optional)
- city (optional)
- state (optional)
- phone (optional)
- createdAt

---

# 🍽️ Product Management

## ✅ Product Creation (NestJS API — ETAPA 4.5.2)

Cooks can create products via `POST /products`.

Each product supports:

- product name
- price
- image (Firebase Storage → imageUrl persisted via API)
- complements (max 3)

---

## ✅ Product Listing (NestJS API — ETAPA 4.5.2)

Products are loaded from `GET /products`.

- Cache-first strategy with background refresh on screen focus
- Only products from the current taquería are returned (multi-tenant enforced by JWT)

---

## ✅ Product Edit — Fields available from UI (NestJS API — ETAPA 4.5.2)

Cooks can update existing products via `PATCH /products/:id`.

Fields editable from the current UI:
- name
- price
- image (Firebase Storage → new imageUrl persisted via API)

Notes:
- Only changed fields are sent in the PATCH request
- New image is uploaded to Firebase Storage before patching
- Old image is deleted from Firebase Storage after successful upload

---

## ⬜ Product Edit — Complement editing from UI (Pendiente — ETAPA 4.9)

The backend supports updating `complements` via `PATCH /products/:id`.

The current `EditProductScreen` does NOT expose complement editing.

This is a known pending feature — the service layer already supports it.

---

## ⬜ Product Delete from UI (Pendiente — ETAPA 4.9)

`DELETE /products/:id` is fully implemented in the service layer (`productService.deleteProduct`).

The current UI has NO button or flow to delete a product.

This is a known pending feature — the service layer already supports it.

---

## ✅ Product Images

Products may contain:

- uploaded image (stored in Firebase Storage, URL persisted via API)
- fallback placeholder image

If no image is selected:
- image upload is skipped
- only product data is saved

---

## ✅ Product Ownership

Products are linked to the taquería via JWT.

Rules:
- A taquería can have many products
- Different taquerías can have products with same name
- Each taquería can define its own prices
- `taqueriaId` is never sent from the frontend — backend extracts it from the JWT

---

# 🌮 Product Complements

## ✅ Complement System

Each product can contain:
- 0 to 3 complements

Examples:
- cilantro
- cebolla
- salsa

---

## ✅ Complement Selection

When waiter selects a product:

- complements are displayed dynamically
- waiter can enable/disable complements
- complements are saved with the order

UI uses:
- checkboxes

---

# 🧑‍🍽️ Waiter Features

---

# 📋 Waiter Orders Screen

## ✅ Order Visualization

Waiters can view:
- their created orders
- order status
- order details

---

# ➕ Create Order Flow

## ✅ Order Fields

Each order supports:

- table number and/or client name
- multiple plates
- multiple products per plate
- quantities
- complements

---

# 🍽️ Plate System

Orders are grouped by plates.

Example:

```txt
PLATE 1
- 3 tacos adobada
- 2 tacos asada

PLATE 2
- 4 tacos chorizo
```

---

# 🧾 Product Selection

## ✅ Product Selector

Products are loaded dynamically from the NestJS API (`GET /products`).

Products shown:
- only products from current taquería (enforced server-side via JWT)

---

## ✅ Quantity Selector

Each selected product supports:
- increase quantity
- decrease quantity
- dynamic counter

---

## ✅ Product Image Preview

When product is selected:
- image is displayed if exists
- placeholder image otherwise

---

# 💰 Pricing System

## ✅ Price Features

Each order supports:

- unit price
- subtotal per item
- total order cost

Current format:

```txt
2x Taco Asada     $30 | $60
```

---

# ✏️ Edit Existing Orders

## ✅ Edit Order Flow

Waiter can:

1. Select an existing order
2. Press edit button
3. Navigate to edit screen
4. Add new products
5. Save changes

---

## ✅ Edit Restrictions

Waiter CANNOT:
- modify table/client
- remove existing closed items

Waiter CAN:
- add new products
- add new plates

---

# 👨‍🍳 Kitchen Display System (KDS)

---

# 📺 Kitchen Screen

Optimized for:
- horizontal layout
- 10-inch tablets
- long-distance readability

---

# 📋 Kitchen Order Cards

## ✅ Order States

Current states:

- PENDIENTE
- ACTUALIZADA
- PREPARANDO
- LISTO

---

# 🔥 Order Priority System

Current priority order:

1. ACTUALIZADA
2. PENDIENTE
3. PREPARANDO
4. LISTO

---

# 🏷️ Order Classification System (Pendiente — ETAPA 4.6)

## ⬜ OrderType — Clasificación de pedido

Each order will have an `orderType` field that determines its consumption modality:

- `DINE_IN` — consume inside the restaurant
- `TAKEAWAY` — customer picks up at the counter
- `DELIVERY` — delivered to an address

`orderType` is independent of `orderStatus`. They represent different dimensions of an order.

---

## ⬜ Reference Field — Identificador visual del pedido

The `tableNumber` field will be replaced conceptually by a `reference` field.

`reference` represents the visual label used by staff to locate an order.

Examples by type:
- `DINE_IN`: "Mesa 4", "Terraza 2", "Barra 3"
- `TAKEAWAY`: "Roberto", "Juan Pérez"
- `DELIVERY`: null (address is used instead)

---

## ⬜ Delivery Address — Dirección de entrega

A new `deliveryAddress` field will be added for `DELIVERY` orders.

Rules:
- Required for `DELIVERY`
- Null for `DINE_IN` and `TAKEAWAY`

---

## ⬜ OrderType Selector — UI al crear pedido

When creating an order, the waiter selects the modality first:

```
🍽 Comer aquí
🥡 Para llevar
🛵 Delivery
```

The displayed input field changes dynamically:
- `DINE_IN` → "Referencia" (placeholder: Mesa 4)
- `TAKEAWAY` → "Nombre cliente" (placeholder: Roberto)
- `DELIVERY` → "Dirección" (placeholder: Av. Juárez #123)

---

## ⬜ Kitchen OrderType Badge — Identificación visual en cocina

The KDS (Kitchen Display System) shows a badge combining emoji + reference for each order:

```
🍽 Mesa 4
🥡 Roberto
🛵 Av. Juárez #123
```

No extra text labels. The emoji alone identifies the modality at a glance.

---

## ⬜ READY is universal — Sin estados adicionales por tipo

The `READY` status means the same thing for all order types:

> "Order fully prepared and ready to be delivered."

- Waiter takes it to the table (DINE_IN)
- Customer picks it up (TAKEAWAY)
- Delivery person takes it out (DELIVERY)

No additional statuses (e.g. "OUT FOR DELIVERY") in ETAPA 4.6.

---

## ⬜ MVP Delivery Scope — Captura interna

`DELIVERY` orders are captured by internal staff only.

No customer-facing portals, QR ordering, or self-ordering in ETAPA 4.6.

---

# 🔧 Kitchen Queue Refinements (Pendiente — ETAPA 4.5.6)

Two problems detected during post-migration functional testing (ETAPA 4.5.3):

## ⬜ Diferenciar actualización de pedido antes y después del servicio

The backend will apply different logic to `PATCH /orders/:id` depending on the current order status:

- If status is `PENDING` → keep `PENDING`, no `isNew`, no `priorityTimestamp` update
- If status is `PREPARING` or higher → promote to `UPDATED`, activate `isNew`, update `priorityTimestamp`

---

## ⬜ Evitar promoción automática a UPDATED cuando el pedido continúa en PENDING

A `PENDING` order that receives new products must remain `PENDING`.

This prevents the order from jumping ahead of older `PENDING` orders in the kitchen queue.

---

## ⬜ Mantener posición FIFO original para pedidos PENDING actualizados

When a `PENDING` order receives new products, its `priorityTimestamp` must NOT be updated.

The order must keep its original position in the FIFO queue within the `PENDING` group.

---

## ⬜ Priorizar visualmente pedidos PREPARING

Orders currently being prepared by the cook must appear at the top of the kitchen queue.

Proposed new priority:

1. PREPARANDO
2. ACTUALIZADA
3. PENDIENTE
4. LISTO

---

## ⬜ Mantener FIFO independiente dentro de cada grupo de estado

FIFO ordering by `priorityTimestamp ASC` is maintained independently within each status group, regardless of the priority reordering above.

---

# ✨ Realtime Order Updates

When waiter edits an order:

## ✅ Kitchen Behavior

- order status changes to ACTUALIZADA
- order moves to top priority
- newly added products are highlighted
- new plates appear first

---

# 🟢 New Product Highlighting

New products inside edited orders:

- highlighted with soft green color
- visible immediately to cook

When order becomes PREPARANDO:
- green highlight disappears

---

# 🎨 KDS UI Features

## ✅ Large Readable UI

Includes:
- large cards
- readable typography
- optimized spacing
- operational workflow design

---

## ✅ Animations

Current animations:
- fade out
- automatic reorder
- smooth transitions

---

# ⚙️ Settings Screen

## ✅ Configuration Options

Current actions:

- logout
- add product
- edit product

---

# ☁️ Firebase Integration

Current Firebase services (pending migration in ETAPA 4.5.4–4.5.5):

- ~~Firebase Auth~~ → **Migrated to NestJS JWT (ETAPA 4.5.1)**
- ~~Firestore (products)~~ → **Migrated to NestJS API (ETAPA 4.5.2)**
- ~~Firestore (orders)~~ → **Migrated to NestJS API (ETAPA 4.5.3)**
- Firebase Storage (images only — kept intentionally; no backend upload endpoint)

---

# 🔄 Realtime Features

## ✅ Realtime Synchronization (Socket.IO — ETAPA 4.5.4)

Frontend connected to backend Socket.IO via `socket.io-client@4`.

Realtime updates include:

- `order-created` → new order inserted in Redux without REST refetch
- `order-updated` → existing order replaced in Redux (append-only payload)
- `order-status-changed` → order status updated in Redux instantly

Kitchen screen reacts to all events automatically via LayoutAnimation.

No polling. No manual refresh. No redundant GET /orders after socket events.

---

# 📅 Historical Filters (Planned / In Progress)

Both cook and waiter screens support:

- today
- last 7 days
- last month
- last 3 months

---

# 🧠 Current Technical Stack

## Frontend

- React Native
- TypeScript

---

## Current Backend

- NestJS (Auth — ETAPA 4.5.1, Products — ETAPA 4.5.2, Orders — ETAPA 4.5.3)
- ~~Firebase Firestore~~ → fully migrated to NestJS API (Auth 4.5.1, Products 4.5.2, Orders 4.5.3)
- Firebase Storage (product images — kept intentionally)

---

## Current Architecture

- JWT authentication via NestJS API
- AsyncStorage token persistence
- Context API (AuthContext) — session management
- NestJS API (products — ETAPA 4.5.2, orders — ETAPA 4.5.3)
- Firebase Storage (product images — kept intentionally)
- role-based rendering
- taquería-based multi-tenancy

---

# 🚀 Current MVP Status

The project currently includes:

- authentication
- realtime order system
- kitchen display system
- product catalog
- complements system
- pricing system
- order editing
- realtime kitchen prioritization
- multi-user taquería workflow
- role-based permissions
- tablet-optimized UI

---

# 📌 IMPORTANT DEVELOPMENT RULE

Whenever a new feature is implemented in this project:

1. The codebase MUST be updated
2. This markdown feature list MUST also be updated
3. New features should include:
   - feature description
   - affected roles
   - UI behavior
   - realtime behavior (if applicable)
   - technical notes if important

---

# Backend Migration Progress (NestJS + Prisma)

## Implemented: Prisma Enterprise Integration

### Technical scope

- Added global Prisma architecture for NestJS:
  - `src/prisma/prisma.service.ts`
  - `src/prisma/prisma.module.ts`
- Root module integration:
  - `src/app.module.ts` imports `PrismaModule`
- Application service integration:
  - `src/app.service.ts` injects Prisma service
  - Real database query enabled with `prisma.taqueria.findMany()`

### Behavior

- Root endpoint now validates live PostgreSQL access through Prisma.
- Response payload:
  - `message: Prisma funcionando 🚀`
  - `taquerias: [] | Taqueria[]`

### Architecture notes

- Prisma service uses `OnModuleInit` and `this.$connect()`.
- Connection guard prevents redundant connection initialization in module lifecycle.
- Structure is ready for modular growth and future realtime features (Socket.IO) without changing data access foundation.

---

# Backend Migration Progress (FASE 2 - Auth NestJS + Prisma + JWT)

## Implemented: Professional Authentication System

### New backend modules

- `src/auth`
  - `auth.module.ts`
  - `auth.controller.ts`
  - `auth.service.ts`
  - `dto/register.dto.ts`
  - `dto/login.dto.ts`
  - `guards/jwt-auth.guard.ts`
  - `guards/roles.guard.ts`
  - `roles.decorator.ts`
  - `strategies/jwt.strategy.ts`
- `src/users`
  - `users.module.ts`
  - `users.service.ts`

### New authentication endpoints

- `POST /auth/register`
  - Creates taquerÃ­a + initial user in a single flow
  - Supports roles: `WAITER`, `COOK`
  - Validates unique email
  - Hashes password with `bcrypt`
- `POST /auth/login`
  - Validates credentials (`email`, `password`)
  - Compares password with `bcrypt.compare`
  - Returns:
    - `accessToken`
    - `user`
    - `taqueria`
- `GET /auth/me` (protected)
  - Validates JWT with `JwtAuthGuard`
  - Applies role authorization with `RolesGuard`
  - Returns authenticated user context

### Security and validation

- JWT authentication configured with:
  - `@nestjs/jwt`
  - `@nestjs/passport`
  - `passport-jwt`
  - `JWT_SECRET` from `.env`
  - token expiration (`1d`)
- Global `ValidationPipe` enabled with:
  - `whitelist: true`
  - `forbidNonWhitelisted: true`
  - `transform: true`
- DTO validation with:
  - `class-validator`
  - `class-transformer`
- Controlled error handling:
  - `UnauthorizedException`
  - `ConflictException`
  - `BadRequestException`
- Passwords are never returned in API responses.

### Backend architecture notes

- Enterprise modular design kept (`AuthModule`, `UsersModule`, `PrismaModule`).
- `PrismaService` remains singleton-based with `OnModuleInit`.
- Auth domain separated from data access (`UsersService`) to avoid logic duplication.
- Base ready for future role-based guards and Socket.IO realtime integration under JWT context.

---

# Backend Migration Progress (FASE 3 - Products Module NestJS + Prisma)

## Implemented: Professional Products Catalog in PostgreSQL

### New backend module

- `src/products`
  - `products.module.ts`
  - `products.controller.ts`
  - `products.service.ts`
  - `dto/create-product.dto.ts`
  - `dto/update-product.dto.ts`
  - `interfaces/authenticated-user.interface.ts`

### New products endpoints

- `POST /products` (COOK only)
- `GET /products` (COOK + WAITER)
- `GET /products/:id` (COOK + WAITER)
- `PATCH /products/:id` (COOK only)
- `DELETE /products/:id` (COOK only)

All endpoints are protected with JWT (`JwtAuthGuard`) and role authorization (`RolesGuard` + `Roles` decorator).

### Multi-taquerÃ­a ownership model

- Product ownership is derived from authenticated `request.user.taqueriaId`.
- Backend never accepts `taqueriaId` from frontend for product ownership.
- Users can only read/modify/delete products belonging to their own taquerÃ­a.
- Cross-taquerÃ­a access is blocked with explicit authorization checks.

### Business validations implemented

- `name` required
- `price` required and positive (`> 0`)
- `complements` optional with max 3 values
- `imageUrl` optional and URL validated
- Product existence checks for read/update/delete
- Ownership checks for update/delete operations

### Security and error handling

- `ForbiddenException` for unauthorized role actions and cross-taquerÃ­a access
- `NotFoundException` for non-existing products
- `BadRequestException` for invalid complements/business validation failures
- `UnauthorizedException` handled through JWT guard flow
- Responses are intentionally minimal (no oversized relations)

### Architecture notes

- Clean controller/service separation maintained.
- Strong typing preserved (no `any`).
- Prisma access remains centralized via `PrismaService` singleton.
- Design is ready for future Socket.IO realtime events, image upload pipelines, analytics, soft delete, and audit trails.

---

# Backend Migration Progress (FASE 4 - Multi-Taqueria Integrity Fix)

## Implemented: Anti-duplication registration + join-taqueria flow

### Database architecture updates

- `Taqueria.name` is now unique.
- `Taqueria.restaurantCode` added as unique short code.
- `restaurantCode` is generated automatically during taqueria creation.

### Auth flow changes

- `POST /auth/register`
  - If taqueria does not exist:
    - creates taqueria
    - generates unique `restaurantCode`
    - creates user
    - returns `accessToken`, `user`, `taqueria`
  - If taqueria already exists:
    - does NOT create duplicate taqueria
    - does NOT create user
    - returns:
      - `message: "Taquería ya existente"`
      - `taqueriaExists: true`
      - `taqueriaName`
      - `canJoin: true`

- Transitional endpoint (`POST /auth/join-taqueria`) was introduced in this phase
  and later replaced in FASE 5 by the unified smart register state-machine.

### Multi-tenant business guarantees

- No duplicate taquerias by name.
- Users in the same taqueria share the same `taqueriaId`.
- Shared catalog consistency is preserved (products/orders/realtime scope by taqueria).
- Cross-tenant isolation remains enforced through `taqueriaId` ownership checks.

### Technical notes

- Prisma migration applied:
  - `20260518045112_multi_taqueria_uniqueness`
- Register/join logic split cleanly in `AuthService` and `UsersService`.
- Unique restaurant code generation includes collision retry logic.

---

# Backend Migration Progress (FASE 5 - Smart Register State Machine)

## Implemented: Single-endpoint intelligent register flow for React Native UX

### Endpoint contract

- `POST /auth/register` is now a 2-phase state-machine:

1. Phase 1 (initial validation)
   - Input: `name`, `email`, `password`, `role`, `taqueriaName`
   - No writes to DB
   - Response if taqueria exists:
     - `taqueriaExists: true`
     - `requiresConfirmation: true`
     - `message: "Esta taquería ya existe. ¿Deseas unirte?"`
   - Response if taqueria does not exist:
     - `taqueriaExists: false`
     - `requiresTaqueriaInfo: true`
     - `message: "La taquería no existe. Completa los datos para crearla."`

2. Phase 2 (final confirmation)
   - Join existing taqueria:
     - same payload + `confirmJoinExistingTaqueria: true`
     - creates user in existing taqueria
     - returns auth response with JWT
   - Create new taqueria:
     - same payload + `createNewTaqueria: true` + `taqueriaData`
     - creates taqueria with unique `restaurantCode`
     - creates user and returns auth response with JWT

### Multi-tenant architecture guarantees

- Single source of truth by taqueria name uniqueness (`Taqueria.name @unique`).
- No duplicated taquerias by accidental register retries.
- Users joining same taqueria share same `taqueriaId`, products, orders, and operational scope.

### Database and model updates

- `Taqueria` now includes:
  - `restaurantCode` (unique)
  - `phone` (optional)
  - `address` (optional)
  - `city` (optional)
  - `state` (optional)
- Prisma migration applied:
  - `20260519021818_register_state_machine_flow`

### Security and validation rules

- Email uniqueness always enforced before any creation.
- Confirmation flags are mutually exclusive.
- No JWT is generated in Phase 1.
- JWT is only generated after user creation.
- Backend prevents confirmation bypass and inconsistent actions.

### Frontend behavior alignment

- React Native can keep single-screen registration UX.
- Backend responses explicitly drive UI decisions (confirm join vs request taqueria data).
- No separate `join-taqueria` endpoint is required in client flow.

---

# Backend Migration Progress (FASE 6 - SaaS Multi-Tenant by RestaurantCode)

## Implemented: Same-name taquerias supported with unique tenant identity

### Final multi-tenant architecture

- `Taqueria.name` is no longer unique.
- `Taqueria.restaurantCode` is the canonical unique tenant identifier.
- Multiple taquerias can share the same display name safely.
- Tenant sharing is defined by:
  - same `taqueriaId`
  - same `restaurantCode`

Users under same tenant share:
- products
- orders
- realtime scope
- operational catalog and kitchen context

### Register state-machine (single endpoint, frontend-aligned)

Endpoint: `POST /auth/register`

#### Phase 1 (discovery, no writes)

Input:
- `name`
- `email`
- `password`
- `role`
- `taqueriaName`

State A: `0` matches

```json
{
  "taqueriaMatches": 0,
  "canCreateNewTaqueria": true,
  "requiresTaqueriaInfo": true,
  "message": "No encontramos una taquería con este nombre. Puedes crear una nueva."
}
```

State B: `1` match

```json
{
  "taqueriaMatches": 1,
  "canJoinExistingTaqueria": true,
  "canCreateNewTaqueria": true,
  "taquerias": [
    {
      "id": "uuid",
      "name": "Taquería El Güero",
      "restaurantCode": "TM-4821"
    }
  ],
  "message": "Encontramos una taquería con este nombre."
}
```

State C: `N` matches

```json
{
  "taqueriaMatches": 3,
  "canJoinExistingTaqueria": true,
  "canCreateNewTaqueria": true,
  "taquerias": [
    { "id": "uuid-1", "name": "Taquería El Güero", "restaurantCode": "TM-4821" },
    { "id": "uuid-2", "name": "Taquería El Güero", "restaurantCode": "TM-9182" }
  ],
  "message": "Encontramos varias taquerías con este nombre."
}
```

#### Phase 2 (final action)

Case A: Join existing taqueria

Input:
- base fields +
- `confirmJoinExistingTaqueria: true`
- `selectedRestaurantCode: "TM-4821"`

Behavior:
- validates restaurant code
- reuses existing `taqueriaId`
- creates user
- generates JWT

Case B: Create new taqueria

Input:
- base fields +
- `createNewTaqueria: true`
- `taqueriaData` (phone/address/city/state optional details)

Behavior:
- creates new taqueria even if same name exists
- generates unique `restaurantCode`
- creates user
- generates JWT

### Frontend React Native integration contract

Single-screen flow remains:
1. User submits base form.
2. Backend returns match-state.
3. Frontend adapts UI:
   - show taqueria list (by `restaurantCode`) for join
   - or show extra taqueria form for creation
4. Frontend re-submits to same endpoint with final confirmation flags.
5. Backend returns auth response with JWT only after actual user creation.

### Validation and security rules

- Email uniqueness enforced.
- `restaurantCode` uniqueness enforced.
- `selectedRestaurantCode` required for join confirmation.
- Confirmation flags are mutually exclusive.
- Invalid join/create combinations are rejected.
- Ownership model remains taqueria-scoped in downstream modules (Products/Orders).

### Prisma updates

- `Taqueria.name` uniqueness removed.
- Migration applied:
  - `20260519022139_multi_taqueria_same_name_support`

---

# Backend Migration Progress (ETAPA 4.1 - Orders Core CRUD)

## Implemented: Orders module with immutable edit architecture

### New backend module

- `src/orders`
  - `orders.module.ts`
  - `orders.controller.ts`
  - `orders.service.ts`
  - `dto/create-order.dto.ts`
  - `dto/update-order.dto.ts`
  - `dto/update-order-status.dto.ts`
  - `interfaces/authenticated-user.interface.ts`

### SQL/domain models

- `Order`
  - `id`
  - `taqueriaId`
  - `waiterId`
  - `tableNumber` (visual reference string)
  - `status` (`PENDING`, `PREPARING`, `READY`, `DELIVERED`, `CANCELLED`)
  - `isUpdated`
  - `createdAt`
  - `updatedAt`
- `Plate`
  - `id`
  - `orderId`
  - `plateNumber`
  - `isClosed`
  - `createdAt`
- `Item`
  - `id`
  - `plateId`
  - `productId`
  - `quantity`
  - `selectedComplements`
  - `notes`
  - `isNew`
  - `createdAt`

### Relationships

- `Order` belongs to `Taqueria`
- `Order` belongs to `User` (`waiter`)
- `Order` has many `Plate`
- `Plate` belongs to `Order`
- `Plate` has many `Item`
- `Item` belongs to `Plate`
- `Item` belongs to `Product`

### Endpoints

- `POST /orders`
  - WAITER only
  - creates full order with nested plates/items
- `GET /orders`
  - WAITER: only own orders
  - COOK: all orders from same taqueria
- `GET /orders/:id`
  - ownership and role checks enforced
- `PATCH /orders/:id`
  - WAITER only
  - append-only edit (adds new plates/items, no historical mutation)
- `PATCH /orders/:id/status`
  - COOK only
  - updates order status

### Immutable edit rules (append-only)

- Existing plates/items are treated as immutable historical records.
- Edit flow never mutates old plates/items quantities/products.
- New items are appended inside newly created plates.
- Edited orders are marked `isUpdated = true`.
- Newly appended items are marked `isNew = true`.

### Role and ownership rules

- Multi-taqueria isolation via `taqueriaId` is mandatory in every query.
- WAITER cannot edit orders created by other waiters.
- WAITER cannot update order status.
- COOK can update status and view all orders in same taqueria.
- Cross-tenant access is blocked.

### Validations

- Product IDs must exist and belong to current taqueria.
- Quantities must be positive integers.
- `tableNumber` is required non-empty string (trim applied).
  - valid examples:
    - `Mesa 1`
    - `Mesa Juanita`
    - `Terraza`
    - `Barra 3`
    - `Pedido Uber`
    - `Mesa VIP`
- Status updates must use enum values only.
- Item `notes` is optional string.
  - valid values:
    - omitted
    - `""`
    - `"Sin salsa"`

### Historical consistency

- Orders are not physically deleted in this stage.
- Data model is prepared for future analytics/reports/realtime prioritization.

### Prisma updates

- Enum `OrderStatus` evolved to:
  - `PENDING`
  - `PREPARING`
  - `READY`
  - `DELIVERED`
  - `CANCELLED`
- Migration intent created for orders stage:
  - `orders_core_crud_append_only` (schema aligned in DB)

### Domain correction (Orders)

- `notes` is optional by design and can be empty.
- `tableNumber` represents mesa/pedido visual label, not numeric table index.

---

# Refactor Arquitectónico — JWT Centralizado (post-Etapa 4.3)

## Implemented: AuthModule como única fuente de verdad para JWT

### Problema resuelto

Existían dos registros independientes de `JwtModule`:

- `AuthModule` → `JwtModule.registerAsync(...)`
- `RealtimeModule` → `JwtModule.registerAsync(...)` (duplicado)

Aunque ambos usaban el mismo `JWT_SECRET`, cualquier cambio futuro en la configuración JWT (expiresIn, issuer, audience, algorithm) podría desincronizar REST y Socket.IO.

### Cambios realizados

- `AuthModule` ahora exporta `[AuthService, JwtModule]`.
- `RealtimeModule` elimina su propio `JwtModule.registerAsync(...)`.
- `RealtimeModule` importa `AuthModule` para reutilizar el `JwtService` ya configurado.

### Resultado

```txt
AuthModule
 ├── JwtModule (única configuración: JWT_SECRET + expiresIn: 1d)
 └── exports: [AuthService, JwtModule]

RealtimeModule
 ├── imports: [AuthModule, UsersModule]
 └── JwtService provisto por AuthModule — sin duplicación
```

### Comportamiento sin cambios

- REST sigue autenticando igual.
- Socket.IO sigue validando el mismo JWT con la misma configuración.
- Rooms multi-tenant sin cambios.
- Sin cambios en lógica de negocio, ownership, roles ni órdenes.

---

# Backend Migration Progress (ETAPA 4.3 - Socket.IO Foundation)

## Implemented: WebSocket Infrastructure with JWT Authentication and Multi-Tenant Rooms

### New backend module

- `src/realtime`
  - `realtime.module.ts`
  - `realtime.gateway.ts`
  - `realtime-auth.guard.ts`
  - `interfaces/authenticated-socket.interface.ts`

### New dependencies

- `@nestjs/websockets` — NestJS WebSocket decorators and interfaces
- `@nestjs/platform-socket.io` — Socket.IO adapter for NestJS
- `socket.io` — WebSocket server

### Architecture

- `RealtimeGateway` implements `OnGatewayConnection` and `OnGatewayDisconnect`.
- JWT validation happens at connection time inside `handleConnection`.
- Authenticated user context (`id`, `name`, `email`, `role`, `taqueriaId`, `restaurantCode`) is stored in `socket.data.user`.
- `RealtimeAuthGuard` protects individual `@SubscribeMessage` handlers by verifying `socket.data.user` exists.
- `IoAdapter` registered in `main.ts`.

### Token extraction (handshake)

Accepted sources in order:

1. `socket.handshake.auth.token` — recommended for React Native
2. `socket.handshake.headers.authorization` — Bearer token fallback

### Multi-tenant rooms

- Room format: `taqueria:<taqueriaId>`
- Users auto-join their taquería room on connection.
- `taqueriaId` is always derived from the JWT — never from the client.
- Cross-taquería event isolation guaranteed by room architecture.

### Events implemented

| Event          | Direction       | Description                            |
|----------------|-----------------|----------------------------------------|
| `connection`   | client → server | JWT validation + auto room join        |
| `disconnect`   | client → server | Connection cleanup                     |
| `join-taqueria`| client → server | Confirms active room for the client    |

### Completion criteria met

- ✅ Socket.IO connects correctly
- ✅ JWT validated at handshake — invalid tokens rejected
- ✅ Users auto-join their taquería room
- ✅ Cross-taquería isolation guaranteed by room architecture
- ✅ No business events yet (foundation only)
- ✅ Documentation updated

---

# Backend Migration Progress (ETAPA 4.4 - Kitchen Realtime)

## Implemented: Order Event Synchronization via WebSocket

### New files

- `src/realtime/interfaces/order-payload.interface.ts` — strongly-typed payload interface

### Modified files

- `src/realtime/realtime.gateway.ts` — added `emitOrderCreated`, `emitOrderUpdated`, `emitOrderStatusChanged`
- `src/realtime/realtime.module.ts` — exports `RealtimeGateway`
- `src/orders/orders.module.ts` — imports `RealtimeModule`
- `src/orders/orders.service.ts` — injects `RealtimeGateway`, emits after each DB operation

### Architecture

- `OrdersService` injects `RealtimeGateway` — no circular dependency since `RealtimeModule` does not import `OrdersModule`.
- Emission always happens **after** DB persistence is confirmed.
- All emit methods are wrapped in try-catch: WebSocket failures never roll back DB transactions.
- All events emitted exclusively to `taqueria:<taqueriaId>` — strict multi-tenant isolation.

### Events implemented

| Event                 | Trigger                        | Role required |
|-----------------------|--------------------------------|---------------|
| `order-created`       | POST /orders                   | WAITER        |
| `order-updated`       | PATCH /orders/:id              | WAITER        |
| `order-status-changed`| PATCH /orders/:id/status       | COOK          |

### Payload

Every event emits the **complete order** including all plates and items — no partial payloads.

Fields always present: `id`, `taqueriaId`, `waiterId`, `tableNumber`, `status`, `revision`, `priorityTimestamp`, `createdAt`, `updatedAt`, `plates[].items[].isNew`, `plates[].items[].createdInRevision`.

### isNew lifecycle via WebSocket

- `order-created` → all items have `isNew: false`
- `order-updated` → new items have `isNew: true` (green highlight for kitchen)
- `order-status-changed` to `READY` → all items have `isNew: false` (cleared in same DB transaction before emit)

### Recipient rules

All connected users in the taquería room receive all events.
The backend does **not** filter by role — the frontend decides how to handle each event.

### Completion criteria met

- ✅ `order-created` emitted after POST /orders
- ✅ `order-updated` emitted after PATCH /orders/:id
- ✅ `order-status-changed` emitted after PATCH /orders/:id/status
- ✅ Payloads contain complete order with plates, items, isNew, revision
- ✅ Events emitted only to the correct taquería room
- ✅ DB persisted before emission (source of truth rule enforced)
- ✅ WebSocket failures do not affect REST responses or DB state
- ✅ No circular module dependencies
- ✅ No `any` types — full TypeScript strict typing
- ✅ Documentation updated

---

# Backend Migration Progress (ETAPA 4.2 - Kitchen Queue Logic)

## Implemented: Backend as the Single Source of Truth for Kitchen Priority

### Architecture Changes
- `isUpdated` boolean flag was completely **removed** and replaced by `UPDATED` as a real `OrderStatus` enum value.
- The backend now assumes full responsibility for determining the display order of the kitchen queue, eliminating frontend priority logic.
- New fields introduced for precise priority and update tracking:
  - `Order.revision`: Counter incremented on every update (starts at 1).
  - `Order.priorityTimestamp`: Timestamp used strictly for kitchen ordering, refreshed on updates.
  - `Plate.createdInRevision`: Tracks exactly which revision added the plate.
  - `Item.createdInRevision`: Tracks exactly which revision added the item.

### Kitchen Queue Ordering (GET /orders for COOK)
The backend now returns orders pre-sorted by operational priority:
1. `UPDATED` (highest priority)
2. `PENDING`
3. `PREPARING`
4. `READY`
5. `DELIVERED`
6. `CANCELLED`

Within each status group, orders are sorted using a **FIFO (First In, First Out)** strategy by `priorityTimestamp ASC`. 
This guarantees that the order that has been waiting the longest in its current state appears first, representing accurately the real workflow of a kitchen.

**FIFO Examples:**
- *Caso 1 (PENDING vs PENDING)*: 
  - Pedido A (12:00) y Pedido B (12:05)
  - Resultado: Pedido A -> Pedido B
- *Caso 2 (UPDATED vs PENDING)*: 
  - Pedido A PENDING (12:00), Pedido B PENDING (12:05), Pedido C UPDATED (12:15)
  - Resultado: Pedido C (Prioridad UPDATED) -> Pedido A (Más antiguo PENDING) -> Pedido B
- *Caso 3 (UPDATED vs UPDATED)*: 
  - Pedido A UPDATED (12:00) y Pedido B UPDATED (12:10)
  - Resultado: Pedido A -> Pedido B (La actualización más antigua se atiende primero)

Waiters continue to see orders sorted simply by `createdAt DESC`.

### Append-Only Update Flow (PATCH /orders/:id)
When a waiter appends new plates/items to an order:
1. The backend increments the order's `revision`.
2. New plates and items are assigned `createdInRevision = newRevision`.
3. New items are flagged with `isNew = true` for frontend highlighting.
4. The order status is changed to `UPDATED`.
5. The `priorityTimestamp` is refreshed to `now()`, moving the order to the top of the kitchen queue.

### Green Highlight Rules (isNew lifecycle)
To maintain the visual "green highlight" for newly added items:
- New items are born with `isNew = true`.
- Transitioning the order from `UPDATED` to `PREPARING` does **not** clear the `isNew` flags. Items remain highlighted while the cook starts preparing them.
- Only when the order transitions to `READY` (from either `UPDATED` or `PREPARING`) does the backend use a Prisma transaction to clear `isNew = false` for all items in the order.

### Security and Validation
- Cooks are explicitly prevented from manually setting the `UPDATED` status via the API (enforced via `UpdateOrderStatusDto` and semantic service validation). The `UPDATED` status is exclusively managed by the backend during append operations.

### Prisma Updates
- Enum `OrderStatus` now includes `UPDATED`.
- Migration created: `20260519040000_kitchen_queue_logic_etapa_4_2`
