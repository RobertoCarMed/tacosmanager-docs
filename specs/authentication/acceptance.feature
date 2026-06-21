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

  # DEPRECADO (spec 2.0): sucesor @REQ-0059.
  @REQ-0004
  Escenario: Smart register crea taquería nueva (histórico)
    Dado que no existe taquería con nombre "Taquería El Güero" en "Av. Reforma"
    Cuando se hace POST /auth/register con datos de usuario y de taquería
    Entonces se crea una taquería nueva con restaurantCode autogenerado
    Y se crea el usuario asociado a esa taquería
    Y la respuesta incluye accessToken

  # DEPRECADO (spec 2.0): sucesor @REQ-0058.
  @REQ-0005
  Escenario: Smart register une a taquería existente (histórico)
    Dado que existe una taquería "TM-0001" coincidente
    Cuando un usuario nuevo hace POST /auth/register apuntando a esa taquería
    Entonces el usuario se asocia a "TM-0001"
    Y NO se crea una taquería adicional

  @REQ-0055
  Escenario: Discovery con 0 coincidencias
    Dado un usuario nuevo con taqueriaName "Taqueria Nueva"
    Y no existe ninguna taquería con ese nombre exacto
    Cuando hace POST /auth/register con el body base sin flags de confirmación
    Entonces la respuesta es 201
    Y el cuerpo incluye taqueriaMatches=0
    Y el cuerpo incluye canCreateNewTaqueria=true y requiresTaqueriaInfo=true
    Y no se crea ningún usuario ni ninguna taquería

  @REQ-0056
  Escenario: Discovery con 1 coincidencia
    Dado un usuario nuevo con taqueriaName "Taqueria El Guero"
    Y existe exactamente una taquería con ese nombre exacto
    Cuando hace POST /auth/register con el body base sin flags de confirmación
    Entonces la respuesta es 201
    Y el cuerpo incluye taqueriaMatches=1
    Y el cuerpo incluye canJoinExistingTaqueria=true y canCreateNewTaqueria=true
    Y la lista taquerias contiene id, name y restaurantCode
    Y no se crea ningún usuario ni ninguna taquería

  @REQ-0057
  Escenario: Discovery con múltiples coincidencias
    Dado un usuario nuevo con taqueriaName "Taqueria El Guero"
    Y existen múltiples taquerías con ese nombre exacto
    Cuando hace POST /auth/register con el body base sin flags de confirmación
    Entonces la respuesta es 201
    Y el cuerpo incluye taqueriaMatches mayor a 1
    Y la lista taquerias contiene cada coincidencia con id, name y restaurantCode

  @REQ-0058
  Escenario: Join confirmado por selectedRestaurantCode
    Dado un usuario nuevo con taqueriaName "Taqueria El Guero"
    Y confirmJoinExistingTaqueria=true
    Y selectedRestaurantCode="TM-4821"
    Cuando hace POST /auth/register
    Entonces la respuesta es 201
    Y se crea el usuario asociado a la taquería de restaurantCode "TM-4821"
    Y no se crea ninguna taquería nueva
    Y la respuesta incluye accessToken, user y taqueria

  @REQ-0059
  Escenario: Create confirmado con taqueriaData
    Dado un usuario nuevo con taqueriaName "Taqueria El Guero"
    Y createNewTaqueria=true
    Y taqueriaData como objeto
    Cuando hace POST /auth/register
    Entonces la respuesta es 201
    Y se crea una nueva taquería con restaurantCode autogenerado
    Y se crea el usuario asociado a esa nueva taquería
    Y la respuesta incluye accessToken, user y taqueria

  @REQ-0060
  Escenario: Email duplicado falla antes del discovery
    Dado que ya existe un usuario con email "ana@example.com"
    Cuando alguien hace POST /auth/register con ese email
    Entonces la respuesta es 409
    Y el mensaje es "Email already exists"

  @REQ-0061
  Escenario: Combinaciones inválidas de flags fallan con 400
    Dado un body base válido para POST /auth/register
    Cuando confirmJoinExistingTaqueria=true y createNewTaqueria=true
    Entonces la respuesta es 400
    Y no se crea ningún usuario ni ninguna taquería

  @REQ-0061
  Escenario: Join confirmado sin selectedRestaurantCode falla con 400
    Dado un body base válido para POST /auth/register
    Y confirmJoinExistingTaqueria=true
    Cuando no se envía selectedRestaurantCode
    Entonces la respuesta es 400
    Y no se crea ningún usuario ni ninguna taquería

  @REQ-0061
  Escenario: Create confirmado sin taqueriaData falla con 400
    Dado un body base válido para POST /auth/register
    Y createNewTaqueria=true
    Cuando no se envía taqueriaData
    Entonces la respuesta es 400
    Y no se crea ningún usuario ni ninguna taquería
