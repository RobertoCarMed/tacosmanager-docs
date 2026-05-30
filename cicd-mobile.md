# TacosManager — Mobile CI/CD

Version: 1.1
Última actualización: ETAPA 5.0.4.1 — Mobile Pipeline Optimization ✅ COMPLETADA (2026-05-28)

---

## Archivo de workflow

```txt
.github/workflows/mobile-ci.yml
```

---

## Estrategia de ramas

```txt
feature/*
    ↓ Pull Request
   dev
    ↓ Push / Pull Request
   qa
    ↓ Push / Pull Request
  main
```

### Responsabilidad de cada rama

| Rama | Propósito |
|------|-----------|
| `feature/*` | Desarrollo de funcionalidades. No tiene pipeline propio — solo se integra vía PR hacia `dev`. |
| `dev` | Integración continua. Recibe PRs de `feature/*`. Ejecuta validación de código. No genera artefactos. |
| `qa` | Validación funcional. Recibe PRs y merges de `dev`. Genera APK QA para pruebas en dispositivo. |
| `main` | Producción. Recibe PRs y merges de `qa`. Genera APK QA + AAB de producción para Play Store. |

---

## Jobs del pipeline

```txt
Mobile • Lint & TypeCheck
        ↓
Mobile • Build QA APK
        ↓
Mobile • Build Production AAB
```

### Dependencias

```txt
lint-typecheck  ← sin dependencias
build-qa        ← needs: lint-typecheck
build-production ← needs: build-qa
```

---

## Estrategia de ejecución por evento

| Evento | Lint & TypeCheck | Build QA APK | Build Production AAB |
|--------|:---:|:---:|:---:|
| PR → dev | ✅ | — | — |
| PR → qa | ✅ | — | — |
| PR → main | ✅ | — | — |
| Push → dev | ✅ | — | — |
| Push → qa | ✅ | ✅ + artifact | — |
| Push → main | ✅ | ✅ + artifact | ✅ + artifact |

**Objetivo de PR (validación rápida):** lint + typecheck únicamente — sin compilar APK ni AAB. Permite revisión de código sin consumir runners de compilación.

**Objetivo de push a dev:** igual que PR — validación de código. No hay artefactos.

**Objetivo de push a qa:** genera APK QA instalable para pruebas funcionales en dispositivo real.

**Objetivo de push a main:** pipeline completo — APK QA (regresión) + AAB producción (listo para Play Store).

---

## Artefactos generados

| Job | Artefacto | Trigger | Retención |
|-----|-----------|---------|-----------|
| Build QA APK | `app-qa-release-<sha>.apk` | push → qa, push → main | 30 días |
| Build Production AAB | `app-production-release-<sha>.aab` | push → main | 30 días |

Descarga: GitHub → Actions → workflow run → sección Artifacts.

---

## Estrategia de ambientes

Los archivos `.env.qa` y `.env.production` se generan dinámicamente en cada ejecución del workflow.

Las URLs se leen desde **GitHub Repository Variables** — sin valores hardcodeados en el workflow.

### Build QA

```yaml
printf 'API_URL=%s\nSOCKET_URL=%s\nENVIRONMENT=qa\n' \
  "${{ vars.QA_API_URL }}" "${{ vars.QA_SOCKET_URL }}" > .env.qa
```

### Build Production

```yaml
printf 'API_URL=%s\nSOCKET_URL=%s\nENVIRONMENT=production\n' \
  "${{ vars.PROD_API_URL }}" "${{ vars.PROD_SOCKET_URL }}" > .env.production
```

---

## GitHub Repository Variables requeridas

Configurar en: `GitHub → Settings → Secrets and variables → Actions → Variables`

| Variable | Descripción | Ejemplo QA | Ejemplo Production |
|----------|-------------|------------|-------------------|
| `QA_API_URL` | URL base del backend QA | `https://api-qa.tacosmanager.up.railway.app` | — |
| `QA_SOCKET_URL` | URL del servidor Socket.IO QA | `https://api-qa.tacosmanager.up.railway.app` | — |
| `PROD_API_URL` | URL base del backend Production | — | `https://api.tacosmanager.up.railway.app` |
| `PROD_SOCKET_URL` | URL del servidor Socket.IO Production | — | `https://api.tacosmanager.up.railway.app` |

Las variables son visibles en los logs del workflow (no son secretas). Solo almacenar URLs, nunca credenciales.

### Ejemplo de configuración QA

```txt
Nombre: QA_API_URL
Valor:  https://api-qa.tacosmanager.up.railway.app

Nombre: QA_SOCKET_URL
Valor:  https://api-qa.tacosmanager.up.railway.app
```

