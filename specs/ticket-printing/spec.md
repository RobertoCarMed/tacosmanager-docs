# Spec: Ticket Printing (Impresión de Cuenta)

- ID: SPEC-ticket-printing
- Versión: 1.0
- Estado: Borrador
- Fecha: 2026-06-21
- ETAPA asociada: 4.11 (propuesta — ver roadmap)

> **Estado del borrador (2026-06-21):** decisiones cerradas — precios por snapshot (A,
> ADR-0012) y transporte **Wi-Fi/LAN (socket TCP:9100)** (ADR-0013). Los REQ de impresión
> son independientes del transporte; el detalle de conexión vive en `plan.md` y ADR-0013.
> Pendiente solo la aprobación formal de la spec y su agenda (ETAPA 4.11 propuesta).

## 1. Problema / Oportunidad

El mesero (WAITER) necesita entregar al cliente una **cuenta impresa** de un pedido ya
terminado: el desglose de lo consumido (cantidad × producto × precio) y el total a pagar.
Hoy no existe impresión; la cuenta solo se ve en pantalla.

Para que la cuenta sea correcta y auditable surge un prerrequisito de datos: el precio de
cada línea debe ser el que se **cobró**, no el del catálogo actual. El modelo actual no
guarda precio en el pedido (`Item` solo tiene `productId`/`quantity`), y el **Artículo II**
prohíbe que el frontend calcule precios/totales que diverjan del backend. Por eso esta
feature incluye un **snapshot de precio** por línea (decisión "A", ver ADR de precios).

Impresora objetivo: **POS-8370** (familia Zijiang ZJ-8370), térmica 80mm, **ESC/POS**,
con auto-cutter; conectividad USB / Ethernet(LAN) / Bluetooth. **Transporte elegido:
Wi-Fi/LAN** — la impresora tiene IP fija en la red de la taquería y la app le envía los
bytes ESC/POS por un socket TCP al puerto 9100 (ADR-0013).

## 2. Objetivos

- **Snapshot de precio:** congelar `unitPrice` por `Item` al crear/editar el pedido, de
  modo que la cuenta refleje el precio cobrado y no cambie si el catálogo cambia después.
- **Impresión manual de la cuenta:** un botón "Imprimir ticket" que el WAITER dueño activa
  sobre un pedido completado, generando un ticket con el desglose y el total.
- **Total correcto sin violar el Artículo II:** el frontend suma `unitPrice × quantity`
  sobre precios **congelados** (presentación), no recalcula precios del catálogo.
- **Salida ESC/POS** hacia la POS-8370, con manejo de fallo de conexión que no afecte el
  estado de la orden.

## 3. No-objetivos

- **Comanda de cocina** (ticket sin precios al crear el pedido): futura spec si se requiere.
- **Impresión automática** al transicionar de estado: este MVP es solo manual.
- **Cobro / pago / propinas / impuestos desglosados**: la cuenta es informativa, no fiscal.
  Sin folios fiscales, IVA desglosado ni timbrado (futuro, requeriría ADR y backend fiscal).
- **Precios de complementos**: en el modelo actual los complementos no tienen precio.
- **Selección/gestión avanzada de impresoras** (varias impresoras, colas): MVP de una
  impresora configurada por dispositivo/taquería (a definir en plan según transporte).

## 4. Actores

- **WAITER** — único actor que imprime la cuenta, y solo de sus propios pedidos.
- **Sistema (backend)** — congela `unitPrice` al persistir items; expone el dato.
- **Sistema (mobile)** — renderiza el ticket a ESC/POS y lo envía a la impresora.

## 5. User Stories

- US-1: Como WAITER quiero imprimir la cuenta de un pedido listo para entregársela al
  cliente con el desglose y el total.
- US-2: Como dueño de la taquería quiero que la cuenta muestre el precio al que se vendió
  cada producto, aunque luego haya cambiado el precio en el catálogo.
- US-3: Como WAITER quiero que, si la impresora no responde, se me avise y pueda reintentar
  sin que el pedido se altere.

## 6. Acceptance Criteria (Gherkin)

> Los REQ-0070 a REQ-0073 son el **prerrequisito de precios** (tocan creación/append de
> órdenes). Los REQ-0074 a REQ-0079 son la **impresión** propiamente dicha.

### REQ-0070 — POST /orders congela unitPrice por item

