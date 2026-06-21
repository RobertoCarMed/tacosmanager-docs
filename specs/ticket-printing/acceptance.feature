# language: es
Característica: Impresión de cuenta (ticket) de pedidos

  Antecedentes:
    Dado un WAITER autenticado de la taquería "TM-0001"
    Y una impresora POS-8370 configurada para el dispositivo

  # --- Prerrequisito de precios (snapshot) ---

  @REQ-0070
  Escenario: POST /orders congela unitPrice por item
    Dado un producto "Coca" con price=20
    Cuando el WAITER crea una orden con 5 unidades de "Coca"
    Entonces cada item persistido tiene unitPrice=20
    Y el unitPrice aparece en el payload de la orden

  @REQ-0071
  Escenario: Append congela unitPrice en items nuevos
    Dado una orden existente
    Cuando el WAITER agrega un item de un producto con price=35
    Entonces el item nuevo tiene unitPrice=35
    Y los items previos conservan su unitPrice original

  @REQ-0072
  Escenario: unitPrice no cambia si cambia el catálogo
    Dado una orden con un item de "Coca" con unitPrice=20
    Cuando luego el COOK cambia el price de "Coca" a 25
    Entonces el item de esa orden sigue con unitPrice=20

  @REQ-0073
  Escenario: Migración backfill best-effort de unitPrice
    Dado items creados antes de la feature sin unitPrice
    Cuando se ejecuta la migración
    Entonces cada item recibe unitPrice = price actual de su producto
    Y si el producto fue borrado, el item queda con unitPrice null

  # --- Impresión de la cuenta ---

  @REQ-0074
  Escenario: WAITER imprime la cuenta de un pedido completado
    Dado un pedido propio en status READY o DELIVERED
    Cuando el WAITER toca "Imprimir ticket"
    Entonces la cuenta se genera y se envía a la impresora
    Y el botón no está disponible en PENDING, PREPARING ni CANCELLED

  @REQ-0075
  Escenario: Solo el WAITER dueño imprime
    Cuando un COOK ve el pedido
    Entonces no se ofrece imprimir cuenta
    Y un WAITER que no es el dueño tampoco puede imprimir

  @REQ-0076
  Escenario: Contenido de la cuenta
    Dado un pedido con varios items
    Cuando se genera el ticket
    Entonces incluye taquería y restaurantCode, tipo y referencia, fecha y hora
    Y una línea por item con cantidad, producto, unitPrice y subtotal
    Y el total del pedido

  @REQ-0077
  Escenario: Total es la suma de subtotales sobre precios congelados
    Dado un pedido con 5 "Coca" a unitPrice=20 y 2 "Taco" a unitPrice=15
    Cuando se genera el ticket
    Entonces los subtotales son 100 y 30
    Y el total es 130
    Y el frontend lo calcula sobre los unitPrice congelados, sin leer el catálogo

  @REQ-0078
  Escenario: Sin unitPrice completo no se emite la cuenta
    Dado un pedido legacy con un item sin unitPrice
    Cuando el WAITER intenta imprimir
    Entonces la impresión se bloquea
    Y se informa que faltan precios para emitir la cuenta

  @REQ-0079
  Escenario: Fallo de impresión no altera el pedido
    Dado un pedido imprimible
    Cuando la impresora no responde
    Entonces se muestra un error y se ofrece reintentar
    Y el status, revision e items del pedido no cambian

  @REQ-0080
  Escenario: Configuración de impresora LAN requerida y persistida
    Dado que no hay impresora configurada en el dispositivo
    Cuando el WAITER intenta imprimir
    Entonces se le pide configurar host IP y puerto (default 9100)
    Y la configuración se persiste para siguientes impresiones
    Y un host inalcanzable produce un error claro
