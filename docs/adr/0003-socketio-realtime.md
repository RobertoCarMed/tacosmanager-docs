# ADR-0003: Socket.IO v4 para realtime

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

La cocina necesita ver pedidos nuevos sin polling. Los meseros necesitan saber cuando una orden cambia de estado para actualizar su UI. El medio es una red Wi-Fi de restaurante (caídas frecuentes).

Requisitos:
1. Reconexión automática transparente.
2. Aislamiento por taquería (un room por tenant).
3. Compatible con auth JWT.
4. Soporte React Native maduro.

## Decisión

Adoptamos **Socket.IO v4** en el mismo proceso/puerto que la API REST (3000 por defecto).

- Cliente: token JWT en `auth.token` del handshake.
- Al conectar, el server **automáticamente** une al socket al room `taqueria:<taqueriaId>`. El cliente no necesita gestionar rooms manualmente.
- Eventos servidor → cliente: `order-created`, `order-updated`, `order-status-changed`.
- Evento cliente → servidor: `join-taqueria` (idempotente, confirma room activa).
- Payloads tipados, declarados en `contracts/asyncapi.yaml`.
- Reconexión: librería Socket.IO maneja el backoff exponencial. Tras reconectar, el cliente solicita resync (REQ-0053).

## Alternativas consideradas

- **WebSockets crudos** — más liviano pero sin reconexión ni rooms out-of-the-box.
- **Server-Sent Events** — unidireccional, no sirve para el handshake auth ni eventos cliente→servidor.
- **Firebase Realtime DB / Firestore** — fuerte acoplamiento a Google, modelo de datos limita reglas de negocio.

## Consecuencias

Positivas:
- Reconexión automática out-of-the-box.
- Rooms como mecanismo natural de tenancy.
- Mismo proceso que REST: sin infra adicional.

Negativas:
- Protocolo propio (no estándar WebSocket puro). Lock-in moderado.
- Escala horizontal requiere `socket.io-redis` adapter (no instalado aún — ADR futuro cuando aplique).

Neutrales:
- En el futuro podemos migrar a WebSockets nativos preservando los nombres de eventos del contrato AsyncAPI.

## Referencias

- Constitución Artículo IV — Realtime Coherente
- `backend-realtime.md`
- `contracts/asyncapi.yaml`
- REQ-0026, REQ-0036, REQ-0045, REQ-0050, REQ-0051, REQ-0052, REQ-0053, REQ-0054
