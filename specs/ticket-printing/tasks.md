# Tasks: Ticket Printing

- Spec: `specs/ticket-printing/spec.md`
- Plan: `specs/ticket-printing/plan.md`

> Feature nueva (`feat:ticket-printing`, fuera de la numeración de ETAPAs — ADR-0014).
> Orden de implementación: backend (precio) primero, luego mobile (impresión).
> Estados: ⬜ pendiente · 🟡 en progreso · ✅ hecho · 🔴 bloqueado

## Backend — Snapshot de precio (ADR-0012)

### TASK-0070 — Columna `Item.unitPrice` + migración con backfill
- Cubre: REQ-0073
- Archivos: prisma/schema.prisma, prisma/migrations/*_ticket_pricing_snapshot
- Pasos: agregar `unitPrice Decimal?`; migración con backfill best-effort desde Product.price.
- Estado: ✅

### TASK-0071 — Congelar unitPrice al crear y al hacer append
- Cubre: REQ-0070, REQ-0071, REQ-0072
- Archivos: src/orders/orders.service.ts (createOrder, updateOrder)
- Pasos: setear `unitPrice = product.price` al construir items; no reescribir en items previos.
- Estado: ✅

### TASK-0072 — Exponer unitPrice en lectura y realtime
- Cubre: REQ-0070, REQ-0071
- Archivos: orders.service.ts (orderSelect), realtime/interfaces/order-payload.interface.ts
- Estado: ✅

### TASK-0073 — Tests backend de snapshot/inmutabilidad/backfill
- Cubre: REQ-0070, REQ-0071, REQ-0072, REQ-0073
- Archivos: backend/test/orders.e2e-spec.ts
- Estado: ✅

## Mobile — Impresión (ADR-0013)

### TASK-0074 — Servicio de impresión TCP (socket host:9100)
- Cubre: REQ-0079
- Archivos: mobile print service
- Pasos: abrir socket, escribir bytes, cerrar; manejar timeout/error con reintento.
- Estado: ⬜

### TASK-0075 — Renderer ESC/POS de la cuenta (80mm)
- Cubre: REQ-0076, REQ-0077
- Archivos: mobile ESC/POS renderer
- Pasos: header taquería + tipo/referencia + fecha; líneas (cant × producto × unitPrice =
  subtotal); total = Σ subtotales; corte `GS V`.
- Estado: ⬜

### TASK-0076 — Botón "Imprimir ticket" (visibilidad + ownership + status)
- Cubre: REQ-0074, REQ-0075
- Archivos: mobile order detail screen
- Pasos: visible solo a WAITER dueño y en READY/DELIVERED.
- Estado: ⬜

### TASK-0077 — Guard de precios incompletos
- Cubre: REQ-0078
- Archivos: ESC/POS renderer / order detail screen
- Pasos: si algún item.unitPrice es null → bloquear e informar.
- Estado: ⬜

### TASK-0078 — Configuración de impresora (host:puerto) persistida
- Cubre: REQ-0080
- Archivos: mobile print service, config storage (AsyncStorage)
- Estado: ⬜

### TASK-0079 — Tests mobile e2e de impresión
- Cubre: REQ-0074 a REQ-0080
- Archivos: mobile/e2e/ticket-printing.e2e.ts
- Estado: ⬜

Criterio de "done" global:
- REQ-0070 a REQ-0080 en ✅ con tests pasando
- Contratos openapi/asyncapi reflejan unitPrice (ya hecho en la spec)
- traceability.md actualizada (🔴 → ✅ conforme se implementa)
