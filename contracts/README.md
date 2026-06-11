# Contracts

Contratos ejecutables del sistema. Toda spec REST y Socket.IO debe estar reflejada aquí.

| Archivo | Estándar | Cubre |
|---|---|---|
| `openapi.yaml` | OpenAPI 3.1 | Endpoints REST `/api/*` |
| `asyncapi.yaml` | AsyncAPI 2.6 | Eventos Socket.IO |

## Reglas

1. Cambiar un contrato es **breaking change** salvo que sea aditivo.
2. PRs que modifican un contrato DEBEN incluir ADR si rompen compatibilidad.
3. CI valida los contratos contra el código real (futuro: Spectral + Dredd/Schemathesis).
4. Toda spec en `specs/<feature>/spec.md` referencia las rutas o eventos de estos archivos.

## Tooling sugerido

- **Lint:** Spectral (`spectral lint contracts/openapi.yaml`).
- **Mock:** Prism (`prism mock contracts/openapi.yaml`).
- **Test:** Dredd o Schemathesis contra el backend en QA.
- **Visualización:** Redoc / Swagger UI / AsyncAPI Studio.

## Generación

Idealmente generamos `openapi.yaml` desde decoradores `@nestjs/swagger` y `asyncapi.yaml` desde `nestjs-asyncapi`. Por ahora se mantiene manual y sincronizado con `backend-api.md` y `backend-realtime.md`.
