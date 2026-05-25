# TacosManager - Reglas de Negocio

Versión: 1.2
Estado: Backend NestJS + Prisma + PostgreSQL
Última actualización: Etapa 4.6.3 — ETAPA 4.5 ✅ y ETAPA 4.6 ✅ completadas

---

# 1. Descripción General

TacosManager es una plataforma SaaS multi-taquería diseñada para administrar:

- Catálogo de productos
- Pedidos
- Cocina
- Historial de órdenes
- Operación diaria de meseros y cocineros

La plataforma permite que múltiples taquerías operen simultáneamente de forma aislada utilizando arquitectura multi-tenant.

---

# 2. Arquitectura Multi-Tenant

## Principio General

Toda la información pertenece a una taquería.

Ningún usuario puede acceder a información de otra taquería.

---

## Entidad Taquería

Cada taquería posee:

- id
- name
- restaurantCode

---

## restaurantCode

Es el identificador único real de una taquería.

Ejemplos:

- TQR-4821
- TM-9182
- TACO-1832

Reglas:

- Debe ser único
- Se genera automáticamente
- No puede modificarse manualmente

---

## Nombre de Taquería

Reglas:

- Pueden existir múltiples taquerías con el mismo nombre
- El nombre NO es un identificador único
- El restaurantCode es el identificador oficial

Ejemplo válido:

Taquería El Güero
- TQR-1111

Taquería El Güero
- TQR-2222

---

# 3. Usuarios

## Roles

### COOK

Puede:

- Ver todos los pedidos de la taquería
- Cambiar estados de pedidos
- Gestionar cocina
- Ver historial completo

No puede:

- Acceder a otras taquerías

---

### WAITER

Puede:

- Crear pedidos
- Consultar sus pedidos
- Editar pedidos propios

No puede:

- Ver pedidos de otros meseros
- Cambiar estados de cocina
- Acceder a otras taquerías

---

# 4. Registro Inteligente

## Flujo General

El frontend solicita:

- name
- email
- password
- role
- taqueriaName

---

## Escenario 1

### No existen coincidencias

Respuesta:

- Permitir crear nueva taquería

---

## Escenario 2

### Existe una coincidencia

Respuesta:

- Permitir unirse
- Permitir crear una nueva taquería con el mismo nombre

---

## Escenario 3

### Existen múltiples coincidencias

Respuesta:

- Mostrar lista de coincidencias
- Permitir seleccionar una
- Permitir crear una nueva

---

# 5. Productos

## Product

Campos principales:

- id
- name
- price
- complements
- taqueriaId

---

## Reglas

Todos los productos pertenecen a una taquería.

Los usuarios sólo pueden consultar productos de su propia taquería.

---

## Complementos

Máximo:

3 complementos por producto.

---

# 6. Pedidos

---

## Order

Representa una orden completa.

Contiene:

- waiter
- taquería
- plates
- status
- revision
- priorityTimestamp

---

## Tipos de Pedido (OrderType)

Cada orden tiene un tipo que determina el contexto de servicio:

### DINE_IN (predeterminado)

Mesa en el local.

Campo requerido: `reference` (número o nombre de mesa).

Ejemplos: `Mesa 3`, `Barra 2`, `Terraza`.

---

### TAKEAWAY

Para llevar, cliente en el local.

Campo requerido: `reference` (nombre del cliente).

Ejemplos: `Juan`, `Familia López`.

---

### DELIVERY

Entrega a domicilio.

Campo requerido: `deliveryAddress` (dirección de entrega).

`reference` es opcional (nombre del cliente que recibe el pedido).

Ejemplos: `Av. Insurgentes 123 Col. Roma`.

---

## reference

Campo `String?` (nullable). Renombrado de `tableNumber` en Etapa 4.6.1.

Requerido para DINE_IN y TAKEAWAY.

Opcional para DELIVERY (nombre del cliente que recibe el pedido).

---

## deliveryAddress

Campo `String?` (nullable).

Requerido para DELIVERY.

Null para DINE_IN y TAKEAWAY.

---

## Reglas de Validación por Tipo

| OrderType | reference  | deliveryAddress | Comportamiento              |
|-----------|------------|-----------------|------------------------------|
| DINE_IN   | requerido  | ignorado        | Error si reference está vacío |
| TAKEAWAY  | requerido  | ignorado        | Error si reference está vacío |
| DELIVERY  | opcional   | requerido       | Error si deliveryAddress vacío |

