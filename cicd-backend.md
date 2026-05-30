# Backend CI — TacosManager

Versión: 2.2
Etapa: 5.0.4.2 (pipeline) / 5.0.4.3 (branch protection)
Estado: ✅ COMPLETADA

---

# Objetivo

Validar automáticamente la calidad del backend NestJS en cada etapa del ciclo de promoción de ramas, y verificar el estado del servicio QA al promover código a ese ambiente.

El pipeline garantiza que:

- El código no tiene errores de lint
- El build TypeScript compila sin errores
- El schema Prisma es válido
- El backend desplegado en QA responde correctamente (solo en push a `qa`)

Esta etapa **no incluye** deploy automático, publicación de artefactos ni tests de integración con base de datos externa.

---

# Flujo de ramas oficial

```txt
feature/*
    ↓  (PR → dev)
   dev
    ↓  (PR → qa)
   qa
    ↓  (PR → main)
  main
```

El CI/CD está alineado con este flujo. Cada etapa tiene responsabilidades diferentes.

---

# Archivo del workflow

```txt
.github/workflows/backend-ci.yml
```

---

# Triggers

| Evento | Rama destino | Jobs ejecutados |
|--------|-------------|-----------------|
| `pull_request` | `dev` | `Backend • Lint, Build & Validate` |
| `pull_request` | `qa` | `Backend • Lint, Build & Validate` |
| `pull_request` | `main` | `Backend • Lint, Build & Validate` |
| `push` | `dev` | `Backend • Lint, Build & Validate` |
| `push` | `qa` | `Backend • Lint, Build & Validate` · `Backend • Health Check QA` |
| `push` | `main` | `Backend • Lint, Build & Validate` |

---

# Jobs

## Job: `Backend • Lint, Build & Validate`

Job ID: `validate` — Ejecutado en: todos los triggers.

```txt
1. Checkout del repositorio
2. Setup pnpm (latest)
3. Setup Node.js LTS con cache pnpm
4. pnpm install --frozen-lockfile
5. pnpm lint       ← ESLint sobre src/
6. pnpm build      ← nest build (compilación TypeScript)
7. prisma validate ← valida schema.prisma sin conexión a BD
```

Si cualquier paso falla → el workflow falla → el merge queda bloqueado (cuando branch protection esté configurada).

**Status check requerido en branch protection:** `Backend • Lint, Build & Validate`

## Job: `Backend • Health Check QA`

Job ID: `health-check-qa` — Ejecutado en: `push → qa` únicamente. Requiere que `validate` haya pasado.

```txt
8. Health Check QA
   GET $QA_API_URL/health
   Valida: { status: "ok" }
```

Si el health check falla → el workflow falla.

---

# Responsabilidades por rama

## dev

Rama de integración continua. Recibe merges de `feature/*`.

| Evento | Validaciones |
|--------|-------------|
| PR → dev | lint · build · prisma validate |
| push → dev | lint · build · prisma validate |

No hay health checks en `dev` — no existe un ambiente desplegado asociado.

## qa

Rama de staging. Recibe merges de `dev`.

| Evento | Validaciones |
|--------|-------------|
| PR → qa | lint · build · prisma validate |
| push → qa | lint · build · prisma validate · **Backend • Health Check QA** |

El Health Check QA vive aquí porque `qa` es el trigger de promoción al ambiente QA desplegado en Railway. Verificar el servicio **después del merge** — no antes — garantiza que el código que acaba de llegar al ambiente responde correctamente.

## main

Rama de producción. Recibe merges de `qa`.

| Evento | Validaciones |
|--------|-------------|
| PR → main | lint · build · prisma validate |
| push → main | lint · build · prisma validate |

El Production Health Check no está implementado todavía — se conectará cuando el ambiente de producción esté disponible. Ver sección **Production Health Check (futuro)**.

---

# Por qué QA Health Check vive en `qa` y no en `main`

El Health Check QA tiene como propósito verificar que el backend desplegado en Railway QA responde correctamente **después de que código nuevo llega a ese ambiente**.

El push a `qa` es el evento que dispara el despliegue a Railway QA. Por lo tanto, el health check debe ejecutarse en ese trigger — no en `main`, que corresponde a producción.

