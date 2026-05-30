# TacosManager — CI/CD Strategy

Version: 1.0
Etapa: 5.0.4.4 — CI/CD Conventions & Documentation 🟡 EN PROGRESO

---

## Propósito

Este documento define las convenciones CI/CD del proyecto TacosManager. Su objetivo es que cualquier desarrollador o IA pueda entender y operar el ciclo de integración y entrega sin depender de conocimiento tácito.

Cubre: estrategia de ramas, commits, Pull Requests, releases, ambientes, GitHub Actions, Branch Protection, proceso de hotfix y convenciones para desarrollo asistido por IA.

---

## 1. Estrategia de ramas

```txt
feature/*  →  dev  →  qa  →  main
```

| Rama | Propósito | CI en PR | Artefactos post-merge |
|------|-----------|----------|-----------------------|
| `feature/*` | Desarrollo individual | — | — |
| `dev` | Integración continua | lint + typecheck | lint + typecheck |
| `qa` | Staging / validación funcional | lint + typecheck | + APK QA + Health Check |
| `main` | Producción | lint + typecheck | + APK QA + AAB Production |

Reglas clave:
- Solo se mergea `feature/*` → `dev` via PR
- Solo se mergea `dev` → `qa` via PR (nunca saltarse dev)
- Solo se mergea `qa` → `main` via PR (nunca saltarse qa)
- Nunca push directo a `dev`, `qa` ni `main`

Documentación detallada: `docs/branch-strategy.md`

---

## 2. Convenciones de commits

Estándar: **Conventional Commits** (`https://www.conventionalcommits.org`)

### Formato

```txt
<tipo>(<scope>): <descripción en imperativo, minúsculas>

[cuerpo opcional]

[trailers opcionales]
```

### Tipos permitidos

| Tipo | Cuándo usarlo |
|------|---------------|
| `feat` | Nueva funcionalidad de producto |
| `fix` | Corrección de bug |
| `docs` | Solo documentación |
| `refactor` | Refactor sin cambio de comportamiento |
| `test` | Agregar o corregir tests |
| `ci` | Cambios en workflows, scripts de CI/CD |
| `chore` | Mantenimiento, dependencias, configuración |
| `perf` | Mejora de rendimiento |

### Scope

Módulo o área impactada. Usar el nombre de la etapa, módulo o feature.

### Ejemplos reales del proyecto

```txt
feat(orders): add DELIVERY type with address validation
fix(kitchen): remove UPDATED state from status priority
docs(5.0.4.1): Mobile Pipeline Optimization — EN PROGRESO
ci(mobile): add branch strategy triggers to workflow
refactor(auth): replace Firebase Auth with JWT from NestJS
chore(deps): remove @react-native-firebase/auth and firestore
test(orders): add 12 cases for OrderType and FIFO validation
```

### Trailers

Los commits generados con Claude Code incluyen:
```txt
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## 3. Convenciones de Pull Requests

### Naming

Seguir el mismo formato que los commits:

```txt
feat(scope): descripción corta
fix(scope): descripción corta
docs(scope): descripción corta
ci(scope): descripción corta
```

Ejemplos:
```txt
feat(5.0.5): add Sentry error tracking to backend
fix(orders): correct PREPARING priority in kitchen queue
docs(5.0.4.4): add CI/CD strategy and contributing guide
ci(mobile): run build jobs on PRs to qa and main
chore: update pnpm lockfile after dependency update
```

### Descripción requerida

Toda PR debe incluir:

```markdown
## Qué hace este PR
[1-3 bullets con los cambios concretos]

## Por qué
[Contexto o etapa — ej: "Parte de ETAPA 5.0.4.4", "Fix para bug reportado en qa"]

## Cómo probar
[Pasos para validar el cambio, o "N/A — solo documentación"]

