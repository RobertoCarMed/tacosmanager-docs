# Spec: Authentication

- ID: SPEC-authentication
- Versión: 1.0
- Estado: Implementada
- Fecha: 2026-06-11
- ETAPA asociada: 4.5.1

## 1. Problema / Oportunidad

Los usuarios (COOK, WAITER) necesitan autenticarse para usar la app. El sistema debe ser stateless, compatible con HTTP REST y con el handshake de Socket.IO, y soportar Session Restore al reabrir la app.

## 2. Objetivos

- Login por email + password que retorna JWT.
- Smart register: crea taquería o une a una existente.
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

- US-1: Como usuario nuevo quiero registrarme y que el sistema decida si crea una taquería o me une a una existente.
- US-2: Como usuario existente quiero loguearme con email+password y obtener un token persistente.
- US-3: Como usuario que reabre la app quiero recuperar mi sesión automáticamente si el token sigue vigente.

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

### REQ-0004 — Smart register crea taquería si no existe

```gherkin
Dado que no existe taquería con nombre+dirección coincidentes
Cuando un usuario hace POST /auth/register con sus datos + datos de taquería
Entonces se crea una taquería nueva con restaurantCode autogenerado
Y se crea el usuario asociado
Y se retorna accessToken válido
```

### REQ-0005 — Smart register une usuario a taquería existente

```gherkin
Dado que existe una taquería con coincidencia
Cuando un usuario nuevo hace POST /auth/register apuntando a esa taquería
Entonces el usuario se asocia a la taquería existente
Y NO se crea una taquería nueva
```

## 7. Edge Cases

- Email duplicado en register → 409.
- Password < N caracteres → 400.
- Token con `taqueriaId` que ya no existe → 401.

## 8. Requerimientos no funcionales

- **Seguridad:** bcrypt para hashes. Constitución Artículo IX (no exponer hashes).
- **Performance:** p95 login < 200ms.
- **Multi-tenancy:** el JWT lleva `taqueriaId` y `role`, usado por TODOS los guards.

## 9. Dependencias

- ADR-0002 (JWT)
- Contrato: `contracts/openapi.yaml#/paths/~1auth~1login`

## 10. Riesgos / Preguntas abiertas

- ❓ Política de password (longitud mínima, complejidad). Hoy: 6 caracteres. Spec futura.

## 11. Referencias

- `backend-api.md` — Autenticación
- `feature-list.md` — Authentication System
