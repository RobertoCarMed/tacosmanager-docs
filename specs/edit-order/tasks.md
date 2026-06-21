# Tasks: Edit Order

> Retroactivas. ETAPA 4.5.3, 4.5.6.2, 4.6.2.

## TASK-0030 — `OrdersService.updateOrder` (append de plates) con transacción
- Cubre: REQ-0048, REQ-0032 (sucede a REQ-0030 deprecado)
- Estado: ✅

## TASK-0031 — `computeStatusAfterAppend()` (CASO 1/2/3)
- Cubre: REQ-0034, REQ-0035
- Estado: ✅

## TASK-0032 — `isNew=true` para items insertados
- Cubre: REQ-0033
- Estado: ✅

## TASK-0033 — Rechazar mutaciones a items históricos
- Cubre: REQ-0031
- Estado: ✅

## TASK-0034 — Emit `order-updated`
- Cubre: REQ-0036
- Estado: ✅

## TASK-0036 — Corrección de clasificación (`validateClassification` sobre estado efectivo)
- Cubre: REQ-0062
- Estado: 🟡 (implementado; falta test automatizado dedicado)

## TASK-0035 — Tests e2e
- Cubre: todos
- Estado: ✅