---

# 7. Plates

Representan agrupaciones visuales dentro de una orden.

Ejemplo:

PLATE 1
- Taco Pastor
- Taco Asada

PLATE 2
- Quesadilla
- Horchata

---

Campos:

- id
- orderId
- plateNumber
- isClosed
- createdInRevision

---

# 8. Items

Representan productos individuales.

Campos:

- id
- plateId
- productId
- quantity
- selectedComplements
- notes
- isNew
- createdInRevision

---

## Notes

Las notas son opcionales.

Ejemplos válidos:

```json
{
  "notes": ""
}
```

```json
{
}
```

```json
{
  "notes": "Sin salsa"
}
```

---

# 9. Historial

Los pedidos nunca deben eliminarse físicamente.

Objetivos:

- Auditoría
- Historial
- Reportes
- Estadísticas futuras

---

# 10. Regla Crítica de Edición

## Append Only Editing

Los pedidos NO se modifican.

Los pedidos se amplían.

---

## Permitido

Agregar:

- Nuevos plates
- Nuevos items

---

## Prohibido

Modificar:

- Plates existentes
- Items existentes
- Cantidades anteriores
- Productos anteriores

---

Ejemplo:

Pedido original:

PLATE 1
- Taco Pastor
- Taco Asada

Cliente pide más:

PLATE 2
- Quesadilla
- Horchata

PLATE 1 permanece intacto.

---

# 11. Revisions

Cada pedido posee:

revision

---

Pedido nuevo:

revision = 1

---

Primera actualización:

revision = 2

---

Segunda actualización:

revision = 3

---

Objetivo:

- Trazabilidad
- Realtime futuro
- Auditoría

---

# 12. createdInRevision

Permite identificar cuándo apareció un plate o item.

Ejemplo:

PLATE 1

createdInRevision = 1

---

PLATE 2

createdInRevision = 2

---

# 13. Estados de Pedido

Flujo oficial (ETAPA 4.5.6.1):

```txt
PENDING → PREPARING → READY → DELIVERED
```

Estados válidos:

- PENDING
- PREPARING
- READY
- DELIVERED
- CANCELLED
- ~~UPDATED~~ — `[DEPRECADO — ETAPA 4.5.6.1]`

---

## PENDING

Pedido recién creado, esperando que cocina lo tome.

Los pedidos PENDING pueden recibir modificaciones (Append Only). Ver sección 16.

---

## PREPARING

Pedido en preparación activa por cocina.

Los pedidos PREPARING pueden recibir modificaciones. Ver sección 16.

---

## READY

Pedido completamente preparado y listo para ser entregado.

Los pedidos READY pueden recibir modificaciones. Ver sección 16.

---

## DELIVERED

Pedido entregado. Estado terminal.

---

## CANCELLED

Pedido cancelado. Estado terminal.

---

## UPDATED `[DEPRECADO — ETAPA 4.5.6.1]`

Estado utilizado en implementaciones anteriores para señalar que un pedido recibió modificaciones mientras estaba en cocina.

**Reemplazado en ETAPA 4.5.6.1** por un mecanismo de seguimiento de cambios independiente del estado (`hasPendingChanges`, `pendingChanges` o tracking por `createdInRevision`), eliminando la necesidad de un estado de modificación separado.

UPDATED no forma parte del flujo oficial a partir de ETAPA 4.5.6.1. No debe usarse en nuevas implementaciones.

---

# 14. Prioridad de Cocina

Prioridades globales (implementado en ETAPA 4.5.6.1):

1. PREPARING
2. PENDING
3. READY
4. DELIVERED
5. CANCELLED

Los pedidos PREPARING representan trabajo activo del cocinero y encabezan la cola.

Los pedidos PENDING son trabajo nuevo que debe tomarse.

Los pedidos READY están listos — permanecen visibles hasta ser entregados.

---

# 15. Cola FIFO

Dentro de cada grupo se utiliza FIFO.

First In First Out.

---

Ejemplo:

Pedido A 12:00

Pedido B 12:05

Resultado:

Pedido A

Pedido B

---

# 16. Reglas de Modificación de Pedidos (Append Only)

Un pedido puede recibir nuevos plates/items en cualquier estado activo. El comportamiento difiere según el estado actual al momento de la modificación.

---

## CASO 1 — Modificación de pedido PENDING

El pedido está esperando que cocina lo tome.