Ejecutar el Health Check QA en `main` sería conceptualmente incorrecto: validaría el ambiente QA en un momento en que el código de producción ya ha avanzado más allá de QA.

---

# Validaciones ejecutadas

## Lint

Script: `pnpm lint`

Ejecuta ESLint sobre `{src,apps,libs,test}/**/*.ts`.

El linter usa `--fix` internamente: auto-corrige lo que puede y falla con código de salida 1 si hay errores no corregibles.

## Build

Script: `pnpm build`

Ejecuta `nest build` (compilación TypeScript completa a `dist/`).

No requiere `DATABASE_URL` ni otras variables de entorno — la validación de ConfigModule solo ocurre en runtime.

## Prisma validate

Comando: `pnpm exec prisma validate`

Valida el archivo `prisma/schema.prisma` para errores de sintaxis y semántica.

No realiza conexión a base de datos real. Sin embargo, tanto `prisma validate` como `prisma generate` (ejecutado en `postinstall`) leen `prisma.config.ts`, que contiene:

```ts
datasource: {
  url: env('DATABASE_URL'),
}
```

La función `env()` de Prisma lanza `PrismaConfigEnvError` si la variable no está definida en el entorno — incluso si el comando no abre ninguna conexión. Por esto el workflow define una `DATABASE_URL` dummy a nivel de job (ver sección **DATABASE_URL en CI**).

## Health Check QA

Endpoint: `GET $QA_API_URL/health`

Respuesta esperada:

```json
{
  "status": "ok",
  "timestamp": "2026-05-27T12:00:00.000Z",
  "environment": "qa"
}
```

Validación: `status === "ok"`.

Si el endpoint no es alcanzable o devuelve un `status` distinto de `"ok"`, el workflow falla.

---

# Production Health Check (futuro)

Pendiente de infraestructura. Se implementará cuando el ambiente de producción en Railway esté disponible.

Estructura prevista:

| Parámetro | Valor |
|-----------|-------|
| Trigger | `push → main` |
| Variable | `PROD_API_URL` (GitHub Variables) |
| Endpoint | `GET $PROD_API_URL/health` |
| Validación | `status === "ok"` |

El placeholder está documentado en `.github/workflows/backend-ci.yml` como comentario. Para activarlo: agregar el job `health-check-prod` con `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` y `needs: validate`.

---

# Variables requeridas en GitHub

## Variables de repositorio (Settings → Secrets and variables → Actions → Variables)

| Variable | Descripción | Cuándo se usa |
|----------|-------------|---------------|
| `QA_API_URL` | URL base del backend en Railway QA (ej. `https://tacos-manager-api-qa.up.railway.app`) | Push a `qa` — Health Check QA |

**No incluir** `/health` en el valor de la variable. El workflow lo agrega automáticamente.

## Secrets

Esta etapa no requiere secrets adicionales. No hay firma de artefactos ni conexión a bases de datos externas.

---

# DATABASE_URL en CI

## Por qué se necesita

`prisma generate` (llamado desde `postinstall` al ejecutar `pnpm install`) y `prisma validate` leen `prisma.config.ts` antes de cualquier operación. Ese archivo llama `env('DATABASE_URL')`, y Prisma lanza `PrismaConfigEnvError` si la variable no está definida — incluso cuando no se establece ninguna conexión real.

## Solución implementada

El workflow define `DATABASE_URL` como variable de entorno a nivel de job con un valor dummy:

```yaml
env:
  DATABASE_URL: postgresql://prisma:prisma@localhost:5432/ci_dummy
```

## Por qué es seguro

- `prisma generate` genera el cliente TypeScript leyendo el schema — no abre conexiones.
- `prisma validate` analiza la sintaxis del schema — no abre conexiones.
- `pnpm lint` y `pnpm build` no usan `DATABASE_URL`.
- El valor apunta a `localhost` — nunca alcanza ningún servidor externo.
- Railway, QA y Producción definen su propia `DATABASE_URL` real en sus entornos — este valor dummy no los afecta.

## Por qué no se usa Secret de GitHub

El valor es intencionalmente falso y sin credenciales reales. Hardcodearlo en el workflow hace evidente su propósito (CI dummy) sin añadir complejidad operativa.

