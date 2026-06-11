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

  @REQ-0044
  Escenario: FIFO dentro del mismo status
    Dado 3 órdenes en PENDING creadas en 10:00, 10:05, 10:10
    Cuando se hace GET /orders
    Entonces las PENDING aparecen en orden 10:00 → 10:05 → 10:10

  @REQ-0045
  Escenario: Cambio de status emite order-status-changed
    Dado un COOK conectado a Socket.IO
    Cuando otro COOK cambia el status de una orden
    Entonces el primer COOK recibe "order-status-changed" con la orden actualizada

  @REQ-0046
  Escenario: WAITER no puede cambiar status
    Cuando un WAITER hace PATCH /orders/<id>/status
    Entonces la respuesta es 403
