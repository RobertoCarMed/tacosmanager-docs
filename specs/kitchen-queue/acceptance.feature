# language: es
Característica: Kitchen Queue (cola de cocina)

  @REQ-0040
  Escenario: COOK cambia status a PREPARING
    Dado un COOK autenticado de "TM-0001"
    Y una orden O en "PENDING"
    Cuando hace PATCH /orders/<id-de-O>/status con status="PREPARING"
    Entonces la orden queda en "PREPARING"

  @REQ-0041
  Escenario: UPDATED es rechazado
    Cuando un COOK hace PATCH /orders/<id>/status con status="UPDATED"
    Entonces la respuesta es 400
    Y la orden mantiene su status previo

  @REQ-0042
  Escenario: Transición a READY limpia isNew
    Dado una orden con 3 items, 2 de ellos con isNew=true
    Cuando un COOK cambia el status a "READY"
    Entonces los 3 items quedan con isNew=false

  @REQ-0043
  Escenario: Ordenamiento global por status
    Dado órdenes con status PREPARING, PENDING, READY, DELIVERED, CANCELLED
    Cuando un COOK hace GET /orders
    Entonces el orden devuelto es: PREPARING > PENDING > READY > DELIVERED > CANCELLED

  # DEPRECADO (spec 2.0, ADR-0010): sucesor @REQ-0047. Se conserva como regresión histórica.
  @REQ-0044
  Escenario: FIFO dentro del mismo status (por createdAt — histórico)
    Dado 3 órdenes en PENDING creadas en 10:00, 10:05, 10:10
    Cuando se hace GET /orders
    Entonces las PENDING aparecen en orden 10:00 → 10:05 → 10:10

  @REQ-0047
  Escenario: FIFO dentro del mismo status por priorityTimestamp
    Dado 3 órdenes en PENDING con priorityTimestamp 10:00, 10:05, 10:10
    Cuando se hace GET /orders
    Entonces las PENDING aparecen en orden 10:00 → 10:05 → 10:10

  @REQ-0047
  Escenario: append en PENDING conserva posición; append en PREPARING reprioriza
    Dado una orden A en PENDING con priorityTimestamp 10:00 y una orden B en PENDING con 10:05
    Cuando el WAITER hace append a la orden A estando en PENDING
    Entonces priorityTimestamp de A sigue siendo 10:00
    Y la cola sigue siendo A, B
    Pero si A estuviera en PREPARING al hacer el append
    Entonces priorityTimestamp de A se actualiza a la hora del append

  @REQ-0045
  Escenario: Cambio de status emite order-status-changed
    Dado un COOK conectado a Socket.IO
    Cuando otro COOK cambia el status de una orden
    Entonces el primer COOK recibe "order-status-changed" con la orden actualizada

  @REQ-0046
  Escenario: WAITER no puede cambiar status
    Cuando un WAITER hace PATCH /orders/<id>/status
    Entonces la respuesta es 403