---

# Configuración en el runner

| Componente | Valor |
|------------|-------|
| Runner | `ubuntu-latest` |
| Node.js | LTS (`lts/*`) |
| pnpm | `latest` |
| Cache | pnpm store (keyed por `pnpm-lock.yaml`) |
| `DATABASE_URL` | `postgresql://prisma:prisma@localhost:5432/ci_dummy` (dummy, sin conexión real) |
| jq | Pre-instalado en ubuntu-latest |

---

# Lecciones aprendidas

## prisma.config.ts requiere DATABASE_URL aunque no haya conexión

`prisma generate` y `prisma validate` cargan `prisma.config.ts` antes de ejecutar. La función `env('DATABASE_URL')` lanza `PrismaConfigEnvError` si la variable no está definida — incluso cuando no se abre ninguna conexión real. La solución es definir un valor dummy en el entorno del job.

## postinstall como vector de fallo silencioso en CI

El script `postinstall` en `package.json` ejecuta `prisma generate` automáticamente durante `pnpm install`. En entornos CI sin variables completas, el fallo ocurre en el paso de instalación (no en "Prisma validate"), lo que puede resultar confuso al diagnosticar. Anticipar las dependencias implícitas de los hooks de `package.json` es crítico al configurar CI.

## El Health Check QA pertenece a `push → qa`, no a `push → main`

El diseño original ejecutaba el health check en `push → main`. Esto es semánticamente incorrecto: `main` corresponde a producción, y validar el ambiente QA desde ese trigger desacopla la verificación del momento en que el código llega al ambiente. El trigger correcto es `push → qa`.

## DATABASE_URL dummy no debe ser Secret de GitHub

Un Secret enmascara el valor en los logs y agrega fricción operativa sin beneficio de seguridad cuando el valor es intencionalmente falso. Hardcodearlo en el workflow lo hace auto-documentado y explícito para quien revise el pipeline.

---

# Troubleshooting

## Install falla: PrismaConfigEnvError

**Síntoma:** El paso `Install dependencies` falla con:

```txt
PrismaConfigEnvError: Cannot resolve environment variable DATABASE_URL
```

**Causa:** `postinstall` ejecuta `prisma generate`, que lee `prisma.config.ts`. La función `env('DATABASE_URL')` de Prisma lanza este error si la variable no está definida en el entorno del runner.

**Solución:** Verificar que el job `validate` tiene definida la variable `DATABASE_URL` (valor dummy) en la sección `env:`. Ver sección **DATABASE_URL en CI**.

---

## Lint falla

**Síntoma:** El paso `Lint` falla con errores de ESLint.

**Causa:** Hay errores de lint en el código que no pueden ser auto-corregidos.

**Solución:** Corregir el error en el archivo y línea indicados por ESLint.

---

## Build falla

**Síntoma:** El paso `Build` falla con errores de TypeScript.

**Causa:** Error de compilación TypeScript en el código.

**Solución:** Corregir el error de tipos indicado en la traza del compilador.

---

## Prisma validate falla

**Síntoma:** El paso `Prisma validate` falla.

**Causa:** El archivo `prisma/schema.prisma` tiene errores de sintaxis o semántica.

**Solución:** Revisar el schema.prisma y corregir el error indicado.

---

## Health Check falla: endpoint no alcanzable

**Síntoma:** `Health check fallido: el endpoint no es alcanzable o devolvió un error HTTP`

**Causas posibles:**
- El servicio Railway QA está caído o reiniciando
- La variable `QA_API_URL` tiene un valor incorrecto
- Railway no ha terminado de desplegar la última versión

**Solución:**
1. Verificar que `QA_API_URL` está correctamente configurada en GitHub Variables
2. Verificar el estado del servicio en el dashboard de Railway
3. Intentar acceder manualmente a `$QA_API_URL/health` desde un navegador

---

## Health Check falla: status != ok

**Síntoma:** `Health check fallido: se esperaba status=ok, se obtuvo status=<otro>`

**Causa:** El endpoint responde pero el backend no está en estado saludable.

**Solución:** Revisar los logs del servicio Railway QA para identificar el error.

---

