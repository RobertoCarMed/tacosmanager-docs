# Spec: Products Management

- ID: SPEC-products-management
- Estado: Implementada
- ETAPA asociada: 4.5.2

## 1. Problema

Cada taquería gestiona su propio catálogo de productos (tacos, bebidas, complementos disponibles). El catálogo debe ser editable por COOK y consumible por WAITER.

## 2. Objetivos

- CRUD completo sobre productos.
- Aislamiento multi-tenant estricto.
- Roles: COOK CRUD, WAITER read-only.

## 3. No-objetivos

- Inventario / stock.
- Precios variables por hora / promociones.

## 4. Actores

- COOK (CRUD).
- WAITER (read).

## 5. User Stories

- US-1: Como COOK quiero crear/editar/eliminar productos para mantener el catálogo al día.
- US-2: Como WAITER quiero leer el catálogo para armar pedidos.
- US-3: Como dueño de taquería A no quiero que taquería B vea mis productos.

## 6. Acceptance Criteria

### REQ-0010 — COOK lista todos los productos de su taquería
```gherkin
Dado un COOK autenticado de la taquería "TM-0001"
Cuando hace GET /products
Entonces recibe 200 con la lista de productos donde taqueriaId="TM-0001"
```

### REQ-0011 — WAITER lista todos los productos (lectura)
```gherkin
Dado un WAITER autenticado
Cuando hace GET /products
Entonces recibe 200 con la lista completa de su taquería
```

### REQ-0012 — Solo COOK puede crear productos
```gherkin
Cuando un WAITER hace POST /products
Entonces la respuesta es 403
```

### REQ-0013 — Solo COOK puede editar productos
```gherkin
Cuando un WAITER hace PATCH /products/:id
Entonces la respuesta es 403
```

### REQ-0014 — Solo COOK puede eliminar productos
```gherkin
Cuando un WAITER hace DELETE /products/:id
Entonces la respuesta es 403
```

### REQ-0015 — Usuario de taquería A no ve productos de taquería B
```gherkin
Dado un producto P de taquería "TM-0002"
Y un usuario autenticado de taquería "TM-0001"
Cuando intenta GET /products/<id-de-P>
Entonces la respuesta es 404 (nunca 200)
```

## 7. Edge Cases

- Producto sin nombre → 400.
- Producto con precio negativo → 400.
- DELETE de producto con items históricos en órdenes → soft delete o restricción (TBD ADR).

## 8. Requerimientos no funcionales

- Multi-tenancy: Artículo I.
- Performance: GET /products p95 < 150ms.

## 9. Dependencias

- ADR-0001 (multi-tenant), ADR-0002 (JWT).
- Contrato: `contracts/openapi.yaml#/paths/~1products`.

## 10. Riesgos

- ❓ Soft delete vs hard delete cuando hay histórico. Pendiente ADR.

## 11. Referencias

- `backend-api.md` — Products
- `business-rules.md` — Productos
