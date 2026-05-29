# TacosManager — CI/CD Governance

Version: 1.0
Última actualización: ETAPA 5.0.4.3 — Branch Protection & Status Checks 🟡 EN PROGRESO

---

## Objetivos

- Todo código que llega a `main` ha pasado por `dev` y `qa`
- Todo merge a ramas compartidas requiere CI verde
- Los pipelines son obligatorios, no opcionales
- La configuración es reproducible y documentada

---

## Status checks — nombres exactos

Los nombres deben coincidir exactamente con los que aparecen en GitHub Actions.

### Mobile Repository (`TacosManager`)

Workflow: `.github/workflows/mobile-ci.yml`

| Nombre en GitHub Actions | Job ID | Corre en PR | Corre en push |
|--------------------------|--------|:-----------:|:-------------:|
| `Mobile • Lint & TypeCheck` | `lint-typecheck` | Siempre | Siempre |
| `Mobile • Build QA APK` | `build-qa` | No (skipped) | push → qa, main |
| `Mobile • Build Production AAB` | `build-production` | No (skipped) | push → main |

### Backend Repository (`TacosManager API`)

Workflow: `.github/workflows/backend-ci.yml`

| Nombre en GitHub Actions | Job ID | Corre en PR | Corre en push |
|--------------------------|--------|:-----------:|:-------------:|
| `Backend • Lint, Build & Validate` | `validate` | Siempre | Siempre |
| `health-check-qa` | `health-check-qa` | No (skipped) | push → qa |

---

## Branch Protection por rama

### dev — Protección mínima

**Propósito:** Garantizar que feature branches integren código válido antes de pasar a staging.

**Mobile Repository — `dev`**

| Setting | Valor recomendado |
|---------|-------------------|
| Require a pull request before merging | ✅ Activar |
| Required approving reviews | 0 (equipo pequeño) |
| Dismiss stale pull request approvals when new commits are pushed | — |
| Require status checks to pass before merging | ✅ Activar |
| Require branches to be up to date before merging | ✅ Activar |
| Include administrators | Opcional |

Status checks a agregar:
```txt
Mobile • Lint & TypeCheck
```

**Backend Repository — `dev`**

Misma configuración. Status check a agregar:
```txt
Backend • Lint, Build & Validate
```

---

### qa — Protección intermedia

**Propósito:** Garantizar que el código en staging pasó validación técnica y fue revisado por el equipo.

**Mobile Repository — `qa`**

| Setting | Valor recomendado |
|---------|-------------------|
| Require a pull request before merging | ✅ Activar |
| Required approving reviews | 1 |
| Dismiss stale pull request approvals when new commits are pushed | ✅ Activar |
| Require status checks to pass before merging | ✅ Activar |
| Require branches to be up to date before merging | ✅ Activar |
| Include administrators | Opcional |

Status checks a agregar:
```txt
Mobile • Lint & TypeCheck
```

> **Nota — Build QA APK:** Este check corre en push a `qa` (post-merge), no en PR. Requerirlo como check de PR bloquearía todos los PRs ya que el job es `skipped` para eventos `pull_request`. Ver sección **Limitaciones actuales**.

**Backend Repository — `qa`**

Misma configuración. Status check a agregar:
```txt
Backend • Lint, Build & Validate
```

---

### main — Protección máxima

**Propósito:** Garantizar que producción solo recibe código que pasó QA completo y fue aprobado por el equipo.

**Mobile Repository — `main`**

| Setting | Valor recomendado |
|---------|-------------------|
| Require a pull request before merging | ✅ Activar |
| Required approving reviews | 1 |
| Dismiss stale pull request approvals when new commits are pushed | ✅ Activar |
| Require status checks to pass before merging | ✅ Activar |
| Require branches to be up to date before merging | ✅ Activar |
| Include administrators | ✅ Activar (nadie bypassa producción) |
| Restrict who can push | Opcional — owners/maintainers únicamente |

Status checks a agregar:
```txt
Mobile • Lint & TypeCheck
```

> **Nota — Build APK/AAB:** Los jobs `Mobile • Build QA APK` y `Mobile • Build Production AAB` corren en push a `main` (post-merge). Ver sección **Limitaciones actuales** y **Estrategia post-merge**.

**Backend Repository — `main`**

Misma configuración. Status check a agregar:
```txt
Backend • Lint, Build & Validate
```

---

