# Plan técnico: <Nombre de la feature>

- Spec: `specs/<feature>/spec.md`
- Estado: Borrador | Aprobado | Implementado
- Autores:
- Fecha:

## 1. Resumen

2-3 líneas: qué se construye y cómo en grandes trazos.

## 2. Arquitectura

¿Qué módulos/capas se tocan? Diagrama si ayuda.

- Backend: módulos NestJS afectados
- Frontend: componentes/screens/Redux slices
- DB: tablas, columnas, índices
- Realtime: eventos emitidos/consumidos

## 3. Modelo de datos

Esquema Prisma o SQL nuevo/modificado.

## 4. Contratos

- REST: endpoint(s) → referencia en `contracts/openapi.yaml`
- Socket.IO: evento(s) → referencia en `contracts/asyncapi.yaml`
- DTOs: validaciones (`class-validator`, `@ValidateIf`)

## 5. Decisiones técnicas

- Decisión 1: razón. ¿Requiere ADR? Sí/No.
- Decisión 2: …

## 6. Migración / Compatibilidad

- ¿Hay datos existentes? ¿Migración?
- ¿Breaking change en contratos? ¿Versión?

## 7. Testing

- Tests unitarios:
- Tests e2e:
- Tests Gherkin: `acceptance.feature`
- Cobertura mínima esperada:

## 8. Observabilidad

- Logs estructurados nuevos
- Métricas
- Health checks

## 9. Rollout

- Feature flag: sí/no
- Pasos de deploy
- Plan de rollback

## 10. Trazabilidad

| REQ | Test | Archivos |
|---|---|---|
| REQ-NNNN | path/test.ts::nombre | backend/src/… |