### Ejemplo de configuración Production

```txt
Nombre: PROD_API_URL
Valor:  https://api.tacosmanager.up.railway.app

Nombre: PROD_SOCKET_URL
Valor:  https://api.tacosmanager.up.railway.app
```

---

## GitHub Secrets requeridos

Configurar en: `GitHub → Settings → Secrets and variables → Actions → Secrets`

| Secret | Descripción |
|--------|-------------|
| `KEYSTORE_PASSWORD` | `MYAPP_UPLOAD_STORE_PASSWORD` del keystore |
| `KEY_PASSWORD` | `MYAPP_UPLOAD_KEY_PASSWORD` del keystore |

El archivo `android/app/tacosmanager.keystore` está en el repositorio.
El alias `tacosmanager-key` es público en `gradle.properties`.

---

## Estrategia de cache

### Node (npm)

`actions/setup-node@v4` con `cache: npm` cachea `node_modules` basado en el contenido del `package-lock.json`.

- Aplica en todos los jobs.
- Evita `npm ci` completo cuando las dependencias no cambian.

### Gradle + Android SDK

`gradle/actions/setup-gradle@v4` cachea:

- Dependencias Gradle (`~/.gradle/caches`)
- Wrapper de Gradle (`~/.gradle/wrapper`)
- Build tools de Android

Aplica solo en los jobs de build (build-qa, build-production).

El job `lint-typecheck` no instala Java ni Gradle — tiempo de ejecución significativamente menor.

---

## Manejo de errores

Cada paso crítico emite una anotación clara visible en la pestaña Actions:

| Paso | Mensaje de error |
|------|-----------------|
| Lint | `::error::Lint failed — fix all ESLint errors before merging` |
| TypeCheck | `::error::TypeCheck failed — fix all TypeScript errors before merging` |
| Build QA APK | `::error::QA APK build failed — review Gradle output above for details` |
| Build Production AAB | `::error::Production AAB build failed — review Gradle output above for details` |

### Diagnóstico de fallos frecuentes

| Fallo | Causa probable | Solución |
|-------|----------------|---------|
| Lint falla | Error ESLint | Corregir en el archivo indicado en el log |
| TypeCheck falla | Error de tipos TypeScript | Corregir el tipo indicado en la traza |
| Build QA falla (signing) | Secrets no configurados | Agregar `KEYSTORE_PASSWORD` y `KEY_PASSWORD` |
| Build QA falla (Gradle) | Dependencia o error de compilación | Revisar logs Gradle en el step |
| Build QA falla (env) | Variables QA no configuradas | Verificar `QA_API_URL` y `QA_SOCKET_URL` en Variables |
| Build Production falla | Depende de Build QA exitoso | Resolver Build QA primero |
| Build Production falla (env) | Variables PROD no configuradas | Verificar `PROD_API_URL` y `PROD_SOCKET_URL` en Variables |

---

## Composite Action — Decisión

**No implementada.**

Los jobs `build-qa` y `build-production` comparten un patrón de setup de 4 pasos (Java, Node, Gradle, npm ci). Con solo dos usos, el overhead de mantener un archivo `action.yml` adicional, la complejidad de inputs/outputs, y la referencia cruzada no aportan valor neto. El setup es idéntico, corto, y legible inline.

Reevaluar si se agregan más de 3 jobs de build en el futuro.

---

## Compatibilidad con Branch Protection

Los nombres de los jobs están diseñados para ser usados directamente como **required status checks** en GitHub.

### Status check usable en PR (branch protection)

```txt
Mobile • Lint & TypeCheck       ← corre en todos los PR y push
```

### Quality gates post-merge (no configurables como checks de PR)

```txt
Mobile • Build QA APK           ← solo en push a qa y main (skipped en PR)
Mobile • Build Production AAB   ← solo en push a main (skipped en PR)
```

Los jobs de build son `skipped` en eventos `pull_request` — requerirlos como status checks de PR bloquearía todos los PRs. Son quality gates que corren post-merge.

### Configuración implementada — GitHub Rulesets (✅ 2026-05-29)

| Rama | Required Status Check (PR) | Quality gate post-merge |
|------|---------------------------|------------------------|
| `dev` | `Mobile • Lint & TypeCheck` | lint + typecheck |
| `qa` | `Mobile • Lint & TypeCheck` | + APK QA |
| `main` | `Mobile • Lint & TypeCheck` | + APK QA + AAB Production |

Reglas activas: Require Pull Request · Require status checks · Block force pushes · Restrict deletions.

Configuración completa: `docs/cicd-governance.md`

Estrategia de ramas: `docs/branch-strategy.md`