## Docs actualizadas
- [ ] roadmap.md
- [ ] architecture.md
- [ ] [otro doc impactado]
```

### Checklist mínima antes de solicitar review

```txt
□ CI verde (Mobile • Lint & TypeCheck + Backend • Lint, Build & Validate)
□ Sin conflictos con la rama destino
□ Documentación actualizada si hay cambio funcional
□ Descripción del PR completa
□ Scope correcto: no incluye cambios no relacionados
```

### Criterios para merge

- CI verde en todos los status checks requeridos
- Al menos 1 review aprobado (en qa y main)
- Rama actualizada con la rama destino (up to date)
- Sin conflictos de merge
- Descripción del PR completa

---

## 4. Convenciones de releases

### QA Release

**Trigger:** merge a `qa`

**Qué genera:**
- APK QA firmado: `app-qa-release-<sha>.apk`
- Artefacto disponible por 30 días en GitHub Actions → Artifacts

**Cómo validar:**
1. Abrir GitHub → Actions → push a qa → job `Mobile • Build QA APK`
2. Descargar `app-qa-release-<sha>.apk`
3. Instalar con adb: `adb install app-qa-release-<sha>.apk`
4. Verificar login, órdenes, cocina, realtime
5. Verificar health check backend en QA (job `Backend • Health Check QA`)

### Production Release

**Trigger:** merge a `main`

**Qué genera:**
- APK QA: `app-qa-release-<sha>.apk` (regresión, 30 días)
- AAB Production: `app-production-release-<sha>.aab` (Play Store, 30 días)

**Cómo validar:**
1. Abrir GitHub → Actions → push a main → verificar los 3 jobs de Mobile
2. Descargar `app-production-release-<sha>.aab`
3. Subir a Google Play Console → Internal Testing track
4. Ejecutar checklist de validación post-subida

**Naming de artefactos:**
```txt
app-qa-release-<git-sha>.apk
app-production-release-<git-sha>.aab
```

El `<git-sha>` es el commit hash completo del push que disparó el build.

---

## 5. Convenciones de ambientes

### Development (local)

| Variable | Valor típico |
|----------|-------------|
| `API_URL` | `http://10.0.2.2:3000` (emulador Android) |
| `SOCKET_URL` | `http://10.0.2.2:3000` |
| `ENVIRONMENT` | `development` |
| `NODE_ENV` (backend) | `development` |
| `DATABASE_URL` | `postgresql://localhost:5432/tacosmanager_dev` |

Archivo de entorno mobile: `.env.development`
Archivo de entorno backend: `.env.development`

### QA

| Variable | Valor |
|----------|-------|
| `API_URL` | `$QA_API_URL` (GitHub Variable) |
| `SOCKET_URL` | `$QA_SOCKET_URL` (GitHub Variable) |
| `ENVIRONMENT` | `qa` |
| `NODE_ENV` (backend) | `qa` |
| `DATABASE_URL` | PostgreSQL Railway QA (Secret Railway) |

Archivo de entorno mobile: `.env.qa` (generado en CI desde GitHub Variables)

### Production

| Variable | Valor |
|----------|-------|
| `API_URL` | `$PROD_API_URL` (GitHub Variable) |
| `SOCKET_URL` | `$PROD_SOCKET_URL` (GitHub Variable) |
| `ENVIRONMENT` | `production` |
| `NODE_ENV` (backend) | `production` |
| `DATABASE_URL` | PostgreSQL Railway Production (Secret Railway) |

Archivo de entorno mobile: `.env.production` (generado en CI desde GitHub Variables)

### Reglas de ambiente

- Los archivos `.env.*` nunca se commitean (están en `.gitignore`)
- La única excepción es `.env.example` (plantilla pública, sin valores reales)
- CI genera `.env.qa` y `.env.production` dinámicamente desde GitHub Variables
- Las credenciales sensibles van en GitHub Secrets, nunca en Variables

---

## 6. Convenciones de GitHub Actions

### Mobile CI (`.github/workflows/mobile-ci.yml`)

| Job | Nombre en GitHub | Cuándo corre | Qué valida | Qué bloquea |
|-----|-----------------|--------------|------------|-------------|
| `lint-typecheck` | `Mobile • Lint & TypeCheck` | Todos los triggers | ESLint + tsc --noEmit | Merge si falla (via branch protection) |
| `build-qa` | `Mobile • Build QA APK` | Push a qa, main | `assembleQaRelease` | — (post-merge) |
| `build-production` | `Mobile • Build Production AAB` | Push a main | `bundleProductionRelease` | — (post-merge) |

