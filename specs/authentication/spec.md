# Spec: Authentication

- ID: SPEC-authentication
- Versión: 2.0
- Estado: Implementada
- Fecha: 2026-06-20
- ETAPA asociada: 4.5.1

> **Changelog 2.0 (2026-06-20):** se alinea la spec con la implementacion real del
> backend para `POST /auth/register`. El registro deja de documentarse como
> auto-decision del sistema y pasa a modelarse como flujo de 2 fases en un solo
> endpoint: discovery sin side effects y confirmacion explicita del cliente para
> `join` o `create`. `REQ-0004` y `REQ-0005` quedan deprecados; sus sucesores son
> `REQ-0058` y `REQ-0059`. Se agregan `REQ-0055` a `REQ-0061`. Breaking -> bump
> MAJOR (ADR-0009).

## 1. Problema / Oportunidad

Los usuarios (COOK, WAITER) necesitan autenticarse para usar la app. El sistema
debe ser stateless, compatible con HTTP REST y con el handshake de Socket.IO, y
soportar Session Restore al reabrir la app.

Ademas, el registro implementado hoy no es auto-resolutivo: el backend expone un
solo `POST /auth/register` que primero explora coincidencias por nombre exacto de
taqueria y luego espera una decision explicita del cliente para unirse a una
taqueria existente o crear una nueva.

## 2. Objetivos

- Login por email + password que retorna JWT.
- Smart register en 2 fases usando el mismo endpoint `POST /auth/register`.
- Discovery sin side effects para detectar 0, 1 o N coincidencias por `taqueriaName`.
- Confirmacion explicita del cliente para:
  - unirse a una taqueria existente por `selectedRestaurantCode`
  - crear una nueva taqueria con `taqueriaData`
- Session restore vía `GET /auth/me`.
- Mismo JWT para REST y Socket.IO.

## 3. No-objetivos

- OAuth/social login.
- Refresh tokens (ver ADR-0002).
- Reset de password vía email (futuro).
- MFA.

## 4. Actores

- Usuario nuevo (registro).
- COOK / WAITER existente (login, session restore).

## 5. User Stories

- US-1: Como usuario nuevo quiero buscar coincidencias por nombre de taqueria
  antes de registrarme para decidir si me uno a una existente o creo una nueva.
- US-2: Como usuario nuevo quiero unirme explicitamente a una taqueria existente
  usando su `restaurantCode`.
- US-3: Como usuario nuevo quiero crear una nueva taqueria aunque existan otras
  con el mismo nombre.
- US-4: Como usuario existente quiero loguearme con email+password y obtener un token persistente.
- US-5: Como usuario que reabre la app quiero recuperar mi sesión automaticamente si el token sigue vigente.

## 6. Acceptance Criteria (Gherkin)

### REQ-0001 — Login válido devuelve accessToken + user + taqueria

```gherkin
Dado un usuario con email "ana@example.com" y password "secret123" en la taquería "TM-0001"
Cuando hace POST /auth/login con esas credenciales
Entonces la respuesta es 200
Y el cuerpo incluye accessToken (JWT válido, expira en 24h), user (sin password), taqueria (con restaurantCode)
```

### REQ-0002 — Login con credenciales inválidas devuelve 401

```gherkin
Cuando alguien hace POST /auth/login con email o password incorrectos
Entonces la respuesta es 401
Y no se filtra información que indique cuál de los dos campos falló
```

### REQ-0003 — GET /auth/me valida token y retorna contexto

```gherkin
Dado un accessToken válido
Cuando se hace GET /auth/me con header Authorization Bearer
Entonces la respuesta es 200 con user y taqueria
Y un token expirado/inválido devuelve 401
```

### REQ-0004 — Smart register crea taquería si no existe `[🗑️ DEPRECADO — sucesor REQ-0059]`

> Deprecado en spec 2.0. Documentaba una decision automatica del backend para crear
> taqueria cuando no habia coincidencias. La implementacion real hace discovery en
> fase 1 y requiere confirmacion explicita del cliente para crear en fase 2.

```gherkin
Dado que no existe taquería con nombre+dirección coincidentes
Cuando un usuario hace POST /auth/register con sus datos + datos de taquería
Entonces se crea una taquería nueva con restaurantCode autogenerado
Y se crea el usuario asociado
Y se retorna accessToken válido
```

### REQ-0005 — Smart register une usuario a taquería existente `[🗑️ DEPRECADO — sucesor REQ-0058]`

> Deprecado en spec 2.0. Documentaba una decision automatica del backend para unir
> al usuario a una taqueria existente. La implementacion real requiere
> `confirmJoinExistingTaqueria=true` y `selectedRestaurantCode`.

```gherkin
Dado que existe una taquería con coincidencia
Cuando un usuario nuevo hace POST /auth/register apuntando a esa taquería
Entonces el usuario se asocia a la taquería existente
Y NO se crea una taquería nueva
```

### REQ-0055 — Register discovery con 0 coincidencias no crea recursos

