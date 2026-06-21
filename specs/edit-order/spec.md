# Spec: Edit Order (Append)

- ID: SPEC-edit-order
- Versión: 3.0
- Estado: Implementada
- ETAPA asociada: 4.5.3, 4.5.6.2, 4.6.2

> **Changelog 3.0 (2026-06-21):** se **legitima** la edición de clasificación de la orden
> (`type`/`reference`/`deliveryAddress`) post-creación (ADR-0011, que enmienda el alcance del
> Artículo V). Era la feature 4.6.2 ya construida; el corpus estaba dividido. `REQ-0049`
> (que la prohibía, nunca implementado) queda `🗑️ Deprecado`; su sucesor es `REQ-0062`
> (clasificación editable). El Artículo V sigue protegiendo plates/items históricos.
> Reversión de comportamiento → bump MAJOR (ADR-0009).

> **Changelog 2.1 (2026-06-20):** se formalizó como criterio testeable (REQ-0049) la
> inmutabilidad de `type`/`reference`/`deliveryAddress` en append. Revertido en 3.0 (ver arriba).

> **Changelog 2.0 (2026-06-20):** verificación doc↔backend reveló que el append agrega
> **plates nuevos** (identificados por `plateNumber`; un `plateNumber` existente → 400,
> inmutabilidad a nivel plate), NO items a un plate existente. REQ-0030 describía el
> comportamiento equivocado y queda deprecado; su sucesor es REQ-0048. Breaking → bump
> MAJOR (ADR-0009).

## 1. Problema

Un mesero necesita agregar tacos/items a una orden ya enviada a cocina sin perder el histórico ni confundir a la cocina sobre qué se está preparando.

## 2. Objetivos

- Permitir agregar plates/items a una orden existente respetando append-only (ADR-0005).
- Permitir corregir la clasificación (`type`/`reference`/`deliveryAddress`) post-creación, con o sin agregar plates (ADR-0011).
- Incrementar `revision` en cada append.
- Marcar items nuevos con `isNew=true` para highlight verde en cocina.
- Recalcular status según estado previo (CASO 1/2/3 de business-rules §16).
- Emitir `order-updated` en realtime.

## 3. No-objetivos

- Modificar plates/items históricos: productos, cantidades, complementos, notas (PROHIBIDO, Artículo V).
- Cancelar items individuales (futuro spec).
- Conservar histórico del valor anterior de la clasificación al corregirla (futuro ADR).

## 4. Actores

- WAITER (única autoridad de append).

## 5. User Stories

- US-1: Como WAITER quiero agregar 2 tacos más a la mesa 4 que ya está en cocina sin perder lo anterior.
- US-2: Como COOK quiero ver claramente cuáles items son nuevos (highlight verde) para no confundirlos con los ya preparados.

## 6. Acceptance Criteria

### REQ-0030 — PATCH /orders/:id agrega plates/items nuevos `[🗑️ DEPRECADO — sucesor REQ-0048]`

> Deprecado en spec 2.0. Describía agregar un item a un plate existente, pero el backend
> agrega plates nuevos (inmutabilidad a nivel plate). Se conserva como histórico inmutable
> (ADR-0009). Ver REQ-0048.

```gherkin
Dado una orden existente con 1 plate y 1 item en revision=1
Cuando el WAITER hace PATCH /orders/:id agregando 1 item nuevo al plate existente
Entonces la respuesta es 200 con la orden completa
Y la orden tiene 2 items en el plate
Y el item nuevo tiene createdInRevision=2 e isNew=true
```

### REQ-0048 — PATCH /orders/:id agrega un plate nuevo (append-only por plate)

```gherkin
Dado una orden existente con 1 plate (plateNumber=1) en revision=1
Cuando el WAITER hace PATCH /orders/:id con un plate nuevo (plateNumber=2) con 1 item
Entonces la respuesta es 200 con la orden completa
Y la orden tiene 2 plates
Y el plate nuevo tiene createdInRevision=2 y su item isNew=true
Y si el WAITER envía un plateNumber ya existente (plateNumber=1) la respuesta es 400
```

### REQ-0049 — PATCH no muta type/reference/deliveryAddress `[🗑️ DEPRECADO — sucesor REQ-0062]`

> Deprecado en spec 3.0 (ADR-0011). Documentaba la prohibición de editar la clasificación;
> nunca se implementó (`🔴`). El proyecto decidió **legitimar** la edición de clasificación
> (ADR-0011 enmienda el alcance del Artículo V). Se conserva como histórico. Ver REQ-0062.

```gherkin
Dado una orden DINE_IN existente con reference="Mesa 4"
Cuando el WAITER hace PATCH /orders/:id incluyendo type, reference o deliveryAddress
Entonces la respuesta es 400 (campos no permitidos en un append)
Y la orden conserva su type, reference y deliveryAddress originales sin mutar
```

### REQ-0062 — PATCH puede corregir la clasificación (type/reference/deliveryAddress)

```gherkin
Dado una orden DINE_IN existente con reference="Mesa 4"
Cuando el WAITER hace PATCH /orders/:id con type="DELIVERY" y deliveryAddress="Av. Juárez #123"
Entonces la respuesta es 200 con la orden completa
Y la orden queda con type="DELIVERY", deliveryAddress="Av. Juárez #123"
Y revision se incrementa
Y los plates/items históricos no cambian (no se crean items ni se marca isNew)
Y si la clasificación resultante es inválida (ej. DELIVERY sin deliveryAddress) la respuesta es 400
```

> **Estado:** 🟡 Implementado, falta test automatizado dedicado. El backend escribe
> `type`/`reference`/`deliveryAddress` en `updateOrder` validando el estado efectivo con
> `validateClassification`. El contrato `AppendOrder` (openapi 2.1.0) acepta estos campos
> como opcionales.

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
- ADRs: ADR-0005 (append-only), ADR-0010 (kitchen ordering), ADR-0011 (edición de clasificación).

## 10. Referencias

- `business-rules.md` §16 — CASOS 1/2/3
- `backend-api.md` — PATCH /orders/:id
