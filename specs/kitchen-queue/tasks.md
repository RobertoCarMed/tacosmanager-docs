# Tasks: Kitchen Queue

> Retroactivas. ETAPA 4.5.6.1, 4.5.6.2, 4.6.3.

## TASK-0040 — Endpoint PATCH /orders/:id/status con guard COOK
- Cubre: REQ-0040, REQ-0046
- Estado: ✅

## TASK-0041 — Rechazar UPDATED en validación
- Cubre: REQ-0041
- Estado: ✅

## TASK-0042 — Limpieza de isNew al transicionar a READY
- Cubre: REQ-0042
- Estado: ✅

## TASK-0043 — Ordenamiento por status + priorityTimestamp ASC (ADR-0010)
- Cubre: REQ-0043, REQ-0047 (sucede a REQ-0044 deprecado: era por createdAt)
- Estado: 🟡 (implementado; falta test dedicado de reprioritización en PREPARING)

## TASK-0044 — Emit order-status-changed
- Cubre: REQ-0045
- Estado: ✅
