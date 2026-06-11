# ADR-0001: Multi-Tenant por Taquería

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

TacosManager es una plataforma SaaS donde múltiples taquerías independientes operan simultáneamente. Cada taquería tiene su propio catálogo, pedidos, usuarios e historial. La filtración de datos entre taquerías sería un fallo crítico (legal, comercial y de confianza).

Debíamos decidir el modelo de tenancy: silo (una DB por tenant), pool (DB compartida con filtros), o bridge (esquemas separados en la misma DB).

## Decisión

Adoptamos **pool multi-tenant**: una sola base PostgreSQL con discriminador `taqueriaId` en cada tabla relevante. El aislamiento se enforza en capa de aplicación:

1. Toda entidad tiene `taqueriaId` no nulo.
2. Toda query incluye filtro obligatorio por `taqueriaId` derivado del JWT.
3. Guards de NestJS validan ownership antes del controller.
4. Tests automatizados verifican que un usuario de taquería A no puede leer ni mutar recursos de taquería B.

El `restaurantCode` (ej. `TM-4821`) es el identificador público de cara al usuario; `taqueriaId` (UUID) es interno.

## Alternativas consideradas

- **Silo (DB por taquería)** — máximo aislamiento, costo operativo prohibitivo en early stage, deploys complejos.
- **Bridge (schemas por taquería)** — aislamiento medio, migraciones complejas, Prisma no lo soporta natural.
- **Pool (elegido)** — costo bajo, performance buena, riesgo de filtración mitigado por guards + tests.

## Consecuencias

Positivas:
- Costo de infraestructura mínimo.
- Una sola migración para todos los tenants.
- Onboarding instantáneo: crear taquería = `INSERT`.

Negativas:
- Cualquier query mal escrita es vector de filtración. Requiere disciplina y tests defensivos.
- Sin aislamiento físico, performance de un tenant puede impactar a otros (mitigado con índices por `taqueriaId`).

Neutrales:
- Migrar a silo en el futuro es viable (export por `taqueriaId`).

## Referencias

- Constitución Artículo I — Multi-Tenancy Estricto
- `business-rules.md` §2
- `architecture.md` — Multi-Tenant Architecture
- REQ-0015, REQ-0052
