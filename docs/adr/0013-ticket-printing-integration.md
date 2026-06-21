# ADR-0013: Integración de impresión de tickets (Wi-Fi/LAN, ESC/POS)

- Estado: Aceptado
- Fecha: 2026-06-21
- Autores: Equipo TacosManager

## Contexto

`specs/ticket-printing/` requiere imprimir la cuenta del cliente en una **POS-8370**
(familia Zijiang ZJ-8370): térmica 80mm, ESC/POS, auto-cutter, con conectividad
USB / Ethernet(LAN) / Bluetooth.

Hay que decidir tres cosas de integración:

1. **Transporte** app ↔ impresora.
2. **Dónde se renderiza** el ticket (qué genera los bytes ESC/POS).
3. **Dónde vive la configuración** de la impresora.

Restricciones conocidas:

- El proyecto mobile es **solo Android** (flavors Android, `run-android`, Play Store).
- El Bluetooth de estos equipos suele ser **Classic SPP** (no BLE, no MFi): funcionaría en
  Android pero no en iOS.
- USB-OTG hacia un teléfono/tablet es poco práctico para operación real.

## Decisión

### 1. Transporte: Wi-Fi/LAN (socket TCP, puerto 9100)

La impresora tiene **IP fija** en la red de la taquería. La app abre un **socket TCP al
puerto 9100** (raw printing) y escribe el flujo de bytes ESC/POS. Es una impresora
**compartida por la taquería** (típicamente en barra/caja).

Razones: una sola impresora compartida encaja con la operación; funciona en Android e iOS
por igual (no nos casa con Bluetooth Classic); no depende de emparejamiento por dispositivo.

### 2. Renderizado en el frontend (mobile)

El ticket se construye en el cliente como **comandos ESC/POS** (texto, alineación, énfasis,
corte `GS V`), diseñado para 80mm (~48 caracteres, Font A). El backend NO genera el ticket
ni participa en la transmisión: provee los **datos** (orden + `item.unitPrice` snapshot,
ADR-0012) y el frontend los formatea y envía. Esto respeta el Artículo II (el backend es
fuente de verdad de los datos; imprimir es presentación/periférico).

### 3. Configuración de impresora: por dispositivo (MVP)

`host:puerto` (default 9100) se guarda en almacenamiento local del dispositivo (REQ-0080).
Requisito previo para imprimir; host inalcanzable → error claro, sin fallo silencioso.
Configuración centralizada por taquería (en backend) queda como mejora futura.

### Manejo de fallos

Un fallo de impresión (red caída, host inalcanzable, impresora ocupada) muestra error y
permite reintentar, y **NUNCA** altera el estado de la orden en BD (análogo a la regla de
emisión Socket.IO: la persistencia tiene prioridad sobre el periférico). REQ-0079.

## Alternativas consideradas

- **Bluetooth Classic (SPP), Android.** Bueno para impresora portátil junto al mesero, sin
  depender de red. Pero: una por dispositivo a emparejar, sin iOS, y no encaja con
  "impresora compartida". Queda como alternativa futura si la red no es confiable.
- **USB-OTG.** Descartada: poco práctica en tablets/teléfonos para operación diaria.
- **Renderizado/impresión desde el backend** (servicio de impresión server-side). Mayor
  complejidad de infraestructura (el backend tendría que alcanzar la impresora en la LAN del
  local); descartada para el MVP.

## Consecuencias

Positivas:
- Una impresora compartida, sin emparejar dispositivos; cross-platform.
- El backend no se acopla al periférico; imprimir es 100% cliente.
- ESC/POS estándar: hay librerías reutilizables; sin comandos propietarios.

Negativas:
- **Depende de la red local**: sin Wi-Fi/LAN no hay impresión.
- **Concurrencia**: dos meseros sobre el mismo socket; el MVP reintenta (posible cola futura).
- Config por dispositivo: cada dispositivo se configura una vez.

Neutrales:
- Migrar a config centralizada por taquería o agregar Bluetooth como alternativa requerirán
  ADRs nuevos.

## Referencias

- Constitución Artículo II — Backend como Fuente de Verdad
- Constitución Artículo IV — regla "persistir antes de emitir" (analogía para fallos)
- `specs/ticket-printing/spec.md` — REQ-0074 a REQ-0080
- ADR-0012 — Snapshot de precio unitario
- POS-8370 / Zijiang ZJ-8370 (80mm, ESC/POS, LAN/Bluetooth/USB)
