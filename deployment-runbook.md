# TacosManager — Deployment Runbook

Version: 1.0
Etapa: 5.0.4.4 — CI/CD Conventions & Documentation 🟡 EN PROGRESO

---

## Infraestructura

| Componente | Proveedor | Ambiente |
|------------|-----------|----------|
| Backend API | Railway | QA + Production |
| PostgreSQL | Railway | QA + Production (instancias separadas) |
| Mobile builds | GitHub Actions | APK QA + AAB Production |
| Firebase Storage | Firebase | Imágenes de productos (todos los ambientes) |

---

## 1. Deploy Backend a QA

**Trigger automático:** Railway detecta push a `qa` y redespliega.

**Prerrequisito:** El backend-ci.yml debe pasar (✅ `Backend • Lint, Build & Validate`).

### Pasos

```txt
1. Asegurarse de que dev está en el estado que se quiere promover
2. Abrir PR: dev → qa en GitHub (tacos-manager-api)
3. Esperar CI verde: Backend • Lint, Build & Validate ✅
4. Review del PR (1 persona)
5. Merge del PR
6. Railway detecta el push a qa y lanza el redespliegue automáticamente
7. Esperar que el deploy complete en Railway dashboard
8. Verificar: GET $QA_API_URL/health → { "status": "ok", "environment": "qa" }
9. Verificar el job Backend • Health Check QA en GitHub Actions (debe ser verde)
```

### Verificación post-deploy

```bash
curl -s https://<qa-url>.up.railway.app/health
# Respuesta esperada:
# { "status": "ok", "timestamp": "...", "environment": "qa" }
```

### Si el deploy falla

```txt
1. Abrir Railway dashboard → proyecto QA → pestaña Deployments
2. Ver logs del deploy fallido
3. Causa más común: migración pendiente de Prisma
   → Railway console: pnpm exec prisma migrate deploy
4. Causa alternativa: variable de entorno faltante
   → Railway: Settings → Variables → verificar DATABASE_URL, JWT_SECRET
5. Forzar redespliegue desde Railway si es necesario
```

---

## 2. Deploy Backend a Production

**Trigger automático:** Railway detecta push a `main` y redespliega.

**Prerrequisito:** El código pasó por QA (merge dev → qa → validación → main).

### Pasos

```txt
1. Asegurarse de que qa fue validada (smoke test en dispositivo)
2. Abrir PR: qa → main en GitHub (tacos-manager-api)
3. Esperar CI verde: Backend • Lint, Build & Validate ✅
4. Review del PR (1 persona — obligatorio)
5. Merge del PR
6. Railway detecta el push a main y lanza el redespliegue
7. Esperar que el deploy complete en Railway dashboard
8. Verificar: GET $PROD_API_URL/health → { "status": "ok", "environment": "production" }
```

### Verificación post-deploy

```bash
curl -s https://<prod-url>.up.railway.app/health
# Respuesta esperada:
# { "status": "ok", "timestamp": "...", "environment": "production" }
```

### Si el deploy falla en producción

Ver sección **Rollback Backend**.

---

## 3. Distribución APK QA (Mobile)

El APK QA se genera automáticamente en cada push a `qa` y `main`.

### Obtener el APK

```txt
1. GitHub → TacosManager → Actions
2. Seleccionar el workflow run del push a qa (o main)
3. Scroll hasta sección "Artifacts"
4. Descargar: app-qa-release-<sha>.zip
5. Extraer el .apk del .zip
```

### Instalar en dispositivo

```bash
# Opción 1: adb (dispositivo conectado por USB)
adb install app-qa-release-<sha>.apk

# Opción 2: compartir el APK por Google Drive / Slack / email
# El dispositivo destino debe tener "Instalar apps de fuentes desconocidas" habilitado
```

### Validar QA APK

```txt
□ Login con credenciales del ambiente QA
□ Crear orden DINE_IN con referencia
□ Crear orden DELIVERY con dirección
□ Ver orden en cocina en tiempo real
□ Cambiar estado de orden
□ Logout y login nuevamente
```

---

## 4. Subir AAB a Google Play Store

El AAB se genera en cada push a `main`.

### Obtener el AAB

```txt
1. GitHub → TacosManager → Actions
2. Seleccionar el workflow run del push a main
3. Scroll hasta sección "Artifacts"
4. Descargar: app-production-release-<sha>.zip
5. Extraer el .aab del .zip
```

### Subir a Play Store (Internal Testing)

```txt
1. Abrir Google Play Console
2. TacosManager → Testing → Internal Testing
3. Click: "Create new release"
4. Upload: app-production-release-<sha>.aab
5. Completar: Release name (ej: "1.0.0 — Build <sha corto>")
6. Completar: Release notes
7. Click: "Review release"
8. Click: "Start rollout to Internal Testing"
```

### Validar Production en Internal Testing

```txt
□ Instalar desde Play Store (Internal Testing track)
□ Login con credenciales de producción
□ Verificar que ENV.ENVIRONMENT === "production"
□ Verificar que API_URL apunta a Railway Production
□ Flujo completo: órdenes, cocina, realtime
```

---

