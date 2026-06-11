# language: es
Característica: Autenticación de usuario

  @REQ-0001
  Escenario: Login válido
    Dado un usuario con email "ana@example.com" y password "secret123" en la taquería "TM-0001"
    Cuando hace POST /auth/login con esas credenciales
    Entonces la respuesta es 200
    Y el cuerpo incluye accessToken, user (sin password), taqueria (con restaurantCode)

  @REQ-0002
  Escenario: Login con credenciales inválidas
    Cuando alguien hace POST /auth/login con email "ana@example.com" y password incorrecto
    Entonces la respuesta es 401
    Y el mensaje de error es genérico (no revela cuál campo falló)

  @REQ-0003
  Escenario: GET /auth/me con token válido
    Dado un accessToken válido en Authorization Bearer
    Cuando se hace GET /auth/me
    Entonces la respuesta es 200 con user y taqueria

  @REQ-0003
  Escenario: GET /auth/me con token expirado
    Dado un accessToken expirado
    Cuando se hace GET /auth/me
    Entonces la respuesta es 401

  @REQ-0004
  Escenario: Smart register crea taquería nueva
    Dado que no existe taquería con nombre "Taquería El Güero" en "Av. Reforma"
    Cuando se hace POST /auth/register con datos de usuario y de taquería
    Entonces se crea una taquería nueva con restaurantCode autogenerado
    Y se crea el usuario asociado a esa taquería
    Y la respuesta incluye accessToken

  @REQ-0005
  Escenario: Smart register une a taquería existente
    Dado que existe una taquería "TM-0001" coincidente
    Cuando un usuario nuevo hace POST /auth/register apuntando a esa taquería
    Entonces el usuario se asocia a "TM-0001"
    Y NO se crea una taquería adicional