## Guía de configuración — paso a paso

### Prerrequisitos

1. Los workflows deben haber corrido al menos una vez para que GitHub registre los nombres de status checks en el selector.
2. Tener acceso de Owner o Admin al repositorio.
3. Si los status checks no aparecen en el selector de búsqueda: hacer un push de prueba a la rama correspondiente para que el workflow corra y registre los nombres.

---

### Mobile Repository — configurar `dev`

```txt
1. GitHub → RobertoCarMed/TacosManager → Settings → Branches
2. Click: "Add branch protection rule"
3. Branch name pattern: dev
4. Sección "Protect matching branches":
   ✅ Require a pull request before merging
      Required approving reviews: 0
   ✅ Require status checks to pass before merging
      ✅ Require branches to be up to date before merging
      Buscar y seleccionar: "Mobile • Lint & TypeCheck"
5. Click: "Create"
```

### Mobile Repository — configurar `qa`

```txt
1. GitHub → RobertoCarMed/TacosManager → Settings → Branches
2. Click: "Add branch protection rule"
3. Branch name pattern: qa
4. Sección "Protect matching branches":
   ✅ Require a pull request before merging
      Required approving reviews: 1
      ✅ Dismiss stale pull request approvals when new commits are pushed
   ✅ Require status checks to pass before merging
      ✅ Require branches to be up to date before merging
      Buscar y seleccionar: "Mobile • Lint & TypeCheck"
5. Click: "Create"
```

### Mobile Repository — configurar `main`

```txt
1. GitHub → RobertoCarMed/TacosManager → Settings → Branches
2. Click: "Add branch protection rule"
3. Branch name pattern: main
4. Sección "Protect matching branches":
   ✅ Require a pull request before merging
      Required approving reviews: 1
      ✅ Dismiss stale pull request approvals when new commits are pushed
   ✅ Require status checks to pass before merging
      ✅ Require branches to be up to date before merging
      Buscar y seleccionar: "Mobile • Lint & TypeCheck"
   ✅ Include administrators
5. Click: "Create"
```

### Backend Repository — configurar `dev`, `qa`, `main`

Misma estructura que Mobile. Reemplazar `Mobile • Lint & TypeCheck` con `Backend • Lint, Build & Validate`.

---

## Estrategia de calidad post-merge

Los builds de Android no corren en PRs — es intencional para mantener los PRs rápidos (solo lint + typecheck, sin compilación de Android de ~5-10 minutos).

Los builds son **quality gates post-merge**: corren después de que el merge fue aprobado y ejecutado.

### Qué monitorear después de cada merge

**Merge a qa:**
```txt
✓ Mobile • Lint & TypeCheck    — debe pasar
✓ Mobile • Build QA APK        — debe pasar (APK para pruebas)
✓ Backend • Lint, Build & Validate — debe pasar
✓ health-check-qa              — debe pasar (Railway QA responde)
```

**Merge a main:**
```txt
✓ Mobile • Lint & TypeCheck       — debe pasar
✓ Mobile • Build QA APK           — debe pasar
✓ Mobile • Build Production AAB   — debe pasar (AAB para Play Store)
✓ Backend • Lint, Build & Validate — debe pasar
```

Si cualquier check falla post-merge: abrir PR de fix inmediatamente.

---

## Limitaciones actuales

### Builds de Android no disponibles como checks de PR

**Contexto:** Los jobs `Mobile • Build QA APK` y `Mobile • Build Production AAB` tienen la condición:
```yaml
if: github.event_name == 'push' && (github.ref == 'refs/heads/qa' || ...)
```
En eventos `pull_request`, estos jobs son `skipped`. GitHub trata un check `skipped` como no-pasado, por lo que requerirlos en branch protection bloquearía todos los PRs.

**Impacto actual:** Los builds solo se validan post-merge. Un build roto se descubre después de mergear, no antes.

**Solución futura:** Agregar condición adicional en los jobs de build para que también corran en PRs hacia `qa` y `main`:
```yaml
if: |
  (github.event_name == 'push' && github.ref == 'refs/heads/qa') ||
  (github.event_name == 'pull_request' && github.base_ref == 'qa')
```
Esto aumentaría el tiempo de CI en PRs (~8-12 min adicionales) pero permitiría requerir los builds como checks de PR.

**Estado actual:** Suficiente para MVP. Evaluar en ETAPA 5.0.5 o posterior.

