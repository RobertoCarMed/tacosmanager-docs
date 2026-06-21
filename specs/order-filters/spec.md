# Spec: Order Filters (Visibilidad de Órdenes)

- ID: SPEC-order-filters
- Versión: 1.0
- Estado: Implementada (spec retroactiva)
- Fecha: 2026-06-21
- ETAPA asociada: 4.8

> **Origen (2026-06-21):** el sistema de filtros de órdenes se implementó de forma
> oportunista junto con la migración de órdenes (post-ETAPA 4.5.3) y quedó descrito en
> prosa en `business-rules.md §31`, `feature-list.md` y `ui-flows.md`, pero sin spec ni
> REQ-IDs. Esta spec formaliza retroactivamente el comportamiento ya construido y entra al
> flujo SDD. Coincide exactamente con el alcance de ETAPA 4.8 "History & Filters" (mismos
> filtros, mismos roles), por lo que esa etapa pasa a ✅ COMPLETADA. La paginación y la
> optimización de queries son ETAPA 4.9 (Performance), fuera de alcance aquí.

## 1. Problema / Oportunidad

Las pantallas de órdenes (mesero y cocina) muestran una lista que crece sin límite.
El personal necesita dos modos de uso distintos:

1. **Operación en vivo:** ver lo que está pasando ahora (pedidos no terminados),
   sin que un cambio de día los oculte.
2. **Consulta de historial:** revisar pedidos por rango de fecha, incluidos los ya
   entregados o cancelados, para auditoría informal y seguimiento.

El detonante concreto fue un bug de visibilidad: un pedido creado a las 23:55 con
status `PENDING` desaparecía de la pantalla a las 00:00 cuando el filtro por defecto
era "hoy" (`today`), porque ese filtro excluye pedidos con `createdAt` anterior al
inicio del día actual. Esto rompía la operación nocturna de meseros y cocina.

## 2. Objetivos

- Ofrecer un filtro **`active`** por defecto que muestre los pedidos en curso
  (status no terminal) **sin límite de fecha**, resolviendo el edge case de medianoche.
- Ofrecer filtros **históricos** por rango de fecha (`today`, `7d`, `1m`, `3m`) que
  muestren **todos los statuses** dentro del rango (incluidos `DELIVERED` y `CANCELLED`).
- Aplicar el filtrado **en el cliente** sobre la lista que ya entrega `GET /orders`,
  como lógica de presentación, sin alterar el orden base ni el aislamiento provistos
  por el backend.
- Mantener el comportamiento idéntico en las pantallas de mesero y cocina, respetando
  el aislamiento por rol (WAITER ve solo lo suyo; COOK ve todo lo de la taquería).

## 3. No-objetivos

- Filtrado **server-side** ni query params en `GET /orders` (evolución futura; ver
  Riesgos y ETAPA 4.9). Hoy el backend NO recibe parámetros de filtro.
- Paginación y optimización de queries (ETAPA 4.9 — Performance).
- Filtros por `OrderType` (DINE_IN/TAKEAWAY/DELIVERY), por mesero, o por texto libre.
- Filtros configurables/persistentes por usuario.
- Reportes, exportación o estadísticas (futuro).

## 4. Actores

- **WAITER** — filtra su propia lista de pedidos (`WaiterOrdersScreen`).
- **COOK** — filtra la lista completa de la taquería (`KitchenScreen`,
  `KitchenDashboardScreen`).

## 5. User Stories

- US-1: Como COOK quiero que un pedido activo creado anoche siga visible esta mañana
  para no perder pedidos por el cambio de día.
- US-2: Como WAITER quiero ver por defecto solo mis pedidos en curso para enfocarme en
  lo que falta entregar.
- US-3: Como COOK/WAITER quiero cambiar a "Hoy" / "7 días" / "1 mes" / "3 meses" para
  consultar el historial, incluidos los pedidos ya entregados o cancelados.
- US-4: Como usuario quiero que el cambio de filtro sea inmediato (sin recargar de red)
  porque ya tengo la lista cargada.

## 6. Acceptance Criteria (Gherkin)

### REQ-0063 — Filtro por defecto es `active` en mesero y cocina

```gherkin
Dado un WAITER o COOK autenticado que abre su pantalla de órdenes
Cuando la pantalla carga por primera vez
Entonces el filtro seleccionado es "active"
Y las opciones disponibles son: Activos, Hoy, Últimos 7 días, Último mes, Últimos 3 meses
```

### REQ-0064 — `active` muestra status no terminal sin límite de fecha

```gherkin
Dado un conjunto de pedidos con status variados y distintas fechas de creación
Cuando el filtro seleccionado es "active"
Entonces se muestran solo los pedidos con status PENDING, PREPARING o READY
Y se ocultan los pedidos con status DELIVERED o CANCELLED
Y NO se aplica ningún límite por createdAt (sin importar cuándo se crearon)
```

### REQ-0065 — Un pedido activo de ayer no desaparece a medianoche

```gherkin
Dado un pedido creado ayer a las 23:55 con status PENDING
Cuando hoy se consulta la lista con el filtro "active"
Entonces el pedido sigue visible
Y no desaparece por el cambio de día (a diferencia del filtro "today")
```

### REQ-0066 — Filtro `today` usa la medianoche en hora local del dispositivo

