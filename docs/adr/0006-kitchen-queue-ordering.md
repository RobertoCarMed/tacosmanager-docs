# ADR-0006: Ordenamiento de Kitchen Queue

- Estado: Reemplazado por ADR-0010
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

> ⚠️ **Reemplazado por [ADR-0010](0010-priority-timestamp-ordering.md) (2026-06-20).**
> La clave FIFO dentro de un mismo status ya NO es `createdAt` sino `priorityTimestamp`
> (automático). El ordenamiento global por prioridad de status se mantiene sin cambios.
> Este documento se conserva como registro histórico de la decisión original.

## Contexto

La cocina necesita ver pedidos en un orden útil. El orden por `createdAt` puro no funciona: un pedido en `PREPARING` (cocinando ahora) debería estar arriba de uno `PENDING` recién llegado, porque ya hay trabajo en curso.

## Decisión

Ordenamiento global por **prioridad de status**, luego FIFO dentro de cada status:

```
PREPARING(1) > PENDING(2) > READY(3) > DELIVERED(4) > CANCELLED(5)
```

Dentro del mismo status: `createdAt ASC` (FIFO).

El backend devuelve la lista ya ordenada. El frontend NO reordena (Artículo II).

Cuando un mesero hace append a una orden ya `READY`, el status retrocede a `PENDING` para que vuelva a entrar en la cola activa.

## Alternativas consideradas

- **FIFO puro por `createdAt`** — confuso: pedidos viejos en `READY` se mezclan con `PENDING` nuevos.
- **`priorityTimestamp` editable** — más flexible pero permite reordenamiento manual no auditado.
- **Ordenamiento configurable por taquería** — over-engineering para el MVP.

## Consecuencias

Positivas:
- Cocina ve trabajo activo siempre arriba.
- Orden global determinista.
- Ningún cliente puede romper el orden.

Negativas:
- Una orden `READY` que recibe append "pierde" su lugar histórico — vuelve a `PENDING` pero la regla está clara y es esperada por la cocina.

Neutrales:
- Una taquería que quiera políticas distintas requerirá nuevo ADR.

## Referencias

- Constitución Artículo II — Backend como Fuente de Verdad
- ADR-0005 — Append-only
- `business-rules.md` — Reglas de Cocina
- `api-reference.md` — Kitchen Queue Rules
- REQ-0043, REQ-0044
