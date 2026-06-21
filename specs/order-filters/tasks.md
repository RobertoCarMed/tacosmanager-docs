# Tasks: Order Filters

- Spec: `specs/order-filters/spec.md`
- Plan: `specs/order-filters/plan.md`

> Retroactivas. ETAPA 4.8. El filtrado client-side ya está implementado; los tests
> automatizados dedicados están pendientes (estado 🟡).

## TASK-0063 — Predicado de filtro `active` (status no terminal, sin fecha)
- Cubre: REQ-0064, REQ-0065
- Archivos: predicado de filtro (mobile), WaiterOrdersScreen, KitchenScreen
- Estado: 🟡 (implementado; falta test automatizado)

## TASK-0064 — Default `active` en pantallas de mesero y cocina
- Cubre: REQ-0063
- Archivos: WaiterOrdersScreen, KitchenScreen, KitchenDashboardScreen
- Estado: 🟡 (implementado; falta test automatizado)

## TASK-0065 — Rangos históricos por `createdAt` en hora local
- Cubre: REQ-0066, REQ-0067
- Archivos: predicado de filtro (mobile)
- Estado: 🟡 (implementado; falta test automatizado)

## TASK-0066 — Históricos incluyen todos los statuses
- Cubre: REQ-0068
- Archivos: predicado de filtro (mobile)
- Estado: 🟡 (implementado; falta test automatizado)

## TASK-0067 — Filtrado client-side preserva orden base y aislamiento
- Cubre: REQ-0069
- Archivos: selector de store (Redux), WaiterOrdersScreen, KitchenScreen
- Estado: 🟡 (implementado; falta test automatizado)

## TASK-0068 — Tests e2e/mobile de filtros
- Cubre: REQ-0063 a REQ-0069
- Archivos: mobile/e2e/order-filters.e2e.ts
- Estado: ⬜ pendiente

Criterio de "done":
- Tests pasando (los 7 REQ cubiertos)
- Trazabilidad actualizada
