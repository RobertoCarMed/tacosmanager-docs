# language: es
Característica: Editar orden (append)

  Antecedentes:
    Dado un WAITER autenticado de "TM-0001"
    Y una orden existente O con 1 plate y 1 item en revision=1, status="PENDING"

  # DEPRECADO (spec 2.0): sucesor @REQ-0048. Se conserva como regresión histórica.
  @REQ-0030
  Escenario: Append agrega item nuevo al plate existente (histórico)
    Cuando el WAITER hace PATCH /orders/<id-de-O> agregando 1 item nuevo
    Entonces la respuesta es 200
    Y la orden tiene 2 items en el plate
    Y el item nuevo tiene createdInRevision=2 e isNew=true

  @REQ-0048
  Escenario: Append agrega un plate nuevo
    Cuando el WAITER hace PATCH /orders/<id-de-O> con un plate nuevo (plateNumber=2) con 1 item
    Entonces la respuesta es 200
    Y la orden tiene 2 plates
    Y el plate nuevo tiene createdInRevision=2 y su item isNew=true

  @REQ-0048
  Escenario: Append con plateNumber existente es rechazado
    Cuando el WAITER hace PATCH /orders/<id-de-O> con plateNumber=1 (ya existente)
    Entonces la respuesta es 400
    Y la orden no cambia (inmutabilidad a nivel plate)

  @REQ-0031
  Escenario: No se permite modificar items históricos
    Cuando el WAITER intenta PATCH cambiando quantity del item original
    Entonces el cambio no se aplica
    Y la quantity histórica permanece igual

  @REQ-0032
  Escenario: revision se incrementa en cada append
    Cuando ocurre un append válido
    Entonces revision pasa de 1 a 2

  @REQ-0033
  Escenario: Items nuevos llegan con isNew=true
    Cuando un append exitoso ocurre
    Entonces los items agregados tienen isNew=true
    Y los items previos mantienen su isNew anterior

  @REQ-0034
  Escenario: Append en READY transiciona a PENDING
    Dado una orden O con status="READY"
    Cuando el WAITER hace PATCH agregando un item
    Entonces O queda con status="PENDING"

  @REQ-0035
  Escenario: Append en PREPARING mantiene PREPARING
    Dado una orden O con status="PREPARING"
    Cuando el WAITER hace PATCH agregando un item
    Entonces O mantiene status="PREPARING"

  @REQ-0036
  Escenario: Append emite order-updated
    Dado un COOK de "TM-0001" conectado a Socket.IO
    Cuando ocurre el PATCH exitoso
    Entonces el COOK recibe "order-updated" con la orden completa
