# ADR-0007: Docs distribuidas vía Git Submodules

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

Backend y frontend mobile son repos separados pero comparten reglas de negocio, contratos y convenciones. Necesitamos que la documentación viva en un solo lugar y sea consumida por ambos sin copy-paste.

## Decisión

Usamos **Git Submodules**: este repo (`tacosmanager-docs`) se monta como submódulo dentro de backend y mobile. La versión pin del submódulo se commitea en el repo consumidor.

1. Toda actualización funcional se hace **primero aquí**.
2. Backend y mobile actualizan su pin al commit más reciente de `main`.
3. PRs en backend/mobile que dependen de doc nueva DEBEN actualizar el pin del submódulo.

## Alternativas consideradas

- **Monorepo único** — alto costo de migración, complica CI/CD por separado.
- **Doc replicada con script de sync** — fuente de divergencia.
- **Doc en wiki / Notion** — sin versionado atado a commits, riesgo de divergencia.

## Consecuencias

Positivas:
- Una sola fuente versionada.
- Cada repo consumidor pin a una versión concreta — reproducible.
- Cambios atómicos visibles en PR del repo consumidor (actualización del pin).

Negativas:
- Submódulos tienen UX históricamente confuso (init, update).
- Un cambio breaking aquí no rompe consumidores hasta que actualicen pin (puede ocultar el problema).

Neutrales:
- Posible migrar a paquete versionado (npm/git tag) si la UX de submódulos se vuelve fricción.

## Referencias

- `README.md` — distribución
- `contributing.md` — flujo de actualización
