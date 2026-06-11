# Architecture Decision Records (ADR)

Registro de decisiones arquitectónicas del proyecto TacosManager. Cada ADR es **inmutable** una vez aceptado. Cambios producen un ADR nuevo con estado `Supersedes: ADR-XXXX`.

## Formato

Usamos [MADR](https://adr.github.io/madr/) (Markdown Architecture Decision Record). Plantilla mínima:

```markdown
# ADR-NNNN: Título corto

- Estado: Propuesto | Aceptado | Deprecado | Reemplazado por ADR-XXXX
- Fecha: YYYY-MM-DD
- Autores: …

## Contexto

¿Qué problema motiva esta decisión?

## Decisión

¿Qué decidimos?

## Alternativas consideradas

- A — pros/contras
- B — pros/contras

## Consecuencias

- Positivas:
- Negativas:
- Neutrales:

## Referencias

- Artículo de constitución afectado
- Specs/contratos relacionados
```

## Índice

| ID | Título | Estado | Fecha |
|---|---|---|---|
| ADR-0001 | Multi-Tenant por Taquería | Aceptado | 2026-06-11 |
| ADR-0002 | JWT como mecanismo de autenticación | Aceptado | 2026-06-11 |
| ADR-0003 | Socket.IO v4 para realtime | Aceptado | 2026-06-11 |
| ADR-0004 | Backend como fuente de verdad | Aceptado | 2026-06-11 |
| ADR-0005 | Modelo append-only para órdenes | Aceptado | 2026-06-11 |
| ADR-0006 | Ordenamiento de Kitchen Queue | Aceptado | 2026-06-11 |
| ADR-0007 | Docs distribuidas vía Git Submodules | Aceptado | 2026-06-11 |
| ADR-0008 | Spec-Driven Development como flujo de trabajo | Aceptado | 2026-06-11 |
| ADR-0009 | Política de versionado de specs y REQ-IDs | Aceptado | 2026-06-11 |
