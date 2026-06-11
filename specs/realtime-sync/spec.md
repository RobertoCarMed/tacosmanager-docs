# Spec: Realtime Sync

- ID: SPEC-realtime-sync
- Estado: Implementada
- ETAPA asociada: 4.5.4, 4.7.1, 4.7.2, 4.7.3

## 1. Problema

Cocina y meseros deben ver el estado actualizado de las órdenes en tiempo real sin polling. La red Wi-Fi del restaurante puede caer; el sistema debe recuperar consistencia tras reconexión.

## 2. Objetivos

- Autenticación de sockets con el mismo JWT que REST.
- Aislamiento por room `taqueria:<taqueriaId>`.
- Eventos `order-created`, `order-updated`, `order-status-changed`.
- Reconexión automática y resync sin pérdida de consistencia.
- Soporte multi-device (varios cocineros / varios meseros).

## 3. No-objetivos

- Distribución horizontal con Redis (ADR futuro cuando aplique).
- Acknowledgements obligatorios por evento.

## 4. Actores

- COOK / WAITER conectados desde mobile.

## 5. User Stories

- US-1: Como COOK quiero ver pedidos nuevos en pantalla apenas el WAITER los crea.
- US-2: Como WAITER quiero ver el cambio de status de mis órdenes cuando la cocina avanza.
- US-3: Como COOK que perdió Wi-Fi 30 segundos, quiero que mi pantalla quede sincronizada al reconectar.
- US-4: Como dueño con un cocinero usando tablet y otro usando celular, quiero que ambos vean lo mismo.

## 6. Acceptance Criteria

### REQ-0050 — Socket sin JWT es rechazado
```gherkin
Cuando un cliente intenta conectar a Socket.IO sin token o con token inválido
Entonces la conexión es rechazada
```

### REQ-0051 — Socket conectado se une a taqueria:<taqueriaId>
```gherkin
Dado un usuario con JWT válido de taquería "TM-0001"
Cuando conecta a Socket.IO
Entonces queda unido automáticamente al room "taqueria:<id-de-TM-0001>"
```

### REQ-0052 — Usuarios de distintas taquerías nunca comparten room
```gherkin
Dado un usuario A de "TM-0001" y un usuario B de "TM-0002" conectados
Cuando A genera un evento que emite al room de "TM-0001"
Entonces B NO recibe ese evento
```

### REQ-0053 — Tras reconexión, cliente puede resincronizar
```gherkin
Dado un COOK conectado que pierde conexión
Cuando reconecta tras 30 segundos
Entonces solicita estado actual de órdenes
Y la UI queda consistente con el servidor
```

### REQ-0054 — Multi-device del mismo user recibe eventos
```gherkin
Dado un COOK conectado desde dispositivo A y dispositivo B simultáneamente
Cuando se emite un evento al room
Entonces ambos dispositivos lo reciben
```

## 7. Edge Cases

- JWT expira durante la sesión socket → desconexión + retry de login.
- Cliente recibe un evento de orden que no conoce localmente → pide GET /orders/:id.

## 8. Requerimientos no funcionales

- Constitución Artículo IV (Realtime Coherente).
- Latencia p95 server-to-client < 500ms en red estable.

## 9. Dependencias

- ADR-0003 (Socket.IO).
- Contrato: `contracts/asyncapi.yaml`.

## 10. Referencias

- `backend-realtime.md`
- `feature-list.md` — Realtime
