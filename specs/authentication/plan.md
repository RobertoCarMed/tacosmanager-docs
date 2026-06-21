# Plan técnico: Authentication

- Spec: `specs/authentication/spec.md`
- Estado: Implementado

## 1. Resumen

NestJS `AuthModule` con `AuthService` (login, register, validateToken) y
`AuthController`. JWT firmado con `JwtService`. Passwords con bcrypt. Guard
`JwtAuthGuard` extrae payload y lo adjunta a `request.user`.

`POST /auth/register` implementa un flujo de 2 fases en un solo endpoint:

1. Discovery sin side effects usando `taqueriaName`
2. Confirmacion explicita del cliente para:
   - join: `confirmJoinExistingTaqueria=true` + `selectedRestaurantCode`
   - create: `createNewTaqueria=true` + `taqueriaData`

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

### Register request real

- Base requerido: `taqueriaName`, `name`, `email`, `password`, `role`
- Join confirmado: base + `confirmJoinExistingTaqueria=true` + `selectedRestaurantCode`
- Create confirmado: base + `createNewTaqueria=true` + `taqueriaData`

## 5. Decisiones técnicas

- bcrypt rounds = 10.
- JWT HS256, expiración 24h.
- Persistencia mobile: `AsyncStorage` con key `@tm:accessToken`.

## 6. Testing

- E2E esperado: `backend/test/auth.e2e-spec.ts`.
- Estado verificado en 2026-06-20: no se encontraron tests auth ejecutables en el
  repo backend auditado; la implementacion fue reconstruida desde codigo fuente.
- Gherkin: `specs/authentication/acceptance.feature`.

## 7. Trazabilidad

Ver `traceability.md` (`REQ-0001` a `REQ-0003`, `REQ-0055` a `REQ-0061`).