### Backend CI (`.github/workflows/backend-ci.yml`)

| Job | Nombre en GitHub | Cuándo corre | Qué valida | Qué bloquea |
|-----|-----------------|--------------|------------|-------------|
| `validate` | `Backend • Lint, Build & Validate` | Todos los triggers | ESLint + nest build + prisma validate | Merge si falla (via branch protection) |
| `health-check-qa` | `Backend • Health Check QA` | Push a qa | GET /health → status: "ok" | — (post-merge) |

### Naming convention para jobs

Formato: `Repositorio • Descripción`

Ejemplos: `Mobile • Lint & TypeCheck`, `Backend • Health Check QA`

Este formato hace los nombres legibles en la UI de GitHub y en las notificaciones de email.

### Naming convention para artefactos

Formato: `app-<flavor>-<type>-<sha>`

Ejemplos: `app-qa-release-abc1234`, `app-production-release-abc1234`

---

## 7. Convenciones de Branch Protection

Implementado con **GitHub Rulesets** (no Branch Protection legacy).

| Regla | dev | qa | main |
|-------|:---:|:--:|:----:|
| Require Pull Request | ✅ | ✅ | ✅ |
| Require status checks | ✅ | ✅ | ✅ |
| Block force pushes | ✅ | ✅ | ✅ |
| Restrict deletions | ✅ | ✅ | ✅ |

Status checks requeridos (idénticos para dev/qa/main):
- Mobile: `Mobile • Lint & TypeCheck`
- Backend: `Backend • Lint, Build & Validate`

Los builds son quality gates post-merge, no checks de PR (los jobs son `skipped` en eventos PR).

Documentación completa: `docs/cicd-governance.md`

---

## 8. Proceso de hotfix

Un hotfix es una corrección urgente que debe llegar a producción sin pasar por el ciclo completo `dev → qa → main`.

### Cuándo usar hotfix

- Bug crítico en producción que afecta operación de taquerías
- Vulnerabilidad de seguridad activa
- El ciclo normal tardaría más de lo aceptable en una situación de emergencia

Para bugs no urgentes: usar el flujo normal `feature/* → dev → qa → main`.

### Flujo oficial de hotfix

```txt
main
  ↓ (crear rama)
hotfix/<descripcion>
  ↓ (aplicar fix + test local)
  ↓ PR → main (review de emergencia, mínimo 1 persona)
main ← fix aplicado
  ↓ PR → qa  (sync obligatorio)
 qa  ← fix sincronizado
  ↓ PR → dev (sync obligatorio)
 dev ← fix sincronizado
```

### Por qué este flujo

- **Velocidad a producción:** el fix llega a `main` en un PR directo, sin esperar qa
- **Integridad del historial:** `qa` y `dev` se sincronizan después, el fix no se pierde en merges futuros
- **No bypassear CI:** incluso el PR de emergencia pasa por `Mobile • Lint & TypeCheck` y `Backend • Lint, Build & Validate`

### Naming de rama hotfix

```txt
hotfix/<descripcion-corta>
hotfix/fix-order-status-stuck
hotfix/jwt-expiry-crash
```

### Checklist de hotfix

```txt
□ Crear hotfix/* desde main (no desde dev ni qa)
□ Aplicar solo el cambio mínimo necesario
□ Validar localmente antes del PR
□ PR hotfix/* → main con descripción clara del bug y la solución
□ CI verde antes de mergear
□ Review de al menos 1 persona
□ Merge a main
□ Verificar el build post-merge (Actions → push a main)
□ PR main → qa (sync)
□ PR qa → dev (sync)
□ Documentar el incidente si fue crítico
```

---

## 9. AI-Assisted Development

TacosManager es un proyecto desarrollado con asistencia activa de herramientas de IA.

### Herramientas utilizadas

| Herramienta | Uso | Tipo de tareas |
|-------------|-----|----------------|
| **Claude Code** (Anthropic) | Asistente principal | Implementación de features, refactors, documentación, CI/CD |
| **ChatGPT** (OpenAI) | Exploración y diseño | Investigación de opciones, arquitectura, debugging |
| **GitHub Copilot / Codex** | Sugerencias inline | Autocompletado, snippets |

