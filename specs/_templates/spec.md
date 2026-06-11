# Spec: <Nombre de la feature>

- ID: SPEC-<slug>
- Estado: Borrador | Aprobada | Implementada | Deprecada
- Autores:
- Fecha:
- ETAPA asociada:

## 1. Problema / Oportunidad

¿Qué problema resuelve esta feature? ¿Para quién?

## 2. Objetivos

Lista los outcomes medibles que esta feature debe lograr.

## 3. No-objetivos

Cosas que esta feature explícitamente NO hace. Acota scope.

## 4. Actores

- ¿Quién interactúa? (COOK, WAITER, sistema)

## 5. User Stories

- US-1: Como `<actor>` quiero `<acción>` para `<beneficio>`.
- US-2: …

## 6. Acceptance Criteria (Gherkin)

Cada criterio lleva `REQ-NNNN`. Formato `Dado / Cuando / Entonces`.

### REQ-NNNN — <descripción corta>

```gherkin
Dado <precondición>
Cuando <acción>
Entonces <resultado esperado>
```

## 7. Edge Cases

- Caso A:
- Caso B:

## 8. Requerimientos no funcionales

- Performance:
- Seguridad:
- Multi-tenancy:
- Realtime:

## 9. Dependencias

- Specs: `specs/<otra>/spec.md`
- ADRs: `docs/adr/NNNN-*.md`
- Contratos: `contracts/openapi.yaml#…`, `contracts/asyncapi.yaml#…`

## 10. Riesgos / Preguntas abiertas

- 

## 11. Referencias

- Roadmap ETAPA: 
- business-rules.md §
- backend-api.md §
