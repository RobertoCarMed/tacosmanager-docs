# Spec: Kitchen Queue

- ID: SPEC-kitchen-queue
- Estado: Implementada
- ETAPA asociada: 4.5.6.1, 4.5.6.2, 4.6.3

## 1. Problema

La cocina ve una lista de pedidos. Necesita un orden claro: lo que está en preparación arriba, luego lo nuevo por preparar, luego lo listo para entregar. Además debe saber qué items son recién agregados (verde) para no preparar de más.

## 2. Objetivos

- Ordenamiento global por status + FIFO.
- Transición de estados controlada por COOK.
- Limpieza automática de `isNew` al pasar a READY.
- Realtime sincronizado entre múltiples cocineros del mismo restaurante.

## 3. No-objetivos

- Reordenamiento manual.
- Asignación de pedidos a cocineros específicos.

## 4. Actores

- COOK (mutaciones).
- WAITER (lectura indirecta vía sus propias órdenes).

## 5. User Stories

- US-1: Como COOK quiero ver primero los pedidos que ya estoy preparando para no perderlos de vista.
- US-2: Como COOK quiero cambiar el status de un pedido para reflejar avance real.
- US-3: Como COOK quiero que los items recién agregados destaquen en verde para prepararlos sin confundirlos con los ya hechos.

## 6. Acceptance Criteria

### REQ-0040 — COOK cambia status a valores válidos
```gherkin
Dado un COOK autenticado y una orden en "PENDING"
Cuando hace PATCH /orders/:id/status con status="PREPARING"
Entonces la orden queda en "PREPARING"
```

### REQ-0041 — Asignar UPDATED manualmente falla
```gherkin
Cuando un COOK hace PATCH /orders/:id/status con status="UPDATED"
Entonces la respuesta es 400
Y la orden mantiene su status previo
```

### REQ-0042 — Transición a READY limpia isNew
```gherkin
Dado una orden con items isNew=true
Cuando se transiciona a READY
Entonces TODOS los items pasan a isNew=false en la misma transacción
```

### REQ-0043 — Ordenamiento Kitchen
```gherkin
Dado un mix de órdenes con status PREPARING, PENDING, READY, DELIVERED, CANCELLED
Cuando un COOK hace GET /orders
Entonces el orden devuelto es: PREPARING > PENDING > READY > DELIVERED > CANCELLED
```

### REQ-0044 — FIFO dentro del mismo status
```gherkin
Dado 3 órdenes en PENDING creadas en distinto createdAt
Cuando se hace GET /orders
Entonces las PENDING vienen ordenadas por createdAt ASC
```

### REQ-0045 — Cambio de status emite order-status-changed
```gherkin
Cuando un COOK cambia el status de una orden
Entonces todos los sockets del room "taqueria:<id>" reciben "order-status-changed"
Y el payload incluye la orden con el nuevo status (y isNew limpio si aplica)
```

### REQ-0046 — WAITER no puede cambiar status
```gherkin
Cuando un WAITER hace PATCH /orders/:id/status
Entonces la respuesta es 403
```

## 7. Edge Cases

- Transiciones ilegales (READY → PENDING manual, etc.) → 409 si se decide enforzar máquina de estados estricta (TBD ADR).
- Cambio a status idéntico al actual → 200 idempotente o 400 (TBD).

## 8. Requerimientos no funcionales

- Ordenamiento garantizado por backend (ADR-0006).
- Performance: GET /orders p95 < 200ms con 100 órdenes activas.

## 9. Dependencias

- ADRs: ADR-0004 (backend source of truth), ADR-0005 (append), ADR-0006 (ordering).

## 10. Referencias

- `business-rules.md` — Reglas de Cocina
- `api-reference.md` — Kitchen Queue Rules
