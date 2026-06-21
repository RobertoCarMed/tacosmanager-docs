# ADR-0014: Features fuera de la numeración de ETAPAs

- Estado: Aceptado
- Fecha: 2026-06-21
- Autores: Equipo TacosManager

## Contexto

El roadmap organiza el trabajo en **ETAPAs** numeradas (`X.Y.Z`) y `traceability.md` tiene
una columna "ETAPA". Esa numeración creció de forma orgánica y hoy es **incoherente** (orden
y dependencias no siempre cuadran). No queremos reordenarla ahora.

Surge una feature nueva (`specs/ticket-printing/`) que debe entrar al producto **sin**
forzarla dentro de esa secuencia numerada ni heredar su desorden, pero siguiendo SDD.

Pregunta de fondo: ¿cuál es la **unidad de trabajo** en SDD — la ETAPA o la spec?

## Decisión

La **unidad de trabajo es la spec/feature** (`specs/<feature>/`). La ETAPA es solo una
etiqueta histórica de agenda del roadmap, no un requisito para que una feature exista.

Una feature **puede no tener ETAPA numerada**. Convenciones:

1. **Identidad:** la feature se identifica por su carpeta de spec (`specs/<slug>/`).
2. **Trazabilidad:** en `traceability.md`, la columna "ETAPA" admite un tag de feature
   `feat:<slug>` en lugar de un número, cuando la feature no pertenece a la numeración.
   `scripts/build-traceability.js` no valida el valor de "ETAPA", así que no se rompe nada.
3. **Roadmap:** estas features viven en una sección dedicada
   **"Características (fuera de la numeración de ETAPAs)"**, separada de la lista numerada.
   No se les asigna `X.Y.Z`.
4. **specs/README:** la columna ETAPAS de esas features se marca `— (feat)`.

Esto **no** corrige la incoherencia de la numeración existente (decisión deliberada de
posponerla); solo permite **esquivarla** para trabajo nuevo sin contaminarlo.

Primer caso: `specs/ticket-printing/` (REQ-0070–REQ-0080), tag `feat:ticket-printing`.

## Alternativas consideradas

- **Asignar un número igual (ej. ETAPA 4.11).** Mantiene una sola columna, pero mete la
  feature en una secuencia ya incoherente y sugiere un orden/dependencia que no existe.
  Descartada.
- **Renumerar/arreglar las ETAPAs ahora.** Correcto a largo plazo pero fuera de alcance hoy;
  el equipo decidió posponerlo. Descartada por ahora.

## Consecuencias

Positivas:
- Features nuevas entran sin heredar el desorden de la numeración.
- Refuerza que la spec (no la ETAPA) es la unidad de trabajo SDD.
- Reversible: si algún día se ordena la numeración, una feature `feat:` puede recibir un
  número.

Negativas:
- Conviven dos formas de etiquetar trabajo (ETAPA numerada y `feat:`) hasta que se unifique.

Neutrales:
- `glossary.md` añade el término **Feature** para distinguirlo de **ETAPA**.

## Referencias

- Constitución Artículo VI — Spec-Driven Development
- ADR-0009 — Política de versionado de specs y REQ-IDs
- `glossary.md` — Feature, ETAPA
- `roadmap.md` — sección "Características (fuera de la numeración de ETAPAs)"
- `specs/ticket-printing/` — primera feature bajo esta convención