```gherkin
Dado el filtro "today"
Y la hora local del dispositivo
Cuando se filtra la lista
Entonces se muestran solo los pedidos con createdAt mayor o igual a la medianoche de hoy en hora local
Y se incluyen todos los statuses dentro de ese rango
```

### REQ-0067 — Filtros `7d`/`1m`/`3m` son ventanas móviles en hora local

```gherkin
Dado el filtro "7d" (o "1m", o "3m")
Cuando se filtra la lista
Entonces se muestran los pedidos con createdAt mayor o igual a (ahora − 7 días | 1 mes | 3 meses) calculado en hora local del dispositivo
Y la ventana es móvil (relativa al instante actual, no a límites de calendario)
```

### REQ-0068 — Los filtros históricos incluyen TODOS los statuses

```gherkin
Dado pedidos DELIVERED y CANCELLED creados dentro del rango de fecha
Cuando el filtro es "today", "7d", "1m" o "3m"
Entonces esos pedidos DELIVERED y CANCELLED SÍ aparecen en la lista
Y únicamente el filtro "active" excluye los statuses terminales
```

### REQ-0069 — El filtrado es client-side y preserva orden base y aislamiento

```gherkin
Dado que GET /orders ya devolvió la lista ordenada por rol (COOK: prioridad de cocina; WAITER: createdAt DESC) y aislada por taquería y ownership
Cuando el frontend aplica cualquier filtro
Entonces el filtrado solo oculta filas localmente, sin reordenar ni hacer una nueva llamada de red
Y un WAITER nunca ve pedidos de otro mesero en ningún filtro
Y el orden relativo de los pedidos visibles se conserva tal como lo entregó el backend
```

## 7. Edge Cases

- **Sin pedidos en el filtro seleccionado** → se muestra estado vacío; cambiar de filtro
  vuelve a poblar sin recargar de red.
- **Cambio de día con la pantalla abierta** → un pedido activo permanece en `active`;
  bajo `today` saldrá del rango al cruzar medianoche (comportamiento esperado de `today`).
- **Pedido que transiciona a `DELIVERED`/`CANCELLED`** → desaparece de `active` en tiempo
  real (vía evento `order-status-changed`), pero sigue consultable en los filtros históricos.
- **Reloj del dispositivo desfasado** → los rangos se calculan con la hora local del
  dispositivo; un reloj mal configurado afecta el filtrado (riesgo conocido, ver §10).
- **Append a un pedido `READY` (CASO 3)** → vuelve a `PENDING`, sigue dentro de `active`.

## 8. Requerimientos no funcionales

- **Backend como fuente de verdad (Artículo II):** el filtrado es **presentación**, no
  estado derivado divergente. El frontend NO recalcula precios, totales, transiciones ni
  el **orden** de cocina; solo oculta/muestra filas de una lista ya ordenada por el backend.
  Por eso el filtrado client-side es compatible con el Artículo II.
- **Multi-tenancy / Ownership (Artículos I y III):** el aislamiento lo garantiza el
  backend en `GET /orders` (WAITER solo sus pedidos; COOK los de su taquería). El filtro
  nunca puede ampliar la visibilidad más allá de lo que el backend ya entregó.
- **Realtime (Artículo IV):** los eventos Socket.IO actualizan la lista subyacente; el
  filtro activo se reaplica sobre el nuevo estado sin recargar de red.
- **Performance:** el cambio de filtro es una operación en memoria (O(n) sobre la lista
  cargada), sin latencia de red. Para volúmenes grandes, ver ETAPA 4.9 (paginación).

## 9. Dependencias

- Spec: `specs/create-order/spec.md` y `specs/edit-order/spec.md` (origen de los pedidos).
- Spec: `specs/kitchen-queue/spec.md` (orden base que el filtro preserva).
- Spec: `specs/realtime-sync/spec.md` (la lista se actualiza por eventos).
- ADRs: ADR-0004 (backend como fuente de verdad), ADR-0010 (orden de cocina que se preserva).
- Contratos: `contracts/openapi.yaml#/paths/~1orders` (`GET /orders`, sin params de filtro).

## 10. Riesgos / Preguntas abiertas

- ❓ **Hora local del dispositivo:** los rangos dependen del reloj del dispositivo. Un
  reloj desfasado filtra mal. Migrar el cálculo a hora del servidor exigiría enviar el
  rango al backend (filtrado server-side) — ver siguiente punto.
- ❓ **Escalabilidad:** filtrar en cliente requiere haber traído toda la lista. Con miles
  de pedidos históricos esto no escala; ETAPA 4.9 evaluará filtrado + paginación
  server-side (query params en `GET /orders`), lo que implicaría bump de contrato y
  nuevos REQ.
- ❓ **Definición de "1 mes"/"3 meses":** se usa resta de meses calendario sobre el
  instante actual en hora local (ej. 21-jun − 1 mes = 21-may). Si se requiriera otra
  semántica (días fijos), sería un REQ nuevo.

## 11. Referencias

- `business-rules.md` §31 — Visibilidad de Pedidos / Filtro Activo
- `feature-list.md` — Order Filters (Active + Historical)
- `ui-flows.md` — Waiter Orders Filter / Kitchen Flow
- `roadmap.md` — ETAPA 4.8 History & Filters
- `glossary.md` — Filtro Activo, Filtros Históricos