Comportamiento:

- El estado **permanece PENDING** — no cambia.
- `priorityTimestamp` **no se actualiza** — el pedido conserva su posición FIFO original.
- Los nuevos items se marcan con el mecanismo de seguimiento de cambios (ver sección 16a).
- El cocinero verá los items nuevos destacados visualmente al tomar el pedido.

Ejemplo:

```txt
Pedido A → PENDING (12:00) → recibe modificación → sigue PENDING (12:00)
Pedido B → PENDING (12:05)

Cola: Pedido A, Pedido B  ← orden sin cambios
```

---

## CASO 2 — Modificación de pedido PREPARING

El pedido está siendo preparado activamente por cocina.

Comportamiento:

- El estado **permanece PREPARING** — no cambia.
- Los nuevos items se destacan visualmente (verde / badge) para que el cocinero identifique qué debe agregar.
- El mecanismo de seguimiento de cambios señala que hay pendientes nuevos.

---

## CASO 3 — Modificación de pedido READY

El pedido ya estaba terminado pero el cliente pidió más.

Comportamiento:

- El estado **revierte a PENDING** automáticamente.
- La cocina debe preparar los items nuevos antes de volver a marcar el pedido como READY.
- Los nuevos items se destacan visualmente.

---

# 16a. Mecanismo de Seguimiento de Cambios

Reemplaza el estado UPDATED (ver sección 13) como señal de que un pedido recibió modificaciones.

Mecanismo implementado (ETAPA 4.5.6.1): **`isNew: boolean` por item**.

- `isNew: true` → item creado por `PATCH /orders/:id` (append posterior)
- `isNew: false` → item creado en la orden original (`POST /orders`)
- Se limpia a `false` en todos los items de la orden al pasar a `READY`, en la misma transacción de BD
- Independiente del estado — aplica en PENDING, PREPARING, y el revert READY→PENDING (CASO 3)

---

# 17. priorityTimestamp

Campo utilizado para:

- Reordenamiento dentro del grupo de estado
- Priorización FIFO
- Realtime futuro

Debe actualizarse cuando:

- Se crea una orden (siempre)
- Se agregan nuevos plates/items a un pedido en estado **PREPARING** (CASO 2)

No debe actualizarse cuando:

- Se agregan nuevos plates/items a un pedido en estado **PENDING** — el pedido conserva su posición FIFO original (ver CASO 1, sección 16)

Esto garantiza que un pedido PENDING que recibe modificaciones no salte por delante de otros pedidos PENDING que llegaron antes en la cola.

---

# 18. Highlight Verde

Los nuevos productos agregados en actualizaciones deben mostrarse en verde.

---

## Activación

Cuando se agregan nuevos items a un pedido existente:

isNew = true

El highlight es independiente del estado de la orden. Aplica en PENDING, PREPARING y el caso de reversión desde READY (CASO 3, sección 16).

---

## Permanencia

El color verde permanece mientras el pedido tenga items recién agregados que aún no han sido preparados.

Aplica en cualquier estado activo (PENDING, PREPARING).

No depende del estado UPDATED (deprecado en ETAPA 4.5.6.1 — ver sección 13).

---

## Eliminación

El color verde desaparece cuando el pedido pasa a READY:

isNew = false (limpiado en la misma transacción que el cambio de estado)

---

# 19. Seguridad

Todos los endpoints deben validar:

- JWT
- Ownership
- Multi-tenant
- Roles

---

## Un mesero no puede

- Cambiar estados
- Ver pedidos ajenos
- Ver información de otra taquería

---

## Un cocinero no puede

- Acceder a otra taquería

---

# 20. Realtime — Reglas de Conexión WebSocket

## Autenticación WebSocket

El token JWT utilizado en REST es el mismo que se usa en WebSocket.

El token debe enviarse en el handshake:

```txt
socket.handshake.auth.token = "<jwt>"
```

O bien:

```txt
Authorization: Bearer <jwt>
```

JWT inválido o ausente → conexión rechazada.

---

## Rooms Multi-Tenant

Cada taquería tiene su propia room:

```txt
taqueria:<taqueriaId>
```

Reglas:

- Todos los usuarios de la misma taquería comparten room.
- Un usuario nunca puede unirse a la room de otra taquería.
- El `taqueriaId` de la room proviene exclusivamente del JWT (nunca del cliente).

---

## Aislamiento de Eventos

