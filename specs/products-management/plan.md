# Plan técnico: Products Management

- Spec: `specs/products-management/spec.md`

## Arquitectura

- `ProductsModule` (NestJS) con controller + service + DTOs.
- Guards: `JwtAuthGuard` global + `RolesGuard` en endpoints mutativos.
- Prisma model `Product(id, taqueriaId, name, price, complements jsonb, createdAt, updatedAt)`.
- Filtro automático `where: { taqueriaId: req.user.taqueriaId }` en TODAS las queries.

## Decisiones

- DELETE por ahora es hard delete (ETAPA temprana, sin órdenes históricas masivas).
- Complementos almacenados como `string[]` en jsonb por simplicidad.

## Testing

- E2E: `backend/test/products.e2e-spec.ts`.
- Gherkin: `specs/products-management/acceptance.feature`.

## Trazabilidad

REQ-0010 a REQ-0015. Ver `traceability.md`.
