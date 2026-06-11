# Plan técnico: Authentication

- Spec: `specs/authentication/spec.md`
- Estado: Implementado

## 1. Resumen

NestJS `AuthModule` con `AuthService` (login, register, validateToken) y `AuthController`. JWT firmado con `JwtService`. Passwords con bcrypt. Guard `JwtAuthGuard` extrae payload y lo adjunta a `request.user`.

## 2. Arquitectura

- `backend/src/auth/auth.module.ts`
- `auth.service.ts` — `login`, `register`, `me`
- `auth.controller.ts` — endpoints
- `jwt.strategy.ts` — Passport strategy
- `jwt-auth.guard.ts` — guard reutilizable
- `roles.guard.ts` + decorador `@Roles()` — autorización por rol
- Frontend: `mobile/src/features/auth/` — `AuthContext`, `AuthService`, `LoginScreen`, `RegisterScreen`

## 3. Modelo de datos

- `User(id, email unique, passwordHash, name, role, taqueriaId, createdAt)`
- `Taqueria(id, name, restaurantCode unique, address, city, state, createdAt)`

## 4. Contratos

- `POST /auth/login`, `POST /auth/register`, `GET /auth/me` — ver `contracts/openapi.yaml`.

## 5. Decisiones técnicas

- bcrypt rounds = 10.
- JWT HS256, expiración 24h.
- Persistencia mobile: `AsyncStorage` con key `@tm:accessToken`.

## 6. Testing

- E2E: `backend/test/auth.e2e-spec.ts`.
- Gherkin: `specs/authentication/acceptance.feature`.

## 7. Trazabilidad

Ver `traceability.md` (REQ-0001 a REQ-0005).