Los eventos de negocio se emiten únicamente a la room de la taquería correspondiente.

Un cocinero o mesero solo recibe eventos de su propia taquería.

---

## Eventos Disponibles

- `connection` — validación JWT + join room automático
- `disconnect` — limpieza de conexión
- `join-taqueria` — confirmación de room activa
- `order-created` — orden nueva creada (emitido tras POST /orders)
- `order-updated` — orden actualizada con Append Only (emitido tras PATCH /orders/:id)
- `order-status-changed` — estado de orden cambiado (emitido tras PATCH /orders/:id/status)

---

# 21. Reglas de Sincronización Realtime

## Persistencia antes de Emisión

El orden es invariante:

```txt
1. Guardar en PostgreSQL
2. Confirmar persistencia
3. Emitir evento WebSocket
```

Nunca emitir antes de confirmar que la BD tiene el dato.

## Propagación de Cambios

Cuando un WAITER crea un pedido:

- El pedido se persiste en BD.
- `order-created` se emite a toda la room de la taquería.
- Cocina y meseros conectados reciben el evento inmediatamente.

Cuando un WAITER actualiza un pedido (Append Only):

- Los nuevos plates/items se persisten en BD.
- El status cambia según las reglas de modificación (ver sección 16): PENDING permanece PENDING, PREPARING permanece PREPARING, READY revierte a PENDING.
- La revisión se incrementa.
- Los nuevos items tienen `isNew: true`.
- El mecanismo de seguimiento de cambios se activa (ver sección 16a).
- `order-updated` se emite a toda la room de la taquería.

Cuando un COOK cambia el estado:

- El nuevo status se persiste en BD.
- Si el nuevo status es `READY`, todos los `isNew: true` se limpian en la misma transacción antes de emitir.
- `order-status-changed` se emite a toda la room de la taquería.

## Sincronización Cocina

El COOK recibe en tiempo real:

- Nuevas órdenes creadas por cualquier mesero de la taquería.
- Órdenes actualizadas (items nuevos en highlight verde via `isNew`).
- Confirmación de sus propios cambios de estado.

## Sincronización Meseros

El WAITER recibe en tiempo real:

- Cambios de estado de sus propias órdenes (el COOK las actualiza).
- Actualizaciones de otros meseros de la misma taquería.

## Receptor de Eventos

Todos los usuarios conectados a la room de la taquería reciben todos los eventos.

El backend **no filtra por rol** — el frontend decide qué hacer con cada evento.

## Payload Completo

Todos los eventos emiten la orden completa con plates e items.

El frontend puede actualizar su estado local sin realizar llamadas REST adicionales.

## Fallo de Emisión

Si Socket.IO falla al emitir un evento:

- La transacción de BD **no se revierte**.
- La respuesta REST al cliente es exitosa.
- El error se registra en Logger.

La persistencia en BD tiene prioridad absoluta sobre la emisión WebSocket.

---

# 22. Order Classification — OrderType

Nuevo enum que clasifica el tipo de pedido según su modalidad de consumo.

Valores:

```txt
DINE_IN
TAKEAWAY
DELIVERY
```

OrderType es completamente independiente de OrderStatus.

OrderStatus representa la etapa de preparación de cocina.

OrderType representa la modalidad de consumo del pedido.

---

# 23. Reglas de Validación por OrderType

## DINE_IN

reference: obligatorio.

Representa el identificador visual de la mesa o zona.

Ejemplos válidos:

- Mesa 4
- Terraza 2
- Barra 3
- Mesa VIP

deliveryAddress: no aplica.

---

## TAKEAWAY

reference: obligatorio.

Representa el nombre de la persona que recogerá el pedido.

Ejemplos válidos:

- Roberto
- Juan Pérez
- María

deliveryAddress: no aplica.

---

## DELIVERY

deliveryAddress: obligatoria.

Ejemplos válidos:

- Av. Juárez #123
- Calle Hidalgo #45, Col. Centro

reference: opcional (nombre del cliente que recibe el pedido).

---

# 24. Evolución del campo tableNumber

El campo `tableNumber` se reemplaza conceptualmente por:

```txt
reference: string | null
```

Representa el identificador visual utilizado por el personal para localizar el pedido.

Se agrega además:

```txt
deliveryAddress: string | null
```

Campo exclusivo para pedidos DELIVERY.

---

# 25. Visualización en Kitchen por OrderType

