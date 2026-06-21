# Plan técnico: Ticket Printing (Impresión de Cuenta)

- Spec: `specs/ticket-printing/spec.md` (v1.0)
- Estado: Aprobado (pendiente de implementación)
- Autores: Equipo TacosManager
- Fecha: 2026-06-21

## 1. Resumen

Dos piezas: (1) **backend** congela `unitPrice` por item al crear/editar pedidos
(snapshot, ADR-0012) y lo expone en el contrato; (2) **mobile** agrega un botón "Imprimir
ticket" para el WAITER dueño de un pedido `READY`/`DELIVERED`, que renderiza la cuenta como
ESC/POS y la envía por **socket TCP:9100** a la POS-8370 en la LAN (ADR-0013).

## 2. Arquitectura

- **Backend (NestJS):**
  - `prisma/schema.prisma` — `Item.unitPrice Decimal?` (nullable por migración).
  - `OrdersService.createOrder` / `updateOrder` — setear `unitPrice = product.price` al crear
    items (el producto ya se consulta para validar ownership).
  - `orderSelect()` y `OrderRealtimePayload` — incluir `unitPrice`.
  - Migración Prisma con backfill best-effort (ver §6).
- **Mobile (React Native, Android):**
  - Servicio de impresión: abre socket TCP a `host:9100`, escribe bytes ESC/POS, cierra.
  - Renderer ESC/POS: arma el ticket (header taquería, líneas, total, corte) para 80mm.
  - Pantalla de detalle de orden: botón "Imprimir ticket" visible solo a WAITER dueño y solo
    en `READY`/`DELIVERED`.
  - Config de impresora: pantalla/ajuste para `host:puerto`, persistido localmente.
- **Realtime:** sin eventos nuevos; `unitPrice` viaja en los payloads existentes.

## 3. Modelo de datos

```prisma
model Item {
  // ...campos existentes...
  unitPrice Decimal? @db.Decimal(10, 2)  // snapshot; null solo en legacy con producto borrado
}
```

Sin `Order.total` (derivado en el frontend).

## 4. Contratos

- REST: `Item.unitPrice` agregado en `contracts/openapi.yaml` (→ **2.2.0**). No es input del
  cliente (no va en `CreateItem`); lo escribe el backend.
- Socket.IO: `Item.unitPrice` agregado en `contracts/asyncapi.yaml` (→ **1.2.0**).
- DTOs: `CreateItemDto` NO recibe `unitPrice` (el cliente no fija precios).

## 5. Decisiones técnicas

- **Precio por snapshot (A)** — ADR-0012. El frontend deriva el total; cumple Artículo II.
- **Transporte Wi-Fi/LAN TCP:9100** — ADR-0013. Impresora compartida por taquería.
- **Renderizado ESC/POS en el frontend** — ADR-0013. El backend no imprime.
- **Config por dispositivo** (MVP) — host:puerto en almacenamiento local.
- **Dinero como `Decimal`** — evita errores de redondeo en subtotales/total.

## 6. Migración / Compatibilidad

- Migración Prisma: agrega `Item.unitPrice` y hace **backfill best-effort**:
  `UPDATE "Item" SET unitPrice = (SELECT price FROM "Product" p WHERE p.id = "Item".productId)`.
  Items con producto borrado quedan en `null`.
- Aditivo en contratos (campo nuevo nullable) → sin breaking para consumidores actuales.
- Pedidos legacy sin precios completos: no imprimen cuenta (REQ-0078).

## 7. Testing

- Backend e2e (`orders.e2e-spec.ts`): snapshot al crear (REQ-0070), al append (REQ-0071),
  inmutabilidad ante cambio de catálogo (REQ-0072), backfill (REQ-0073).
- Mobile e2e (`mobile/e2e/ticket-printing.e2e.ts`): visibilidad/ownership del botón
  (REQ-0074/0075), contenido y total (REQ-0076/0077), bloqueo sin precios (REQ-0078),
  fallo de impresión seguro (REQ-0079), config requerida (REQ-0080).
- Unit: renderer ESC/POS (layout 80mm, corte) y cálculo de total.

## 8. Observabilidad

- Backend: sin cambios relevantes.
- Mobile: log de intentos de impresión y errores de conexión (sin datos sensibles).

## 9. Rollout

- Orden de despliegue: **backend primero** (snapshot + migración) → luego mobile (impresión)
  para que ya haya `unitPrice` en los pedidos nuevos.
- Feature flag: opcional en mobile (ocultar botón hasta validar en sitio).
- Rollback: revertir mobile no afecta datos; la columna `unitPrice` puede quedarse (inerte).

## 10. Trazabilidad

| REQ | Test | Archivos |
|---|---|---|
| REQ-0070 | orders.e2e-spec.ts::create_snapshots_unitprice | orders.service.ts, schema.prisma |
| REQ-0071 | orders.e2e-spec.ts::append_snapshots_unitprice | orders.service.ts |
| REQ-0072 | orders.e2e-spec.ts::unitprice_frozen | orders.service.ts |
| REQ-0073 | orders.e2e-spec.ts::backfill_unitprice | prisma/migrations/*_ticket_pricing_snapshot |
| REQ-0074 | mobile/e2e/ticket-printing.e2e.ts::print_completed | order detail screen, print service |
| REQ-0075 | mobile/e2e/ticket-printing.e2e.ts::owner_only | order detail screen |
| REQ-0076 | mobile/e2e/ticket-printing.e2e.ts::ticket_content | ESC/POS renderer |
| REQ-0077 | mobile/e2e/ticket-printing.e2e.ts::total_from_snapshots | ESC/POS renderer |
| REQ-0078 | mobile/e2e/ticket-printing.e2e.ts::block_without_prices | ESC/POS renderer |
| REQ-0079 | mobile/e2e/ticket-printing.e2e.ts::print_failure_safe | print service (TCP) |
| REQ-0080 | mobile/e2e/ticket-printing.e2e.ts::printer_config | print service, config storage |
