# Spec: Edit Order (Append)

- ID: SPEC-edit-order
- Versión: 1.0
- Estado: Implementada
- ETAPA asociada: 4.5.3, 4.5.6.2, 4.6.2

## 1. Problema

Un mesero necesita agregar tacos/items a una orden ya enviada a cocina sin perder el histórico ni confundir a la cocina sobre qué se está preparando.

## 2. Objetivos

- Permitir agregar plates/items a una orden existente respetando append-only (ADR-0005).
- Incrementar `revision` en cada append.
- Marcar items nuevos con `isNew=true` para highlight verde en cocina.
- Recalcular status según estado previo (CASO 1/2/3 de business-rules §16).
- Emitir `order-updated` en realtime.

## 3. No-objetivos

- Modificar items históricos (PROHIBIDO).
- Cancelar items individuales (futuro spec).
- Cambiar `type`, `reference`, `deliveryAddress` post-creación.

## 4. Actores

- WAITER (única autoridad de append).

## 5. User Stories

- US-1: Como WAITER quiero agregar 2 tacos más a la mesa 4 que ya está en cocina sin perder lo anterior.
- US-2: Como COOK quiero ver claramente cuáles items son nuevos (highlight verde) para no confundirlos con los ya preparados.

## 6. Acceptance Criteria

### REQ-0030 — PATCH /orders/:id agrega plates/items nuevos

```gherkin
Dado una orden existente con 1 plate y 1 item en revision=1
Cuando el WAITER hace PATCH /orders/:id agregando 1 item nuevo al plate existente
Entonces la respuesta es 200 con la orden completa
Y la orden tiene 2 items en el plate
Y el item nuevo tiene createdInRevision=2 e isNew=true
```

### REQ-0031 — PATCH no permite modificar items históricos

```gherkin
Dado una orden con un item I (quantity=1)
Cuando el WAITER intenta PATCH /orders/:id intentando cambiar quantity de I
Entonces el cambio es ignorado o rechazado con 400
Y la quantity de I sigue siendo 1
```

### REQ-0032 — revision se incrementa en cada append

```gherkin
Dado una orden en revision=N
Cuando el WAITER hace PATCH agregando algo
Entonces la respuesta tiene revision=N+1
```

### REQ-0033 — Items nuevos llegan con isNew=true

```gherkin
Cuando un append exitoso ocurre
Entonces los items agregados tienen isNew=true
Y los items previos mantienen isNew con su valor anterior
```

### REQ-0034 — Append en READY transiciona status a PENDING

```gherkin
Dado una orden con status="READY"
Cuando el WAITER hace PATCH agregando un item
Entonces la orden queda con status="PENDING"
Y vuelve a entrar en la cola activa de cocina
```

### REQ-0035 — Append en PREPARING mantiene PREPARING

```gherkin
Dado una orden con status="PREPARING"
Cuando el WAITER hace PATCH agregando un item
Entonces la orden mantiene status="PREPARING"
```

### REQ-0036 — Append emite order-updated

```gherkin
Cuando ocurre un PATCH exitoso
Entonces todos los sockets conectados al room "taqueria:<id>" reciben "order-updated"
Y el payload incluye la orden completa con items nuevos marcados isNew=true
```

## 7. Edge Cases

- PATCH sin cambios → 400.
- PATCH a orden CANCELLED o DELIVERED → 409 (transición ilegal).
- PATCH con productId de otra taquería → 400/404.

## 8. Requerimientos no funcionales

- Append-only: Constitución Artículo V.
- Idempotencia: no garantizada.

## 9. Dependencias

- Spec: create-order.
- ADRs: ADR-0005 (append-only), ADR-0006 (kitchen ordering).

## 10. Referencias

- `business-rules.md` §16 — CASOS 1/2/3
- `backend-api.md` — PATCH /orders/:id
