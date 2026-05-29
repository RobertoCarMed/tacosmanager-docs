# Backend CI — TacosManager

Versión: 1.0
Etapa: 5.0.4.2
Estado: ✅ COMPLETADA

---

# Objetivo

Validar automáticamente la calidad del backend NestJS antes de permitir merges a `main`.

El pipeline garantiza que:

- El código no tiene errores de lint
- El build TypeScript compila sin errores
- El schema Prisma es válido
- El backend desplegado en QA responde correctamente (solo en push a main)

Esta etapa **no incluye** deploy automático, publicación de artefactos ni tests de integración con base de datos externa.

---

# Archivo del workflow

```txt
.github/workflows/backend-ci.yml
```

---

# Triggers

| Evento | Descripción |
|--------|-------------|
| `pull_request` | Cualquier PR abierto o actualizado |
| `push → main` | Push directo o merge de PR a la rama main |

---

# Flujo PR

Ejecutado en: todos los `pull_request` y `push → main`.

```txt
1. Checkout del repositorio
2. Setup pnpm (latest)
3. Setup Node.js LTS con cache pnpm
4. pnpm install --frozen-lockfile
5. pnpm lint       ← ESLint sobre src/
6. pnpm build      ← nest build (compilación TypeScript)
7. prisma validate ← valida schema.prisma sin conexión a BD
```

Si cualquier paso falla → el workflow falla → el merge queda bloqueado.

---

# Flujo Main (adicional al flujo PR)

Ejecutado solo en: `push → main`.

```txt
8. Health Check QA
   GET $QA_API_URL/health
   Valida: { status: "ok" }
```

Si el health check falla → el workflow falla.

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

No requiere conexión a base de datos. El datasource en el schema no incluye `url` (se usa el driver adapter en runtime).

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

# Variables requeridas en GitHub

## Variables de repositorio (Settings → Secrets and variables → Actions → Variables)

| Variable | Descripción | Cuándo se usa |
|----------|-------------|---------------|
| `QA_API_URL` | URL base del backend en Railway QA (ej. `https://tacos-manager-api-qa.up.railway.app`) | Push a main — Health Check QA |

**No incluir** `/health` en el valor de la variable. El workflow lo agrega automáticamente.

## Secrets

Esta etapa no requiere secrets adicionales. No hay firma de artefactos ni conexión a bases de datos externas.

---

# Configuración en el runner

| Componente | Valor |
|------------|-------|
| Runner | `ubuntu-latest` |
| Node.js | LTS (`lts/*`) |
| pnpm | `latest` |
| Cache | pnpm store (keyed por `pnpm-lock.yaml`) |
| DATABASE_URL | No requerida |
| jq | Pre-instalado en ubuntu-latest |

---

# Troubleshooting

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

# Checklist de mantenimiento

```txt
□ Al cambiar la URL del servicio Railway QA → actualizar QA_API_URL en GitHub Variables
□ Al actualizar la versión de pnpm en el proyecto → verificar que el workflow sigue pasando
□ Al actualizar Node.js en el proyecto → actualizar node-version en el workflow si es necesario
□ Al agregar nuevas reglas ESLint → verificar que pnpm lint sigue pasando en CI
□ Periódicamente verificar que ubuntu-latest sigue teniendo jq pre-instalado
```

---

# Casos de prueba manuales

## 1. Verificar que el pipeline se activa en PR

```txt
1. Crear un branch nuevo con cualquier cambio
2. Abrir un Pull Request hacia main
3. Ir a GitHub → pestaña Actions
4. Confirmar que "Backend CI" aparece y ejecuta el job "Lint · Build · Validate"
5. Todos los pasos deben pasar (verde ✅)
6. El paso "Health Check QA" NO debe ejecutarse en PR
```

## 2. Verificar que el pipeline se activa en push a main

```txt
1. Hacer merge de un PR o push directo a main
2. Ir a GitHub → pestaña Actions
3. Confirmar que "Backend CI" se ejecuta
4. Los pasos de validación (lint, build, prisma validate) deben pasar
5. El paso "Health Check QA" DEBE ejecutarse
6. Confirmar que el health check pasa correctamente
```

## 3. Verificar que lint falla correctamente

```txt
1. Crear un branch con un error de lint no auto-corregible (ej. variable no usada con explicit any)
2. Abrir un PR
3. Confirmar que el paso "Lint" falla (rojo ❌)
4. Confirmar que el merge queda bloqueado (si branch protection está configurada)
```

## 4. Verificar que build falla correctamente

```txt
1. Crear un branch con un error TypeScript intencional (ej. tipo incorrecto)
2. Abrir un PR
3. Confirmar que el paso "Build" falla (rojo ❌)
```

## 5. Verificar health check manual

```txt
1. Obtener la URL del servicio Railway QA
2. Ejecutar: curl -s $QA_API_URL/health
3. Confirmar que la respuesta es: { "status": "ok", ... }
```