```gherkin
Dado un producto "Coca" con price=20 en el catálogo
Cuando un WAITER crea una orden con 5 unidades de "Coca"
Entonces cada item persistido guarda unitPrice=20 (snapshot del precio al crear)
Y el unitPrice se devuelve en el payload de la orden
```

### REQ-0071 — PATCH /orders/:id (append) congela unitPrice en items nuevos

```gherkin
Dado una orden existente
Cuando el WAITER agrega un plate con un item de un producto con price=35
Entonces el item nuevo guarda unitPrice=35
Y los items previos conservan su unitPrice original sin cambios
```

### REQ-0072 — unitPrice es inmutable ante cambios posteriores del catálogo

```gherkin
Dado una orden con un item de "Coca" guardado con unitPrice=20
Cuando luego el COOK cambia el price de "Coca" a 25 en el catálogo
Entonces el item de esa orden sigue con unitPrice=20
Y la cuenta de esa orden sigue calculándose con 20
```

### REQ-0073 — Migración: backfill best-effort de unitPrice en items existentes

```gherkin
Dado items de órdenes creados antes de esta feature (sin unitPrice)
Cuando se ejecuta la migración
Entonces cada item recibe unitPrice = price actual de su producto en el catálogo (best-effort)
Y si el producto fue borrado, el item queda con unitPrice = null
```

### REQ-0074 — WAITER imprime la cuenta de un pedido completado (manual)

```gherkin
Dado un WAITER autenticado dueño de un pedido en status READY o DELIVERED
Cuando toca "Imprimir ticket"
Entonces se genera la cuenta del pedido y se envía a la impresora
Y el botón NO está disponible para pedidos en PENDING, PREPARING o CANCELLED
```

### REQ-0075 — Solo el WAITER dueño imprime; COOK no

```gherkin
Dado un pedido de la taquería
Cuando un COOK ve el pedido
Entonces no se ofrece la acción de imprimir cuenta
Y cuando un WAITER que NO es el dueño del pedido lo ve, tampoco se le ofrece imprimir
```

### REQ-0076 — Contenido de la cuenta

```gherkin
Dado un pedido con varios items
Cuando se genera el ticket
Entonces incluye: nombre de la taquería y restaurantCode, tipo y referencia del pedido,
  fecha y hora, una línea por item (cantidad, nombre de producto, unitPrice y subtotal),
  y el total del pedido
```

### REQ-0077 — Total = suma de unitPrice × quantity (frontend, sobre precios congelados)

```gherkin
Dado un pedido con 5 "Coca" a unitPrice=20 y 2 "Taco" a unitPrice=15
Cuando se genera el ticket
Entonces cada subtotal es unitPrice × quantity (100 y 30)
Y el total es la suma de los subtotales (130)
Y el frontend calcula la suma sobre los unitPrice congelados, sin leer el catálogo
```

### REQ-0078 — Sin unitPrice completo, no se emite la cuenta

```gherkin
Dado un pedido (legacy) con al menos un item sin unitPrice (producto borrado)
Cuando el WAITER intenta imprimir la cuenta
Entonces la impresión se bloquea
Y se informa que el pedido no tiene precios completos para emitir la cuenta
```

### REQ-0079 — Emisión ESC/POS con manejo de fallo de conexión

```gherkin
Dado un pedido imprimible y una impresora configurada
Cuando el WAITER toca "Imprimir ticket" y la impresora no responde
Entonces se muestra un error y se ofrece reintentar
Y el status, revision e items del pedido NO se modifican por el intento de impresión
```

### REQ-0080 — Configuración de impresora LAN (host:puerto) requerida y persistida

```gherkin
Dado que no hay impresora configurada en el dispositivo
Cuando el WAITER intenta imprimir
Entonces se le pide configurar la impresora (host IP y puerto, default 9100)
Y la configuración se persiste y se reutiliza en siguientes impresiones
Y un host inválido o inalcanzable produce un error claro (no un fallo silencioso)
```

## 7. Edge Cases

- **Pedido sin items** (no debería existir por validación de creación) → botón deshabilitado.
- **Producto borrado del catálogo** tras vender → el `unitPrice` congelado se conserva, así
  que la cuenta SÍ se imprime con el precio cobrado (solo bloquea si el item es legacy sin
  snapshot, REQ-0078).
- **Reimpresión**: imprimir dos veces produce dos copias idénticas (no hay folio único).
- **Texto largo** (nombre de producto, referencia) → se ajusta/trunca al ancho de 80mm
  (~48 caracteres, Font A).
