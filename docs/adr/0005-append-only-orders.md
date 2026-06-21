# ADR-0005: Modelo append-only para órdenes

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

> ℹ️ **Aclaración por [ADR-0011](0011-order-classification-edit.md) (2026-06-21).**
> "Modificación" en este ADR se refiere al **trabajo de cocina** (plates/items históricos),
> que sigue siendo inmutable. La **clasificación** de la orden (`type`/`reference`/
> `deliveryAddress`) SÍ puede corregirse vía `PATCH /orders/:id` (REQ-0062). El punto 2 de la
> Decisión ("PATCH SOLO permite agregar plates/items nuevos") debe leerse con ese matiz.

## Contexto

Una orden en una taquería va cambiando: el mesero agrega más tacos, la cocina avanza el estado. Hubo que decidir si las ediciones modifican lo existente o si solo se agrega.

Riesgos de permitir edición libre:
- La cocina podría estar preparando algo que el mesero "borró".
- Auditoría imposible.
- Bug subtle: cambiar la cantidad de un item ya cocinado.

## Decisión

Adoptamos **append-only**:

1. Una orden tiene `revision` monotónica. Inicia en `1`.
2. `PATCH /orders/:id` SOLO permite agregar plates nuevos o items nuevos a plates abiertos.
3. PROHIBIDO: modificar quantity de items existentes, borrar items, cambiar productos.
4. Cada item/plate guarda `createdInRevision` para reconstrucción histórica.
5. Items nuevos llegan con `isNew: true` para highlight verde en cocina (limpiado al pasar a `READY`).
6. El status resultante del append depende del status previo (ver business-rules §16):
   - PENDING → PENDING (sigue acumulando)
   - PREPARING → PREPARING (cocina ya está en eso)
   - READY → PENDING (vuelve a la cola)

## Alternativas consideradas

- **Edición libre con event sourcing** — auditoría perfecta pero complejidad alta para el equipo y la UI.
- **Edición libre + tombstones** — soft delete, frágil bajo concurrencia.
- **Cierre de orden** — no aplica al flujo de taquería donde se agregan tacos sobre la marcha.

## Consecuencias

Positivas:
- Cocina nunca prepara algo "borrado".
- Auditoría trivial: el orden de plates por `createdInRevision` reconstruye la historia.
- Concurrencia simple: solo INSERT, no UPDATE de filas críticas.

Negativas:
- UX: si el cliente se arrepiente de un taco, hay que cancelar el item (flujo futuro) o cancelar la orden completa.
- Modelado de "remover taco" requiere ADR futuro (probablemente un item de tipo `REMOVAL` que la cocina interpreta).

Neutrales:
- El status `UPDATED` quedó deprecado (ETAPA 4.5.6.1) y solo persiste en DB por compatibilidad histórica.

## Referencias

- Constitución Artículo V — Append-Only en Órdenes
- `business-rules.md` §16
- `backend-api.md` — Orders
- REQ-0030, REQ-0031, REQ-0032, REQ-0033, REQ-0034, REQ-0035
