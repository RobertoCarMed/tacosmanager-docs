# ADR-0011: Edición de clasificación de orden post-creación (carve-out del Artículo V)

- Estado: Aceptado
- Fecha: 2026-06-21
- Autores: Equipo TacosManager

## Contexto

El Artículo V (Append-Only en Órdenes) se interpretó inicialmente de forma
absoluta: "una orden existente NUNCA puede modificarse retroactivamente; solo se
permite agregar plates/items nuevos". Bajo esa lectura, `REQ-0049` (spec
`edit-order` 2.1) formalizó que `PATCH /orders/:id` NO podía mutar
`type`/`reference`/`deliveryAddress` y debía responder `400`, marcando el
comportamiento del backend (que sí los escribe) como una violación pendiente de fix.

Sin embargo, el resto del corpus evolucionó en la dirección contraria, y por una
razón operativa válida:

- ETAPA 4.6.2 implementó deliberadamente la edición de tipo de pedido
  (`DINE_IN ↔ TAKEAWAY ↔ DELIVERY`) en `EditOrderScreen`, documentada en
  `roadmap.md`, `feature-list.md`, `ui-flows.md`, `architecture.md`,
  `frontend-architecture.md` y `backend-api.md`.
- `business-rules.md` §28/§29 describen la corrección de tipo y dirección como
  parte del flujo operativo del mesero.

El caso de negocio: un mesero captura el pedido bajo presión y se equivoca de
modalidad (marca DINE_IN cuando era DELIVERY, o teclea mal la mesa/dirección).
Estos son **datos de clasificación** del pedido, no el trabajo de cocina ya
encolado. Bloquear su corrección obliga a cancelar y recrear toda la orden,
perdiendo el histórico — exactamente lo que el Artículo V busca evitar.

Nota clave: editar la clasificación NO toca los plates/items históricos. La cocina
sigue preparando exactamente lo mismo; solo cambia la etiqueta de modalidad/entrega.

## Decisión

El Artículo V protege la **inmutabilidad del trabajo de cocina**: los plates e
items históricos (cantidades, productos, complementos, notas) son inmutables y
solo pueden crecer por append. Esa garantía NO cambia.

La **clasificación de la orden** (`type`, `reference`, `deliveryAddress`) es
metadata corregible y queda explícitamente FUERA del alcance restrictivo del
Artículo V. `PATCH /orders/:id` PUEDE:

1. Agregar plates nuevos (append-only, `REQ-0048`), y/o
2. Corregir la clasificación (`type`/`reference`/`deliveryAddress`), con o sin
   agregar plates.

Reglas de la edición de clasificación:

- La validación se aplica sobre el **estado efectivo** resultante: si se cambia
  `type`, se exige `reference` (DINE_IN/TAKEAWAY) o `deliveryAddress` (DELIVERY)
  coherente con el nuevo tipo; combinaciones inválidas → `400`.
- Editar clasificación **no** crea plates/items, **no** marca `isNew`, y **no**
  altera el trabajo histórico.
- `revision` se incrementa igual que en cualquier `PATCH` (append).
- La transición de status sigue las reglas de modificación (CASO 1/2/3,
  `business-rules.md` §16): un append puro de clasificación se trata igual que un
  append de plates respecto al status y `priorityTimestamp`.

Trazabilidad: `REQ-0049` (prohibía mutar la clasificación) queda `🗑️ Deprecado`
con sucesor **`REQ-0062`** (clasificación editable). La spec `edit-order` sube a
`3.0` (MAJOR, reversión de comportamiento, ADR-0009). El contrato
`openapi.yaml` sube a `2.1.0` (aditivo: `AppendOrder` acepta campos de
clasificación opcionales).

Esta decisión enmienda la interpretación del Artículo V (constitución `1.1`) sin
debilitar su núcleo: el trabajo de cocina sigue siendo append-only e inmutable.

## Alternativas consideradas

- **Mantener Artículo V absoluto (REQ-0049)** — append-only total, sin edición de
  clasificación. Coherente con la lectura literal original, pero contradice la
  feature 4.6.2 ya construida y validada multi-device, y degrada la UX (cancelar y
  recrear para corregir una mesa mal tecleada). Descartada.
- **Edición libre de toda la orden** — permitiría también mutar plates/items
  históricos. Rechazada: reintroduce los riesgos que motivaron ADR-0005 (cocina
  preparando algo "borrado", auditoría imposible).
- **Corrección vía cancelar + recrear** — sin cambios de contrato, pero pierde el
  histórico de la orden y rompe la continuidad de `revision`. Descartada.

## Consecuencias

Positivas:
- Una sola realidad coherente entre constitución, spec, contrato, business-rules y
  docs descriptivos sobre qué permite `PATCH /orders/:id`.
- El mesero corrige errores de captura sin perder el pedido ni su histórico.
- El núcleo append-only (plates/items históricos inmutables) queda intacto y más
  claramente delimitado.

Negativas:
- `traceability.md` retiene `REQ-0049` como histórico deprecado.
- Auditoría de clasificación: un cambio de `type`/`reference`/`deliveryAddress` no
  guarda histórico de su valor anterior (solo el actual). Si en el futuro se
  requiere trazar correcciones de clasificación, necesitará un ADR nuevo.

Verificación (2026-06-21):
- El backend YA implementa la edición de clasificación (`orders.service.ts`
  `updateOrder` escribe `type`/`reference`/`deliveryAddress` con
  `validateClassification` sobre el estado efectivo). `REQ-0062` queda `🟡`
  (implementado; falta test automatizado dedicado). No hay trabajo de backend
  pendiente; el fix que pedía `REQ-0049` queda cancelado.

Neutrales:
- ADR-0005 conserva su decisión; se le agrega una nota de aclaración apuntando a
  este ADR para el alcance de "modificación".

## Referencias

- Constitución Artículo V — Append-Only en Órdenes (enmendado, versión 1.1)
- ADR-0005 — Modelo append-only para órdenes (aclarado por este ADR)
- ADR-0009 — Política de versionado de specs y REQ-IDs
- `specs/edit-order/spec.md` — REQ-0062 (sucesor de REQ-0049)
- `business-rules.md` §28, §29 — Edición de tipo y dirección
- `contracts/openapi.yaml` — `AppendOrder` (2.1.0)
