# TacosManager — Branch Strategy

Version: 1.1
Última actualización: ETAPA 5.0.4.3 — Branch Protection & Status Checks ✅ COMPLETADA (2026-05-29)

---

## Flujo oficial

```txt
feature/*
    ↓ Pull Request → dev
   dev
    ↓ Pull Request → qa
   qa
    ↓ Pull Request → main
  main
```

Cada flecha representa un Pull Request: no se hace push directo a ramas compartidas.

---

## Propósito de cada rama

### feature/*

Propósito: Desarrollo individual de una funcionalidad o corrección.

Convención de nombre: `feature/<etapa>-<descripcion-corta>`

Ejemplos:
```txt
feature/5.0.4.1-mobile-pipeline-optimization
feature/4.8-history-filters
feature/fix-kitchen-queue-order
```

Lifecycle: La rama existe mientras se desarrolla la funcionalidad. Se elimina después del merge a `dev`.

Protección: Sin protección. El desarrollador tiene control total.

CI ejecutado: Ninguno (el CI corre al abrir PR hacia `dev`).

---

### dev

Propósito: Integración continua. Punto de convergencia de `feature/*` branches.

Reglas:
- Solo recibe merges de `feature/*` via Pull Request
- Nunca se mergea directamente desde `main` o `qa` hacia atrás (hotfixes van por el flujo normal)
- Es la rama más activa del repositorio

CI ejecutado en PR:
- Mobile: `Mobile • Lint & TypeCheck`
- Backend: `Backend • Lint, Build & Validate`

CI ejecutado en push (post-merge):
- Mobile: `Mobile • Lint & TypeCheck`
- Backend: `Backend • Lint, Build & Validate`

Sin artefactos generados. Sin despliegues automáticos.

---

### qa

Propósito: Staging. Representa el estado del ambiente QA desplegado en Railway.

Reglas:
- Solo recibe merges de `dev` via Pull Request
- Un merge a `qa` puede disparar un despliegue al ambiente Railway QA
- Sirve como punto de validación funcional antes de producción
- El código en `qa` debe estar validado por el equipo

CI ejecutado en PR:
- Mobile: `Mobile • Lint & TypeCheck`
- Backend: `Backend • Lint, Build & Validate`

CI ejecutado en push (post-merge):
- Mobile: `Mobile • Lint & TypeCheck` + `Mobile • Build QA APK` + artifact
- Backend: `Backend • Lint, Build & Validate` + Health Check QA

Artefacto generado: `app-qa-release-<sha>.apk` (disponible en GitHub Actions → Artifacts).

---

### main

Propósito: Producción. Representa el estado del sistema desplegado en Railway Production.

Reglas:
- Solo recibe merges de `qa` via Pull Request
- Todo lo que llega a `main` ha sido validado en QA
- Un merge a `main` puede disparar un despliegue a Railway Production
- Los artefactos de producción se generan en cada push a `main`

CI ejecutado en PR:
- Mobile: `Mobile • Lint & TypeCheck`
- Backend: `Backend • Lint, Build & Validate`

CI ejecutado en push (post-merge):
- Mobile: pipeline completo (lint + APK QA + AAB Production + ambos artifacts)
- Backend: `Backend • Lint, Build & Validate`

Artefactos generados:
- `app-qa-release-<sha>.apk`
- `app-production-release-<sha>.aab` (para Play Store)

---

## Flujo de promoción

```txt
1. Desarrollador crea feature/* desde dev
2. Desarrollador implementa cambios en feature/*
3. Desarrollador abre PR: feature/* → dev
4. CI corre (lint + typecheck) — debe ser verde
5. [Opcional] Revisión del PR
6. Merge a dev
7. [CI post-merge corre en dev]

8. Desarrollador abre PR: dev → qa
9. CI corre (lint + typecheck) — debe ser verde
10. Revisión del PR (recomendada)
11. Merge a qa
12. CI post-merge corre en qa: build APK QA + health check
13. QA funcional con APK generado

14. Desarrollador abre PR: qa → main
15. CI corre (lint + typecheck) — debe ser verde
16. Revisión del PR (obligatoria recomendada)
17. Merge a main
18. CI post-merge corre en main: build APK QA + AAB Production
19. AAB disponible para Play Store
```

---

## Reglas de merge

### Prohibido

```txt
✗ Push directo a main, qa o dev sin PR
✗ Merge de feature/* directamente a qa o main
✗ Merge de main o qa de vuelta a dev (evita divergencia)
✗ Force-push en ramas compartidas (dev, qa, main)
✗ Merge sin CI verde en las ramas con branch protection
```

### Permitido

```txt
✓ Merge a dev con CI verde (review opcional en equipo pequeño)
✓ Merge a qa con CI verde + review recomendada
✓ Merge a main con CI verde + review obligatoria (recomendada)
✓ Fix urgente en qa o main via PR (no bypass de protection)
```

---

## Status checks requeridos por rama

Los status checks se verifican en el momento del PR. Los builds corren post-merge.

| Rama | Status checks requeridos en PR | Builds post-merge |
|------|-------------------------------|-------------------|
| `dev` | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` | Lint + typecheck |
| `qa` | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` | + APK QA + Health Check QA |
| `main` | `Mobile • Lint & TypeCheck` · `Backend • Lint, Build & Validate` | + APK QA + AAB Production |

Implementado con GitHub Rulesets el 2026-05-29. Para la configuración completa: ver `docs/cicd-governance.md`.

---

## Ambientes asociados

| Rama | Ambiente | Infraestructura | URL |
|------|----------|-----------------|-----|
| `feature/*` | Local | Máquina del desarrollador | localhost:3000 |
| `dev` | Sin ambiente desplegado | — | — |
| `qa` | Railway QA | PostgreSQL Railway QA | Variable: `QA_API_URL` |
| `main` | Railway Production | PostgreSQL Railway Prod | Variable: `PROD_API_URL` |

---

## Documentos relacionados

- `docs/cicd-strategy.md` — convenciones completas (commits, PRs, hotfix, ambientes, IA)
- `docs/contributing.md` — guía de onboarding para nuevos contribuidores
- `docs/deployment-runbook.md` — runbooks de deploy, rollback y emergencias
- `docs/cicd-mobile.md` — pipeline mobile completo
- `docs/cicd-backend.md` — pipeline backend completo
- `docs/cicd-governance.md` — branch protection y status checks
