# ADR-0002: JWT como mecanismo de autenticación

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

El frontend es una app React Native que opera en taquerías con conectividad variable. Necesitamos auth que:

1. No requiera estado de sesión server-side (stateless).
2. Funcione con HTTP REST y con el handshake de Socket.IO.
3. Sea simple de persistir en el dispositivo y restaurar al arranque.
4. Permita validar `taqueriaId` y `role` sin hit a DB en cada request.

## Decisión

Adoptamos **JWT firmado** emitido por el backend en `POST /auth/login`.

- Algoritmo: HS256 con secret en env.
- Expiración: 1 día.
- Claims: `userId`, `taqueriaId`, `role` (`COOK`|`WAITER`).
- Persistencia mobile: `AsyncStorage`.
- Validación en cada request HTTP vía `JwtAuthGuard` de NestJS.
- En Socket.IO: el token viaja en `auth.token` del handshake; rechazo automático si inválido.
- Endpoint `GET /auth/me` para validar el token al arranque del frontend (Session Restore).

No usamos refresh tokens en esta etapa — el usuario reingresa credenciales tras expiración.

## Alternativas consideradas

- **Sessions server-side con cookies** — requiere sticky sessions, complica scaling y mobile.
- **OAuth/OIDC con IdP externo** — overkill para early stage, complica onboarding offline-tolerant.
- **JWT + refresh token** — pospuesto hasta que la fricción de re-login sea problema medible.

## Consecuencias

Positivas:
- Stateless: cualquier instancia del backend valida sin hit a DB.
- Socket.IO y REST comparten el mismo token y guard.
- Session Restore trivial.

Negativas:
- Revocación inmediata no posible (token válido hasta expirar). Mitigado por expiración de 1 día.
- Rotación de secret invalida todas las sesiones — requiere coordinación.

Neutrales:
- Se podrá agregar refresh tokens sin romper compatibilidad (claim opcional).

## Referencias

- Constitución Artículo III — Ownership-Based Security
- `backend-api.md` — Autenticación
- ADR-0003 (Socket.IO usa este mismo JWT)
- REQ-0001, REQ-0002, REQ-0003, REQ-0050