## 5. Rollback Backend

### Rollback automático (Railway)

```txt
1. Railway dashboard → proyecto (QA o Production)
2. Pestaña "Deployments"
3. Encontrar el último deploy exitoso
4. Click: "Redeploy" en ese deployment
5. Esperar que el rollback complete
6. Verificar health check
```

### Rollback via git

```txt
1. Identificar el commit al que rollback (git log)
2. Crear rama: hotfix/rollback-to-<sha>
3. git revert <commit-problemático> (NO usar git reset en ramas compartidas)
4. PR hotfix/rollback-to-<sha> → main
5. Merge (revisión de emergencia)
6. Railway redespliega automáticamente
```

### Cuándo usar rollback automático vs git

| Situación | Método recomendado |
|-----------|-------------------|
| Bug en el último deploy, fix rápido no está listo | Rollback automático en Railway |
| Múltiples commits problemáticos | git revert + PR de hotfix |
| Fix ya está en una rama | Hotfix PR directo a main |

---

## 6. Procedimientos de emergencia

### Backend no responde (health check falla)

```txt
1. Verificar Railway dashboard: ¿el servicio está corriendo?
2. Ver logs en Railway → buscar error de startup (DATABASE_URL, JWT_SECRET)
3. Si es variable faltante: Settings → Variables → agregar variable → redeploy
4. Si es error de código: rollback a último deploy exitoso
5. Si Railway tiene outage: revisar status.railway.app
```

### Mobile build falla post-merge a main

```txt
1. GitHub → Actions → ver el job fallido (Build QA APK o Build Production AAB)
2. Expandir el step fallido → leer error de Gradle
3. Causa más común: error de TypeScript o ESLint que pasó lint/typecheck
   (los scripts de build ejecutan lint + typecheck nuevamente)
4. Causa alternativa: problema con el keystore o secrets
   → verificar KEYSTORE_PASSWORD y KEY_PASSWORD en GitHub Secrets
5. Abrir PR de fix en la rama afectada (qa o main)
```

### CI bloqueado en un PR (status check no pasa)

```txt
1. Abrir el PR → pestaña "Checks"
2. Click en el check fallido → ver detalles del error
3. Corregir en la rama del PR
4. El CI se vuelve a ejecutar automáticamente al pushear
```

### Branch protection bloquea un merge urgente

Solo para admins, como último recurso:

```txt
1. GitHub → Settings → Rules → Rulesets
2. Temporalmente deshabilitar el ruleset afectado
3. Hacer el merge
4. Re-habilitar el ruleset INMEDIATAMENTE
5. Documentar la excepción en el commit message o en una issue
```

---

## 7. Checklist pre-release

### Antes de mergear a qa

```txt
□ Tests manuales en dev flavor (o emulador con .env.development)
□ CI verde en el PR (Mobile • Lint & TypeCheck)
□ No hay errores en console de Metro
□ Documentación actualizada si hay cambio funcional
□ versionCode y versionName actualizados si corresponde
```

### Antes de mergear a main

```txt
□ Smoke test en APK QA del último build de qa
□ Health check QA verde (Backend • Health Check QA)
□ Review del PR aprobada
□ CI verde
□ Release notes preparadas (para Play Store si aplica)
```

### Después de mergear a main

```txt
□ Verificar Actions → push a main → los 3 jobs de Mobile verdes
□ Verificar Actions → Backend • Lint, Build & Validate verde
□ Verificar Railway Production health check
□ Descargar y verificar el AAB si va a Play Store
```

---

## Variables y credenciales de referencia

### GitHub Variables (Settings → Secrets and variables → Variables)

| Variable | Uso |
|----------|-----|
| `QA_API_URL` | URL base backend QA en CI |
| `QA_SOCKET_URL` | URL Socket.IO QA en CI |
| `PROD_API_URL` | URL base backend Production en CI |
| `PROD_SOCKET_URL` | URL Socket.IO Production en CI |

### GitHub Secrets (Settings → Secrets and variables → Secrets)

| Secret | Uso |
|--------|-----|
| `KEYSTORE_PASSWORD` | Firma Android (MYAPP_UPLOAD_STORE_PASSWORD) |
| `KEY_PASSWORD` | Firma Android (MYAPP_UPLOAD_KEY_PASSWORD) |

### Railway Variables (por ambiente, en Railway dashboard)

| Variable | Ambientes |
|----------|-----------|
| `DATABASE_URL` | QA, Production |
| `JWT_SECRET` | QA, Production |
| `JWT_EXPIRES_IN` | QA, Production |
| `NODE_ENV` | QA (`qa`), Production (`production`) |
| `CORS_ORIGIN` | QA, Production |
| `SOCKET_ORIGIN` | QA, Production |
| `PORT` | Inyectado automáticamente por Railway |

---

## Documentos relacionados

- `docs/cicd-strategy.md` — convenciones completas de CI/CD
- `docs/cicd-mobile.md` — pipeline mobile
- `docs/cicd-backend.md` — pipeline backend
- `docs/cicd-governance.md` — branch protection
- `docs/branch-strategy.md` — estrategia de ramas y proceso de hotfix