---

## Mantenimiento del pipeline

```txt
□ Al cambiar API URLs de QA → actualizar variable QA_API_URL en GitHub Settings
□ Al cambiar API URLs de PROD → actualizar variable PROD_API_URL en GitHub Settings
□ Al renovar el keystore → actualizar los secrets KEYSTORE_PASSWORD y KEY_PASSWORD
□ Al rotar contraseñas del keystore → actualizar KEYSTORE_PASSWORD y KEY_PASSWORD
□ Al actualizar compileSdkVersion o buildToolsVersion → verificar compatibilidad con ubuntu-latest
□ Al agregar nuevas dependencias → verificar que el cache Gradle sigue funcionando
□ Periódicamente revisar retención de artefactos (30 días actualmente)
□ Al agregar nuevas ramas protegidas → revisar triggers del workflow
```

---

## Compatibilidad con stack existente

El pipeline no modifica ninguna de estas configuraciones:

```txt
✅ versionCode / versionName   — android/app/build.gradle (sin cambios)
✅ productFlavors              — development / qa / production (sin cambios)
✅ google-services             — android/app/google-services.json (sin cambios)
✅ Firebase Storage            — @react-native-firebase/storage (sin cambios)
✅ Android signing             — signingConfig.release (sin cambios)
✅ tacosmanager.keystore       — android/app/ (sin cambios)
✅ react-native-config         — dotenv.gradle + envConfigFiles (sin cambios)
✅ Scripts npm                 — build:android:qa, build:android:prod (sin cambios)
```

---

## Validaciones — ETAPA 5.0.4.1 ✅

Validaciones ejecutadas en GitHub Actions el 2026-05-28:

### Pull Requests (feature→dev, dev→qa, qa→main)

```txt
✅ Mobile • Lint & TypeCheck  — ejecutado
✅ Mobile • Build QA APK      — NO ejecutado (correcto)
✅ Mobile • Build Production AAB — NO ejecutado (correcto)
```

### Push a dev

```txt
✅ Mobile • Lint & TypeCheck  — ejecutado
✅ Mobile • Build QA APK      — NO ejecutado (correcto)
```

### Push a qa

```txt
✅ Mobile • Lint & TypeCheck  — ejecutado
✅ Mobile • Build QA APK      — ejecutado
✅ APK QA artifact            — generado y disponible
✅ Mobile • Build Production AAB — NO ejecutado (correcto)
```

### Push a main

```txt
✅ Mobile • Lint & TypeCheck      — ejecutado
✅ Mobile • Build QA APK          — ejecutado
✅ Mobile • Build Production AAB  — ejecutado
✅ APK QA artifact                — generado
✅ AAB Production artifact        — generado
```

### Variables y ambientes

```txt
✅ QA_API_URL / QA_SOCKET_URL       — configuradas y consumidas correctamente
✅ PROD_API_URL / PROD_SOCKET_URL   — configuradas y consumidas correctamente
✅ .env.qa generado dinámicamente   — sin URLs hardcodeadas
✅ .env.production generado dinámicamente — sin URLs hardcodeadas
```

### Cache y artefactos

```txt
✅ npm cache operativo (por package-lock.json)
✅ Gradle cache operativo (dependencias Android)
✅ lint-typecheck sin Java/Gradle — ejecución más rápida
✅ Retención 30 días en ambos artefactos
```

---

## Lecciones aprendidas

### Submodule en detached HEAD

Al trabajar con submódulos en detached HEAD y luego hacer `git checkout main` con cambios pendientes, se generan conflictos de merge con commits previos. Solución correcta: verificar que el submódulo esté en la rama `main` antes de iniciar cambios, o hacer `git stash` antes de cambiar de rama y resolver conflictos manualmente partiendo del estado upstream.

### Estrategia `needs` + `if` en GitHub Actions

Para ejecución condicional por rama con jobs dependientes:
- La condición `if` en un job se evalúa de forma independiente al resultado del `needs`.
- Si el job necesitado es saltado (`skipped`), el dependiente también se salta por defecto.
- Para push a main: los 3 jobs corren en cascada. Para push a qa: solo los primeros 2. Para PRs/dev: solo el primero.
- El diseño evita la necesidad de condiciones `if: always()` o manejo explícito de `skipped`.

### Repository Variables vs Secrets

Las Repository Variables son la herramienta correcta para URLs de ambiente: visibles en logs, editables sin rotación, sin aprobación de org. Los Secrets se reservan para credenciales sensibles (contraseñas de keystore). Esta separación es semánticamente correcta y reduce la fricción operativa al cambiar de infraestructura.
```
