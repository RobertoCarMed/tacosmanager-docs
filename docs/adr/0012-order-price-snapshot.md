# ADR-0012: Snapshot de precio unitario (`unitPrice`) en órdenes

- Estado: Aceptado
- Fecha: 2026-06-21
- Autores: Equipo TacosManager

## Contexto

La feature de impresión de cuenta (`specs/ticket-printing/`) necesita el precio al que se
**cobró** cada línea del pedido. Hoy el modelo no lo guarda: `Item` solo tiene
`productId`/`quantity`; el precio vive únicamente en `Product.price` (catálogo mutable).

Calcular la cuenta leyendo el catálogo en vivo tiene dos problemas:

1. **Corrección histórica:** si el precio del producto cambia después, la cuenta de un
   pedido viejo mostraría un total que nunca se cobró; si el producto se borra, se rompe.
2. **Artículo II:** el frontend no debe calcular precios/totales que diverjan del backend.

Se evaluaron tres opciones (A: snapshot persistido; B: backend calcula al vuelo; C:
frontend desde catálogo). Se eligió **A**.

## Decisión

El backend **congela** el precio unitario en cada `Item` al momento de persistirlo:

1. Se agrega `Item.unitPrice` (snapshot de `Product.price` en el instante de creación).
2. En `POST /orders` (`createOrder`) y en el append de `PATCH /orders/:id` (`updateOrder`),
   cada item nuevo se guarda con `unitPrice = product.price` actual. El servicio ya consulta
   el producto para validar ownership/existencia, así que el precio ya está disponible.
3. `unitPrice` es **inmutable**: cambios posteriores en `Product.price` NO lo alteran.
4. El **total NO se persiste** en `Order`: se deriva sumando `unitPrice × quantity`. Para la
   cuenta lo calcula el frontend sobre los `unitPrice` congelados (aritmética de
   presentación sobre dato autoritativo → compatible con el Artículo II).
5. **Dinero como `Decimal`** (o enteros en centavos), nunca `float`.

Los complementos no tienen precio en el modelo actual; `unitPrice = product.price`.

### Migración de datos existentes

- Backfill **best-effort**: a los items existentes se les asigna `unitPrice = price actual`
  de su producto.
- `unitPrice` es **nullable**: items cuyo producto fue borrado quedan en `null`.
- La impresión exige `unitPrice` completo; un pedido legacy con líneas sin precio no emite
  cuenta (REQ-0078). Como las órdenes son efímeras (se cierran en el mismo turno), el
  backfill aproximado de pedidos ya terminados es inofensivo en la práctica.

### Trazabilidad y contrato

- Nuevos: REQ-0070, REQ-0071, REQ-0072 (snapshot e inmutabilidad), REQ-0073 (migración).
- Contrato: `item.unitPrice` agregado a `Item` en `openapi.yaml` (→ 2.2.0) y `asyncapi.yaml`
  (→ 1.2.0). Bump aditivo. No se agrega `order.total`.

## Alternativas consideradas

- **B — Backend calcula el total al vuelo (sin persistir).** Cumple Artículo II y no requiere
  migración, pero el ticket de un pedido viejo cambia si cambia el catálogo. Descartada: una
  cuenta debe reflejar lo cobrado.
- **C — Frontend calcula desde el catálogo en vivo.** Cero backend, pero viola el Artículo II
  y corrompe tickets ante cambios de precio o productos borrados. Descartada.

## Consecuencias

Positivas:
- La cuenta refleja el precio cobrado y es estable en el tiempo.
- Cumple el Artículo II: el precio es autoritativo del backend; el frontend solo suma.
- Cambio de backend pequeño y acotado (el precio ya se consulta en `createOrder`).

Negativas:
- `unitPrice` nullable obliga a manejar el caso legacy/producto-borrado en la impresión.
- El backfill de pedidos pre-feature es aproximado (no recupera el precio real cobrado).

Neutrales:
- No se persiste `order.total`; si reportes futuros lo necesitan persistido, será otro ADR.

## Referencias

- Constitución Artículo II — Backend como Fuente de Verdad
- `specs/ticket-printing/spec.md` — REQ-0070 a REQ-0073
- ADR-0013 — Integración de impresión de tickets
- `contracts/openapi.yaml`, `contracts/asyncapi.yaml` — `Item.unitPrice`