## QA_API_URL no configurada

**Síntoma:** `QA_API_URL no está configurada en las variables del repositorio de GitHub`

**Causa:** La variable `QA_API_URL` no existe en las variables del repositorio.

**Solución:** Configurar la variable en GitHub → Settings → Secrets and variables → Actions → Variables → New repository variable.

---

## El workflow no se activa en PR hacia `dev`

**Síntoma:** Se abre un PR de `feature/*` hacia `dev` pero el workflow no se ejecuta.

**Causa:** El trigger `pull_request` del workflow especifica `branches: [dev, qa, main]`. Si la rama base del PR es diferente (ej. `develop`, `staging`), el workflow no se activa.

**Solución:** Verificar que la rama base del PR coincide exactamente con `dev`, `qa` o `main`.

---

# Checklist de mantenimiento

```txt
□ Al cambiar la URL del servicio Railway QA → actualizar QA_API_URL en GitHub Variables
□ Al crear el ambiente de producción → implementar health-check-prod en el workflow
□ Al agregar PROD_API_URL → configurarla en GitHub Variables (no Secret)
□ Al actualizar la versión de pnpm en el proyecto → verificar que el workflow sigue pasando
□ Al actualizar Node.js en el proyecto → actualizar node-version en el workflow si es necesario
□ Al agregar nuevas reglas ESLint → verificar que pnpm lint sigue pasando en CI
□ Al renombrar ramas (dev/qa/main) → actualizar los triggers del workflow
□ Periódicamente verificar que ubuntu-latest sigue teniendo jq pre-instalado
```

---

# Casos de prueba manuales

## 1. Verificar que PR hacia `dev` ejecuta validaciones

```txt
1. Crear un branch feature/* con cualquier cambio
2. Abrir un Pull Request hacia dev
3. Ir a GitHub → pestaña Actions
4. Confirmar que "Backend CI" aparece y ejecuta el job "Backend • Lint, Build & Validate"
5. Todos los pasos deben pasar (verde ✅)
6. El job "Backend • Health Check QA" NO debe aparecer
```

## 2. Verificar que PR hacia `qa` ejecuta validaciones

```txt
1. Abrir un Pull Request de dev hacia qa
2. Ir a GitHub → pestaña Actions
3. Confirmar que "Backend • Lint, Build & Validate" pasa
4. El job "Backend • Health Check QA" NO debe ejecutarse (solo se activa en push, no en PR)
```

## 3. Verificar que push a `qa` ejecuta Health Check QA

```txt
1. Hacer merge de un PR hacia qa
2. Ir a GitHub → pestaña Actions
3. Confirmar que se ejecutan ambos jobs: "Backend • Lint, Build & Validate" y "Backend • Health Check QA"
4. Confirmar que "Backend • Health Check QA" pasa (verde ✅)
```

## 4. Verificar que push a `main` NO ejecuta Health Check QA

```txt
1. Hacer merge de un PR hacia main
2. Ir a GitHub → pestaña Actions
3. Confirmar que solo se ejecuta "Backend • Lint, Build & Validate"
4. El job "Backend • Health Check QA" NO debe aparecer
```

## 5. Verificar que lint falla correctamente

```txt
1. Crear un branch con un error de lint no auto-corregible
2. Abrir un PR hacia dev (o qa o main)
3. Confirmar que el paso "Lint" falla (rojo ❌)
4. Confirmar que el merge queda bloqueado (si branch protection está configurada)
```

## 6. Verificar health check manual

```txt
1. Obtener la URL del servicio Railway QA
2. Ejecutar: curl -s $QA_API_URL/health
3. Confirmar que la respuesta es: { "status": "ok", ... }
```

---

# Branch Protection

Estado: ✅ CONFIGURADA (2026-05-29) — GitHub Rulesets activos en dev, qa y main.

El nombre exacto del status check configurado en los Rulesets:

```txt
Backend • Lint, Build & Validate
```

Reglas activas: Require Pull Request · Require status checks · Block force pushes · Restrict deletions.

Aplica en dev, qa y main del repositorio Backend.

Configuración completa: ver `docs/cicd-governance.md`

Estrategia de ramas: ver `docs/branch-strategy.md`
