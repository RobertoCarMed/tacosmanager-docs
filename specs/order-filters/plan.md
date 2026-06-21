# Plan técnico: Order Filters (Visibilidad de Órdenes)

- Spec: `specs/order-filters/spec.md` (v1.0)
- Estado: Implementado
- Autores: Equipo TacosManager
- Fecha: 2026-06-21

## 1. Resumen

Filtrado **client-side** de la lista de órdenes ya cargada (REST + realtime). Un
selector de filtro en las pantallas de mesero y cocina decide qué subconjunto se
muestra: `active` (default, status no terminal, sin fecha) o un rango histórico
(`today`/`7d`/`1m`/`3m`, por `createdAt` en hora local). El backend no cambia.

## 2. Arquitectura

- **Backend:** sin cambios. `GET /orders` sigue devolviendo la lista ordenada por rol
  (COOK: prioridad de cocina + `priorityTimestamp ASC`; WAITER: `createdAt DESC`) y
  aislada por taquería/ownership.
- **Frontend (mobile):**
  - `WaiterOrdersScreen` — selector de filtro, default `active`.
  - `KitchenScreen` / `KitchenDashboardScreen` — selector de filtro, default `active`.
  - Predicado de filtro puro y reutilizable (mismo criterio en ambas pantallas),
    aplicado sobre la lista del store de Redux antes de renderizar.
- **Realtime:** los eventos `order-created` / `order-updated` / `order-status-changed`
  actualizan el store; el predicado de filtro se reaplica sobre el nuevo estado.

> Nota: el path exacto del predicado/util de filtro debe confirmarse contra el repo
> mobile al implementar tests (las pantallas sí están nombradas en `ui-flows.md`).

## 3. Modelo de datos

Sin cambios de esquema. El filtro opera sobre campos ya existentes de `Order`:
`status` (para `active`) y `createdAt` (para los rangos históricos).

## 4. Contratos

- REST: `GET /orders` — **sin** query params de filtro (filtrado en cliente). Ver
  `contracts/openapi.yaml#/paths/~1orders`.
- Socket.IO: sin cambios; el filtro se reaplica al recibir eventos.
- DTOs: no aplica (no hay input de filtro hacia el backend).

## 5. Decisiones técnicas

- **Filtrado en cliente (no server-side).** Razón: la lista ya está en el store; cambiar
  de filtro debe ser inmediato y sin red. Compatible con el Artículo II porque es
  presentación (oculta filas) y no recalcula orden ni estado. ¿Requiere ADR? No (no es
  decisión cross-cutting nueva; se apoya en ADR-0004). Mover a server-side en el futuro
  SÍ requeriría ADR + bump de contrato.
- **Hora local del dispositivo** para los rangos de fecha. Razón: coherente con el edge
  case de medianoche (REQ-0065) y con la expectativa del personal en sitio.
- **Ventanas móviles** (`ahora − N`) para `7d`/`1m`/`3m`; `today` desde medianoche local.
- **Históricos muestran todos los statuses**; solo `active` excluye `DELIVERED`/`CANCELLED`.

## 6. Migración / Compatibilidad

- Sin migración de datos ni breaking change de contrato.
- Compatible con pedidos históricos (cualquier `status`/`createdAt`).

## 7. Testing

- Tests unitarios: predicado de filtro (active vs históricos, límites de rango, statuses).
- Tests e2e/mobile (Detox/Playwright): `mobile/e2e/order-filters.e2e.ts`.
- Tests Gherkin: `specs/order-filters/acceptance.feature`.
- Cobertura mínima esperada: los 7 REQ (REQ-0063 a REQ-0069).

## 8. Observabilidad

- No requiere logs/métricas backend nuevos (es client-side).
- Opcional: telemetría de uso de filtro en el cliente (futuro, fuera de alcance).

## 9. Rollout

- Feature flag: no.
- Deploy: incluido en el build del cliente; sin pasos de backend.
- Rollback: revertir el cliente; el backend no se ve afectado.

## 10. Trazabilidad

| REQ | Test | Archivos |
|---|---|---|
| REQ-0063 | mobile/e2e/order-filters.e2e.ts::default_active | WaiterOrdersScreen, KitchenScreen |
| REQ-0064 | mobile/e2e/order-filters.e2e.ts::active_excludes_terminal | predicado de filtro |
| REQ-0065 | mobile/e2e/order-filters.e2e.ts::active_midnight_edge | predicado de filtro |
| REQ-0066 | mobile/e2e/order-filters.e2e.ts::today_local_midnight | predicado de filtro |
| REQ-0067 | mobile/e2e/order-filters.e2e.ts::rolling_windows | predicado de filtro |
| REQ-0068 | mobile/e2e/order-filters.e2e.ts::historical_all_statuses | predicado de filtro |
| REQ-0069 | mobile/e2e/order-filters.e2e.ts::clientside_preserves_order | screens + store selector |
