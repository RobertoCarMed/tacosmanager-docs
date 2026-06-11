# language: es
Característica: Sincronización en tiempo real

  @REQ-0050
  Escenario: Conexión sin JWT es rechazada
    Cuando un cliente intenta conectar a Socket.IO sin auth.token
    Entonces la conexión es rechazada

  @REQ-0050
  Escenario: Conexión con JWT inválido es rechazada
    Cuando un cliente conecta con auth.token="invalid"
    Entonces la conexión es rechazada

  @REQ-0051
  Escenario: Auto-join al room de la taquería
    Dado un usuario con JWT válido de "TM-0001"
    Cuando conecta exitosamente a Socket.IO
    Entonces queda unido al room "taqueria:<id-de-TM-0001>"

  @REQ-0052
  Escenario: Aislamiento entre rooms
    Dado un user A de "TM-0001" conectado
    Y un user B de "TM-0002" conectado
    Cuando A dispara un evento que emite al room "TM-0001"
    Entonces B NO recibe ese evento

  @REQ-0053
  Escenario: Resync tras reconexión
    Dado un COOK conectado que pierde Wi-Fi 30s
    Cuando reconecta
    Entonces solicita GET /orders al backend
    Y la UI queda consistente con el estado del servidor

  @REQ-0054
  Escenario: Multi-device del mismo usuario
    Dado un COOK conectado en dispositivo A y dispositivo B simultáneamente
    Cuando ocurre un order-created en su taquería
    Entonces ambos dispositivos reciben el evento
