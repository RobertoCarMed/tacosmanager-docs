# language: es
Característica: Crear orden (WAITER)

  Antecedentes:
    Dado un WAITER autenticado de la taquería "TM-0001"
    Y un producto "Taco al pastor" de la misma taquería

  @REQ-0020
  Escenario: WAITER crea orden DINE_IN con reference
    Cuando el WAITER hace POST /orders con:
      | type      | DINE_IN  |
      | reference | Mesa 4   |
    Y agrega 1 plate con 1 item del producto "Taco al pastor"
    Entonces la respuesta es 201
    Y la orden persistida tiene type="DINE_IN", reference="Mesa 4", deliveryAddress=null
    Y la orden tiene status="PENDING" y revision=1

  @REQ-0021
  Escenario: WAITER crea orden TAKEAWAY con reference
    Cuando el WAITER hace POST /orders con:
      | type      | TAKEAWAY |
      | reference | Roberto  |
    Y agrega 1 plate con 1 item
    Entonces la respuesta es 201
    Y la orden tiene type="TAKEAWAY", reference="Roberto", deliveryAddress=null

  @REQ-0022
  Escenario: WAITER crea orden DELIVERY con deliveryAddress
    Cuando el WAITER hace POST /orders con:
      | type            | DELIVERY         |
      | deliveryAddress | Av. Juárez #123  |
    Y agrega 1 plate con 1 item
    Entonces la respuesta es 201
    Y la orden tiene type="DELIVERY", deliveryAddress="Av. Juárez #123"

  @REQ-0023
  Escenario: DINE_IN sin reference falla
    Cuando el WAITER hace POST /orders con type="DINE_IN" sin reference
    Entonces la respuesta es 400
    Y el error menciona el campo "reference"
    Y no se crea ninguna orden

  @REQ-0024
  Escenario: DELIVERY sin deliveryAddress falla
    Cuando el WAITER hace POST /orders con type="DELIVERY" sin deliveryAddress
    Entonces la respuesta es 400
    Y el error menciona el campo "deliveryAddress"

  @REQ-0025
  Escenario: Orden creada arranca con revision=1 y status=PENDING
    Cuando el WAITER crea una orden válida
    Entonces la orden tiene revision=1, status="PENDING"
    Y priorityTimestamp=createdAt

  @REQ-0026
  Escenario: Crear orden emite order-created al room de la taquería
    Dado un COOK de la taquería "TM-0001" conectado a Socket.IO
    Y un COOK de la taquería "TM-0002" conectado a Socket.IO
    Cuando el WAITER de "TM-0001" crea una orden
    Entonces el COOK de "TM-0001" recibe el evento "order-created" con la orden completa
    Y el COOK de "TM-0002" NO recibe ningún evento

  @REQ-0027
  Escenario: COOK no puede crear órdenes
    Dado un COOK autenticado
    Cuando intenta POST /orders con datos válidos
    Entonces la respuesta es 403