### Reglas para desarrollo asistido por IA

1. **Todo cambio funcional generado por IA debe ser revisado por el desarrollador** antes de commitear
2. **El código generado por IA sigue los mismos estándares** de calidad que el código humano
3. **La IA no toma decisiones arquitectónicas** sin aprobación explícita del desarrollador
4. **Los cambios asistidos por IA pasan por el mismo proceso de PR** que los cambios humanos
5. **La documentación se actualiza síncronamente** con los cambios funcionales

### Documentación obligatoria post-cambio

Ante cualquier modificación funcional (con o sin IA), verificar y actualizar:

| Documento | Actualizar cuando |
|-----------|-------------------|
| `docs/roadmap.md` | Cambia el estado de una etapa, se agrega funcionalidad |
| `docs/architecture.md` | Cambia la arquitectura del sistema, módulos, flujos |
| `docs/api-reference.md` | Se agregan, modifican o eliminan endpoints |
| `docs/business-rules.md` | Cambian las reglas de negocio del dominio |
| `docs/frontend-architecture.md` | Cambia la arquitectura frontend, navegación, componentes |
| `docs/feature-list.md` | Se implementa o completa una funcionalidad del producto |
| Cualquier `docs/cicd-*.md` | Cambia un workflow, pipeline o estrategia CI/CD |

**La documentación es parte del producto. Un cambio sin documentación no está terminado.**

### Convenciones para prompts con IA

Al solicitar implementaciones a una IA, el prompt debe incluir:

```txt
1. Etapa actual y objetivo (ej: "ETAPA 5.0.4.4 — CI/CD Conventions")
2. Contexto del proyecto (stack: NestJS, React Native, PostgreSQL, etc.)
3. Restricciones explícitas ("NO modificar X", "mantener Y intacto")
4. Documentos relevantes de referencia
5. Formato de entregables esperados
```

Al finalizar una tarea con IA, verificar que la respuesta incluya:
- Lista de archivos creados
- Lista de archivos modificados
- Lista de documentación afectada

---

## 10. Reglas de sincronización de documentación

### Estructura de docs del proyecto

```txt
docs/
├── README.md              — índice de documentación
├── roadmap.md             — estado de todas las etapas
├── architecture.md        — arquitectura backend
├── frontend-architecture.md — arquitectura frontend
├── api-reference.md       — referencia de endpoints
├── business-rules.md      — reglas de negocio
├── business-model.md      — modelo comercial
├── feature-list.md        — funcionalidades del producto
├── cicd-strategy.md       — este documento: convenciones CI/CD
├── cicd-mobile.md         — pipeline mobile
├── cicd-backend.md        — pipeline backend
├── cicd-governance.md     — branch protection y status checks
├── branch-strategy.md     — estrategia de ramas
├── contributing.md        — guía para contribuidores
├── deployment-runbook.md  — runbooks operativos
├── ui-flows.md            — flujos de UI
├── backend-api.md         — detalles de API
└── backend-realtime.md    — arquitectura realtime
```

### Regla de versioning de docs

Cada documento lleva encabezado `Version: X.Y` y línea `Última actualización: ETAPA X.X.X`.

Incrementar versión menor (`X.Y → X.Y+1`) al agregar o corregir contenido.
Incrementar versión mayor (`X.Y → X+1.0`) al reestructurar el documento.

### Regla de cierre de etapa

Una etapa NO se considera cerrada hasta que:
1. `roadmap.md` refleja ✅ COMPLETADA con fecha
2. Todos los documentos impactados están actualizados
3. Los cambios están commiteados y pusheados

---

## Documentos relacionados

- `docs/branch-strategy.md` — propósito de ramas y flujo de promoción
- `docs/cicd-governance.md` — branch protection y status checks
- `docs/cicd-mobile.md` — pipeline mobile completo
- `docs/cicd-backend.md` — pipeline backend completo
- `docs/contributing.md` — guía para contribuidores (setup, workflow)
- `docs/deployment-runbook.md` — runbooks operativos (deploy, rollback)
