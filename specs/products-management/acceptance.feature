# language: es
Característica: Gestión de productos

  @REQ-0010
  Escenario: COOK lista productos de su taquería
    Dado un COOK autenticado de "TM-0001" con 3 productos en su catálogo
    Cuando hace GET /products
    Entonces recibe 200 con 3 productos, todos con taqueriaId de "TM-0001"

  @REQ-0011
  Escenario: WAITER lista productos
    Dado un WAITER autenticado de "TM-0001"
    Cuando hace GET /products
    Entonces recibe 200 con la lista completa del catálogo de "TM-0001"

  @REQ-0012
  Escenario: WAITER no puede crear productos
    Dado un WAITER autenticado
    Cuando hace POST /products con datos válidos
    Entonces la respuesta es 403

  @REQ-0013
  Escenario: WAITER no puede editar productos
    Cuando un WAITER hace PATCH /products/<id>
    Entonces la respuesta es 403

  @REQ-0014
  Escenario: WAITER no puede eliminar productos
    Cuando un WAITER hace DELETE /products/<id>
    Entonces la respuesta es 403

  @REQ-0015
  Escenario: Aislamiento entre taquerías
    Dado un producto P de taquería "TM-0002"
    Y un usuario autenticado de "TM-0001"
    Cuando intenta GET /products/<id-de-P>
    Entonces la respuesta es 404