La cocina identifica el tipo de pedido visualmente mediante emoji + referencia.

Sin texto adicional ni etiquetas redundantes.

```txt
DINE_IN   →  🍽 Mesa 4
TAKEAWAY  →  🥡 Roberto

DELIVERY (con reference):
  🛵 Roberto - Enviar

DELIVERY (sin reference):
  🛵 Av. Juárez #123...   (truncado si el texto es largo)
```

El emoji identifica la modalidad a distancia.

Kitchen NO agrupa por tipo. Los pedidos permanecen mezclados en la misma cola.

Se mantienen el FIFO y la priorización de estados existentes sin cambios.

---

# 26. READY — Significado unificado para todos los OrderType

READY mantiene exactamente el mismo significado independientemente del tipo de pedido.

Significa:

"Pedido completamente preparado y listo para ser entregado."

- DINE_IN → mesero puede llevarlo a la mesa.
- TAKEAWAY → cliente puede recogerlo.
- DELIVERY → repartidor puede salir a entregarlo.

No se agregan estados adicionales por tipo en la ETAPA 4.6.

---

# 27. Alcance MVP — DELIVERY

Los pedidos DELIVERY son capturados exclusivamente por personal interno.

Flujo:

```txt
Cliente llama al restaurante
      ↓
Mesero captura el pedido en el sistema
      ↓
Sistema registra pedido DELIVERY con deliveryAddress
```

No existe en ETAPA 4.6:

- Integración con clientes externos
- Portal web
- QR Ordering
- Self-ordering
- App de repartidores

Estas funcionalidades podrán evaluarse en etapas posteriores a producción.

---

# 28. Edición del tipo de pedido

El mesero puede cambiar el tipo de un pedido existente:

```txt
DINE_IN ↔ TAKEAWAY ↔ DELIVERY
```

Validaciones correspondientes al nuevo tipo seleccionado se aplican al momento de editar.

Implementado en ETAPA 4.6.2.

---

# 29. Visualización de dirección DELIVERY para meseros

Cuando un mesero abre un pedido de tipo DELIVERY para editarlo:

La dirección completa (`deliveryAddress`) se muestra dentro del flujo de edición actual.

No se requiere pantalla adicional para ver la dirección.

Implementado en ETAPA 4.6.2.

---

# 30. Migración de datos existentes — tableNumber → reference

Todos los pedidos existentes antes de ETAPA 4.6.1 deben migrarse automáticamente:

```txt
tableNumber → reference
tipo implícito → orderType = DINE_IN
```

La migración ocurre en la misma operación de Prisma que agrega los nuevos campos.

No se pierde información histórica.

No se requiere intervención manual.

---

# 31. Visibilidad de Pedidos — Filtro Activo

## Problema

Un pedido creado a las 23:55 con status PENDING desaparece automáticamente a las 00:00 si el filtro utilizado es "Hoy" (`today`), ya que ese filtro excluye pedidos cuyo `createdAt` sea anterior al inicio del día actual.

Esto genera una experiencia incorrecta para meseros, cocina y operación nocturna.

---

## Filtro Activo (`active`)

El filtro `active` representa pedidos activos del negocio.

Un pedido es activo cuando su status **NO** es:

- DELIVERED
- CANCELLED

Por lo tanto deben permanecer visibles bajo el filtro `active`:

- PENDING
- PREPARING
- READY

Sin importar cuándo fueron creados.

---

## Casos de uso

Pedido creado ayer a las 23:55 con status PENDING:

- Resultado: visible hoy en el filtro `active`.

Pedido READY creado ayer:

- Resultado: visible hoy en el filtro `active`.

Pedido DELIVERED:

- Resultado: no aparece en `active`.

Pedido CANCELLED:

- Resultado: no aparece en `active`.

---

## Filtros históricos

Los filtros `today`, `7d`, `1m`, `3m` filtran por `createdAt`.

Son útiles para consultas históricas, no para operación en tiempo real.

---

## Filtro por defecto

El filtro por defecto en `WaiterOrdersScreen` y `KitchenScreen` es `active`.

---

# 32. Principios Arquitectónicos

Mantener siempre:

- NestJS modular
- PrismaService Singleton
- DTOs tipados
- ValidationPipe
- TypeScript estricto
- Sin any
- Ownership centralizado
- Arquitectura multi-tenant
- Seguridad por roles
- Source of Truth en Backend

---

# Fin del Documento