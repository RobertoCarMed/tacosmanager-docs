# ADR-0009: Política de versionado de specs y REQ-IDs

- Estado: Aceptado
- Fecha: 2026-06-11
- Autores: Equipo TacosManager

## Contexto

Tras adoptar SDD (ADR-0008), surgen preguntas operativas que no quedaron resueltas:

1. Cuando un acceptance criterion ya implementado cambia comportamiento, ¿se edita in-place el REQ existente o se crea uno nuevo?
2. ¿Cómo se versiona una spec? ¿Sigue semver?
3. ¿Cómo se distingue un cambio aditivo (nuevo REQ) de uno breaking (REQ existente cambia)?
4. ¿Qué hacemos con tests que dependen de la versión anterior de un REQ?
5. ¿Cómo se coordina con el versionado de contratos OpenAPI/AsyncAPI?

Sin política, cada developer/agente interpreta distinto y los REQ-IDs pierden estabilidad — el cimiento de la trazabilidad colapsa.

## Decisión

Adoptamos una política formal de versionado con tres reglas duras:

### Regla 1 — REQ-IDs son inmutables

Una vez merged con estado `✅ Implementado`, un `REQ-NNNN` JAMÁS se edita semánticamente. Permitido: corregir typos, mejorar redacción sin cambiar comportamiento. Prohibido: cambiar status code esperado, cambiar campos requeridos, cambiar reglas de validación.

Si el comportamiento debe cambiar:

1. Asignar nuevo `REQ-MMMM` con el nuevo comportamiento.
2. Marcar `REQ-NNNN` como `🗑️ Deprecado` en `traceability.md` con campo `Sucesor: REQ-MMMM`.
3. El test del REQ viejo se elimina o se mueve a una sección de regresión histórica.

### Regla 2 — Specs siguen SemVer

Cada `spec.md` lleva header:

```markdown
- Versión: MAJOR.MINOR
```

- **MAJOR (+1):** algún REQ existente cambia comportamiento (deprecación + sucesor). Breaking.
- **MINOR (+1):** se agregan REQ nuevos sin tocar los existentes. Aditivo.
- **Patch:** no aplica. Cambios de redacción no bumpean.

Versión inicial al crear la spec: `1.0`.

### Regla 3 — Lifecycle de REQ-ID

Estados permitidos en `traceability.md`:

| Estado | Significado | Transiciones permitidas |
|---|---|---|
| 🔴 Pendiente | Spec aprobada, sin implementar | → 🟡, → 🗑️ |
| 🟡 En progreso | Implementación iniciada | → ✅, → 🔴 |
| ✅ Implementado | Test pasa en CI | → 🗑️ |
| 🗑️ Deprecado | Sucedido por otro REQ o eliminado | (terminal) |

Un REQ NUNCA vuelve de `✅` a `🔴`. Si se descubre que estaba mal implementado, se mantiene `✅` con el comportamiento documentado y se crea un REQ nuevo para el comportamiento corregido.

## Coordinación con contratos

- Cambio breaking en `contracts/openapi.yaml` o `contracts/asyncapi.yaml` requiere bump de versión del contrato (declarado en `info.version`) **y** ADR explicando el plan de deprecación.
- Cambio breaking en una spec implica que el contrato asociado probablemente también necesita bump.
- Periodo de deprecación mínimo recomendado: 1 release cycle del consumidor (backend o mobile).

## Enforcement

- Workflow CI (`spec-versioning.yml`) que rechaza PRs que modifican:
  - Un `acceptance.feature` con escenarios `@REQ-NNNN` ya `✅ Implementado` sin bumpear versión de la spec correspondiente.
  - Un `spec.md` cuyo header `Versión:` no se incrementó tras editar REQ implementados.
- Workflow de trazabilidad (Issue #7) detecta REQ huérfanos y reporta drift.

## Alternativas consideradas

- **Sin versionado de specs** — status quo. Riesgo demostrado: los REQ-IDs se erosionan.
- **SemVer completo (con patch)** — overhead innecesario; patch no aporta señal real.
- **Hash-based versioning** — opaco para humanos.
- **Editar REQ-IDs in-place** — rompe trazabilidad histórica de tests, PRs y discusiones.

## Consecuencias

Positivas:
- REQ-IDs como referencia estable: cualquier mención en commits viejos sigue siendo válida.
- Diferencia clara entre evolución aditiva y breaking.
- Coordinación entre specs y contratos formalizada.

Negativas:
- Disciplina adicional: cada cambio a spec implementada debe pensarse antes.
- El `traceability.md` crece monotónicamente (entradas deprecadas no se borran).

Neutrales:
- Reciclar `REQ-NNNN` libres de deprecaciones está prohibido — siempre incrementar.

## Referencias

- Constitución Artículo VI — Spec-Driven Development
- ADR-0008 — SDD adoption
- `traceability.md`
- `specs/_templates/spec.md`
