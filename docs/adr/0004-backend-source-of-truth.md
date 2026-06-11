# ADR-0004: Backend como fuente de verdad

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

Tenemos un frontend React Native y un backend NestJS. La pregunta es dónde residen las reglas: cálculo de totales, transiciones de estado, ordenamiento de cocina, validaciones condicionales (por ejemplo `reference` obligatorio en DINE_IN/TAKEAWAY).

Si el frontend duplica lógica:
- Divergencias entre clientes (web futuro, mobile, integraciones).
- Bugs por desincronización al actualizar reglas.
- Riesgo de bypass: cliente malicioso podría calcular distinto.

## Decisión

**El backend es la única fuente autoritativa.** El frontend solo presenta.

1. Toda regla de negocio (transiciones, validaciones, derivaciones) vive en el backend.
2. El frontend NUNCA calcula totales, estado derivado, orden de cocina.
3. Las respuestas del backend son el objeto verdadero que la UI muestra.
4. Cuando el cliente necesita mostrar algo derivado, lo pide al backend o lo recibe en el payload.
5. Los DTOs de entrada usan `class-validator` con validación condicional (`@ValidateIf`) — el cliente puede prevalidar UX, pero la verdad es del server.

## Alternativas consideradas

- **Smart client / thin server** — más flexible offline, pero divergencia inevitable.
- **Shared validation library** — requiere monorepo, complica deploys mobile.

## Consecuencias

Positivas:
- Una sola fuente de reglas. Cambios atómicos.
- Tests del backend cubren toda la lógica crítica.
- Cualquier cliente nuevo es compatible si respeta el contrato.

Negativas:
- UX offline limitada en versiones futuras (mitigable con queue local + sync).
- Cada validación es un round-trip.

Neutrales:
- Los contratos OpenAPI/AsyncAPI son la frontera contractual entre backend y clientes.

## Referencias

- Constitución Artículo II — Backend como Fuente de Verdad
- `architecture.md` — Backend as Source of Truth
- `contracts/openapi.yaml`
- REQ-0023, REQ-0024, REQ-0034, REQ-0035, REQ-0041
