# language: es
Característica: Filtros de visibilidad de órdenes

  Antecedentes:
    Dado un usuario autenticado (WAITER o COOK) de la taquería "TM-0001"
    Y una lista de pedidos ya cargada vía GET /orders y eventos realtime

  @REQ-0063
  Escenario: El filtro por defecto es "active"
    Cuando el usuario abre su pantalla de órdenes
    Entonces el filtro seleccionado es "active"
    Y las opciones son: Activos, Hoy, Últimos 7 días, Último mes, Últimos 3 meses

  @REQ-0064
  Escenario: "active" muestra status no terminal sin límite de fecha
    Dado pedidos con status PENDING, PREPARING, READY, DELIVERED y CANCELLED de distintas fechas
    Cuando el filtro es "active"
    Entonces se muestran solo los PENDING, PREPARING y READY
    Y no se aplica ningún límite por createdAt

  @REQ-0065
  Escenario: Un pedido activo de ayer no desaparece a medianoche
    Dado un pedido creado ayer a las 23:55 con status PENDING
    Cuando hoy se consulta con el filtro "active"
    Entonces el pedido sigue visible

  @REQ-0066
  Escenario: "today" usa la medianoche en hora local del dispositivo
    Cuando el filtro es "today"
    Entonces se muestran solo pedidos con createdAt >= medianoche de hoy en hora local
    Y se incluyen todos los statuses dentro de ese rango

  @REQ-0067
  Escenario: "7d", "1m", "3m" son ventanas móviles en hora local
    Cuando el filtro es "7d" (o "1m", o "3m")
    Entonces se muestran pedidos con createdAt >= (ahora − 7 días | 1 mes | 3 meses) en hora local
    Y la ventana es relativa al instante actual, no a límites de calendario

  @REQ-0068
  Escenario: Los filtros históricos incluyen DELIVERED y CANCELLED
    Dado pedidos DELIVERED y CANCELLED dentro del rango de fecha
    Cuando el filtro es "today", "7d", "1m" o "3m"
    Entonces esos pedidos DELIVERED y CANCELLED aparecen
    Y solo el filtro "active" los excluye

  @REQ-0069
  Escenario: El filtrado client-side preserva orden y aislamiento
    Dado que GET /orders ya entregó la lista ordenada por rol y aislada por taquería/ownership
    Cuando el frontend aplica cualquier filtro
    Entonces solo se ocultan filas localmente, sin reordenar ni recargar de red
    Y un WAITER nunca ve pedidos de otro mesero
    Y el orden relativo de los visibles se conserva