- **Impresora ocupada / dos meseros imprimen a la vez** → comportamiento depende del
  transporte (a definir en plan); el MVP reintenta.
- **Append después de imprimir**: si se agregan items tras imprimir, la cuenta previa queda
  desactualizada; reimprimir refleja el nuevo total (sin invalidar la copia anterior).

## 8. Requerimientos no funcionales

- **Backend como fuente de verdad (Artículo II):** el `unitPrice` es autoritativo del
  backend (snapshot). El frontend solo **multiplica y suma** para el total — aritmética de
  presentación sobre datos autoritativos, no recálculo divergente del catálogo.
- **Ownership / Multi-tenancy (Artículos I, III):** solo el WAITER dueño imprime; el pedido
  se obtiene con los filtros de `taqueriaId`/`waiterId` ya existentes.
- **Dinero:** `unitPrice` (y cualquier total persistido) se almacena como `Decimal` o
  enteros en centavos — nunca `float` — para evitar errores de redondeo.
- **Resiliencia:** un fallo de impresión es un problema de dispositivo/periférico; NUNCA
  revierte ni altera el estado de la orden en BD (análogo a la regla de emisión Socket.IO).
- **Compatibilidad:** ESC/POS estándar (la POS-8370 lo soporta); el renderizado del ticket
  no depende de comandos propietarios.

## 9. Dependencias

- Spec: `specs/create-order/spec.md` y `specs/edit-order/spec.md` — el snapshot de
  `unitPrice` modifica (aditivamente) la creación y el append de items.
- Spec: `specs/kitchen-queue/spec.md` — define los status READY/DELIVERED que habilitan la
  impresión.
- **Contrato:** `item.unitPrice` agregado a `Item` en `contracts/openapi.yaml` (2.2.0) y
  `contracts/asyncapi.yaml` (1.2.0) — bump aditivo. No se persiste `order.total` (derivado).
- **ADR-0012** — Snapshot de precio unitario (`unitPrice`) en órdenes (decisión de precios "A").
- **ADR-0013** — Integración de impresión de tickets (transporte Wi-Fi/LAN TCP:9100,
  renderizado ESC/POS en frontend, config de impresora por dispositivo).

## 10. Decisiones cerradas y riesgos

Decisiones tomadas (2026-06-21):

- ✅ **Transporte: Wi-Fi/LAN** (socket TCP:9100). Impresora fija compartida por taquería
  (ADR-0013).
- ✅ **"Completado" = `READY` o `DELIVERED`** (no `PENDING`/`PREPARING`/`CANCELLED`).
- ✅ **Total derivado en el frontend** desde `unitPrice`; el contrato agrega solo
  `item.unitPrice` (no se persiste `order.total`).
- ✅ **Config de impresora: por dispositivo** (host:puerto en almacenamiento local) para el
  MVP (REQ-0080). Config centralizada por taquería en backend = futuro.

Riesgos / preguntas abiertas:

- ❓ **Impresora compartida y concurrencia:** dos meseros imprimiendo a la vez sobre el
  mismo socket. La POS-8370 procesa en serie; el MVP reintenta ante conexión ocupada
  (REQ-0079). Si hay contención real, evaluar cola de impresión (futuro).
- ❓ **Dependencia de red:** sin Wi-Fi/LAN operativa no hay impresión. Bluetooth quedaría
  como alternativa futura (otro ADR) si la red no es confiable.
- ❓ **iOS:** por LAN/TCP la POS-8370 sí funcionaría en iOS; el bloqueo de Bluetooth no
  aplica a esta ruta. Irrelevante mientras el proyecto sea solo Android.
- ❓ **Cuenta fiscal:** este MVP NO es comprobante fiscal. Si el negocio lo requiere luego,
  será otra spec + ADR (folios, IVA, timbrado).

## 11. Referencias

- `business-rules.md` — Pricing System (precios y subtotales)
- `glossary.md` — Cuenta (Ticket), unitPrice, ESC/POS
- POS-8370 / Zijiang ZJ-8370 — 80mm, ESC/POS, USB/LAN/Bluetooth, auto-cutter
  - https://www.snroprinter.com/shop/pos8370/
  - http://www.zjiang.com/en/init.php/product/index?id=70
- Librería candidata (Bluetooth, Android): https://github.com/januslo/react-native-bluetooth-escpos-printer