```gherkin
Dado un usuario nuevo con `taqueriaName="Taqueria Nueva"`
Y que no existe ninguna taqueria con ese nombre exacto
Cuando hace POST /auth/register con `taqueriaName`, `name`, `email`, `password` y `role`
Entonces la respuesta es 201
Y el cuerpo incluye `taqueriaMatches=0`, `canCreateNewTaqueria=true` y `requiresTaqueriaInfo=true`
Y NO se crea ningun usuario
Y NO se crea ninguna taqueria
```

### REQ-0056 — Register discovery con 1 coincidencia devuelve la taqueria encontrada

```gherkin
Dado un usuario nuevo con `taqueriaName="Taqueria El Guero"`
Y que existe exactamente una taqueria con ese nombre exacto
Cuando hace POST /auth/register sin flags de confirmacion
Entonces la respuesta es 201
Y el cuerpo incluye `taqueriaMatches=1`
Y el cuerpo incluye `canJoinExistingTaqueria=true` y `canCreateNewTaqueria=true`
Y la lista `taquerias` contiene `id`, `name` y `restaurantCode`
Y NO se crea ningun usuario ni ninguna taqueria
```

### REQ-0057 — Register discovery con multiples coincidencias devuelve lista por restaurantCode

```gherkin
Dado un usuario nuevo con `taqueriaName="Taqueria El Guero"`
Y que existen multiples taquerias con ese nombre exacto
Cuando hace POST /auth/register sin flags de confirmacion
Entonces la respuesta es 201
Y el cuerpo incluye `taqueriaMatches > 1`
Y la lista `taquerias` contiene cada coincidencia con `id`, `name` y `restaurantCode`
Y el cliente puede decidir unirse a una existente o crear una nueva
```

### REQ-0058 — Register une a taqueria existente con confirmacion explicita

```gherkin
Dado un usuario nuevo con `taqueriaName="Taqueria El Guero"`
Y `confirmJoinExistingTaqueria=true`
Y `selectedRestaurantCode="TM-4821"`
Cuando hace POST /auth/register
Entonces la respuesta es 201
Y se crea el usuario asociado a la taqueria de `selectedRestaurantCode`
Y NO se crea una taqueria nueva
Y el cuerpo incluye `accessToken`, `user` y `taqueria`
```

### REQ-0059 — Register crea nueva taqueria con confirmacion explicita

```gherkin
Dado un usuario nuevo con `taqueriaName="Taqueria El Guero"`
Y `createNewTaqueria=true`
Y `taqueriaData` como objeto
Cuando hace POST /auth/register
Entonces la respuesta es 201
Y se crea una taqueria nueva con `restaurantCode` autogenerado
Y se crea el usuario asociado a esa nueva taqueria
Y el cuerpo incluye `accessToken`, `user` y `taqueria`
```

### REQ-0060 — Register con email duplicado devuelve 409 antes del discovery

```gherkin
Dado que ya existe un usuario con `email="ana@example.com"`
Cuando alguien hace POST /auth/register con ese email
Entonces la respuesta es 409
Y el mensaje es `Email already exists`
Y NO se ejecuta ninguna busqueda de taquerias ni se crean recursos
```

### REQ-0061 — Register rechaza combinaciones invalidas de flags con 400

```gherkin
Dado un body base valido para POST /auth/register
Cuando `confirmJoinExistingTaqueria=true` y `createNewTaqueria=true`
O cuando falta `selectedRestaurantCode` en join confirmado
O cuando falta `taqueriaData` en create confirmado
Entonces la respuesta es 400
Y NO se crea ningun usuario ni ninguna taqueria
```

## 7. Edge Cases

- Email duplicado en register → 409.
- Password < N caracteres → 400.
- `selectedRestaurantCode` se resuelve globalmente por `restaurantCode`; no se cruza con `taqueriaName`.
- `selectedRestaurantCode` o `taqueriaData` enviados sin flags de confirmacion son ignorados en discovery.
- `confirmJoinExistingTaqueria=true` + `taqueriaData` → 400.
- `createNewTaqueria=true` + `selectedRestaurantCode` → 400.
- Token con `taqueriaId` que ya no existe → 401.

## 8. Requerimientos no funcionales

- **Seguridad:** bcrypt para hashes. Constitución Artículo IX (no exponer hashes).
- **Performance:** p95 login < 200ms.
- **Multi-tenancy:** el JWT lleva `taqueriaId` y `role`, usado por TODOS los guards.
- **Validacion:** `ValidationPipe` global con `whitelist`, `forbidNonWhitelisted` y `transform`.

## 9. Dependencias

- ADR-0002 (JWT)
- Contratos: `contracts/openapi.yaml#/paths/~1auth~1login`, `contracts/openapi.yaml#/paths/~1auth~1register`

## 10. Riesgos / Preguntas abiertas

- ❓ Política de password (longitud mínima, complejidad). Hoy: 6 caracteres. Spec futura.
- ❓ El backend permite `join` por `selectedRestaurantCode` aunque el discovery previo haya devuelto 0 coincidencias para otro `taqueriaName`. Hoy esta permitido y documentado como comportamiento actual.

## 11. Referencias

- `backend-api.md` — Autenticación
- `ui-flows.md` — Register Flow
- `feature-list.md` — Authentication System