---

## Tabla resumen — Branch Protection

| Rama | PR required | Reviews | Status checks (PR) | Admins incluidos |
|------|:-----------:|:-------:|-------------------|:----------------:|
| `dev` | ✅ | 0 | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` | Opcional |
| `qa` | ✅ | 1 | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` | Opcional |
| `main` | ✅ | 1 | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` | ✅ |

---

## Responsabilidades de CI/CD

| Responsabilidad | Quién | Cuándo |
|-----------------|-------|--------|
| Mantener workflows funcionales | Desarrollador | Siempre |
| Actualizar GitHub Variables al cambiar URLs | Dev | Al cambiar infraestructura |
| Rotar secrets del keystore | Dev | Al renovar keystore |
| Revisar Actions después de merge a qa | Dev / QA | Después de cada merge a qa |
| Revisar Actions después de merge a main | Dev | Después de cada merge a main |
| Monitorear health check QA | Dev | Después de cada push a qa |
| Actualizar branch protection rules | Admin | Al cambiar estrategia de ramas |
| Revisar y actualizar esta documentación | Dev | Al cambiar CI/CD |

---

## Riesgos y recomendaciones

### Riesgo 1 — Build falla post-merge a main

**Impacto:** El AAB de producción no se genera. No hay artefacto para Play Store.

**Probabilidad:** Baja si el desarrollo local usa los mismos scripts de build.

**Mitigación:** Fix inmediato via PR en `main`. Si el build tarda en correr, los primeros ~10 minutos post-merge son la ventana crítica de monitoreo.

---

### Riesgo 2 — Health Check QA falla post-merge a qa

**Impacto:** El backend QA no responde. Las pruebas funcionales no pueden ejecutarse.

**Causa probable:** Cambio de esquema que requiere migración, variable de entorno faltante en Railway, o falla de infraestructura.

**Mitigación:** Revisar logs en Railway QA. Si es migración pendiente: ejecutar `prisma migrate deploy` manualmente en Railway.

---

### Riesgo 3 — Branch protection mal configurada bloquea PRs válidos

**Causa más común:** Agregar un status check cuyo job es `skipped` en eventos PR (como los builds de Android).

**Cómo verificar:** Antes de agregar un status check como requerido, confirmar en la pestaña Actions que ese check aparece con ✅ (no con ⊘ skipped) en PRs.

**Resolución:** Remover el check problemático desde Settings → Branches → editar la regla.

---

### Recomendación 1 — Configurar gradualmente

1. Configurar `dev` primero (menor riesgo, fácil de ajustar)
2. Validar que los PRs normales no quedan bloqueados
3. Configurar `qa`
4. Validar
5. Configurar `main`

---

### Recomendación 2 — Proceso de emergencia (bypass)

Para incidentes críticos de producción, los administradores pueden crear un bypass temporal:

```txt
Settings → Branches → main → Edit
Desactivar temporalmente "Include administrators"
→ hacer el merge de emergencia
→ volver a activar "Include administrators" inmediatamente
```

Documentar el bypass en el commit message o en una issue.

---

### Recomendación 3 — Agregar builds a PRs en el futuro

Cuando el equipo crezca o cuando los builds rotos post-merge sean un problema recurrente, actualizar los workflows para que los builds también corran en PRs. Esto mejora la detección temprana pero aumenta el tiempo de CI.

---

## Validaciones para cerrar la etapa

```txt
Mobile Repository
□ Branch protection configurada en dev
□ Branch protection configurada en qa
□ Branch protection configurada en main

Backend Repository
□ Branch protection configurada en dev
□ Branch protection configurada en qa
□ Branch protection configurada en main

Funcionalidad
□ PR sin CI verde queda bloqueado (verificar en un PR de prueba)
□ PR con CI verde puede mergearse normalmente
□ Push directo a main bloqueado (verificar con git push forzado)
□ Administrador incluido en las reglas de main

Documentación
□ docs/branch-strategy.md creado y revisado
□ docs/cicd-governance.md creado y revisado
□ Documentación existente actualizada
```

---

## Documentos relacionados

- `docs/branch-strategy.md` — propósito de ramas, flujo de promoción, reglas
- `docs/cicd-mobile.md` — pipeline mobile (workflow, jobs, artifacts)
- `docs/cicd-backend.md` — pipeline backend (workflow, jobs, health check)
