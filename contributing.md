# TacosManager — Contributing Guide

Version: 1.0
Etapa: 5.0.4.4 ✅ COMPLETADA (2026-05-29)

---

## Para quién es esta guía

Para cualquier desarrollador (humano o IA) que quiera contribuir al proyecto TacosManager.
Cubre setup de entorno, flujo de trabajo, commits, PRs y expectativas de CI.

---

## 1. Setup del entorno

### Prerrequisitos

```txt
Node.js   LTS (≥ 20.x)
npm       viene con Node.js
Java      17 (Temurin recomendado — para builds Android)
Android Studio  con SDK API 35+
Git       ≥ 2.40
```

### Repositorios

```txt
TacosManager (Mobile)  — React Native app
tacos-manager-api      — NestJS backend
tacosmanager-docs      — Documentación (submódulo de ambos repos)
```

### Setup Mobile

```bash
git clone https://github.com/RobertoCarMed/TacosManager.git
cd TacosManager
git submodule update --init      # inicializa docs/
npm install
cp .env.example .env.development  # completar con valores locales
npm run android:dev               # inicia Metro + emulador dev
```

### Setup Backend

```bash
git clone https://github.com/RobertoCarMed/tacos-manager-api.git
cd tacos-manager-api
git submodule update --init
pnpm install
cp .env.example .env.development  # completar DATABASE_URL y JWT_SECRET
pnpm run start:dev
```

### Variables de entorno (Mobile)

Crear `.env.development` en la raíz del repo Mobile:

```env
API_URL=http://10.0.2.2:3000
SOCKET_URL=http://10.0.2.2:3000
ENVIRONMENT=development
```

### Variables de entorno (Backend)

Crear `.env.development`:

```env
NODE_ENV=development
DATABASE_URL=postgresql://postgres:password@localhost:5432/tacosmanager_dev
JWT_SECRET=dev-secret-change-in-prod
JWT_EXPIRES_IN=1d
PORT=3000
```

---

## 2. Naming de ramas

```txt
feature/<etapa-o-descripcion>    — nueva funcionalidad o etapa
fix/<descripcion-corta>          — corrección de bug
hotfix/<descripcion-corta>       — fix urgente desde main
chore/<descripcion-corta>        — mantenimiento, dependencias
docs/<descripcion-corta>         — solo documentación
ci/<descripcion-corta>           — workflows y CI/CD
refactor/<descripcion-corta>     — refactor sin cambio de comportamiento
```

Ejemplos reales:
```txt
feature/5.0.4.4-cicd-conventions
feature/4.8-history-filters
fix/kitchen-queue-preparing-priority
hotfix/jwt-expiry-crash
docs/cicd-governance
ci/add-pr-builds-to-qa
chore/update-dependencies
```

Reglas:
- Usar kebab-case (minúsculas, guiones)
- Descripción en inglés (el código es en inglés)
- Máximo 50 caracteres después del prefijo
- Sin caracteres especiales

---

## 3. Flujo de trabajo

```txt
1. Crear rama desde dev (no desde qa ni main)
   git checkout dev && git pull
   git checkout -b feature/mi-feature

2. Implementar los cambios
   — commits atómicos con mensajes descriptivos

3. Pushear la rama
   git push -u origin feature/mi-feature

4. Abrir Pull Request hacia dev en GitHub
   — título siguiendo Conventional Commits
   — descripción completa (qué, por qué, cómo probar)

5. Esperar CI verde
   — Mobile • Lint & TypeCheck
   — Backend • Lint, Build & Validate (si hay cambio backend)

6. Review y merge a dev

7. El ciclo dev → qa → main lo conduce el responsable del proyecto
```

---

## 4. Formato de commits

Estándar: Conventional Commits

```txt
<tipo>(<scope>): <descripción en imperativo>

[cuerpo si es necesario]
```

### Tipos

```txt
feat     — nueva funcionalidad
fix      — corrección de bug
docs     — solo documentación
refactor — refactor sin cambio de comportamiento
test     — agregar o corregir tests
ci       — workflows, scripts CI/CD
chore    — mantenimiento, dependencias, configuración
perf     — mejora de rendimiento
```

### Ejemplos

```txt
feat(orders): add DELIVERY type with address validation
fix(kitchen): remove UPDATED from status priority map
docs(cicd): add hotfix process to cicd-strategy.md
ci(mobile): expand workflow triggers to dev and qa branches
chore(deps): update socket.io-client to 4.8.3
refactor(auth): extract token management to standalone service
test(orders): add FIFO and OrderType validation cases
```

### Reglas

- Descripción en minúsculas, en imperativo ("add", "fix", "remove", no "added", "fixes")
- Sin punto al final
- Máximo 72 caracteres en la primera línea
- Scope: módulo, etapa o área impactada

---

## 5. Pull Requests

### Título

Mismo formato que commits: `<tipo>(<scope>): <descripción>`

### Descripción

```markdown
## Qué hace este PR
- [cambio 1]
- [cambio 2]

## Por qué
[Contexto: etapa, bug reportado, decisión de diseño]

## Cómo probar
[Pasos concretos — o "N/A" si es solo docs/chore]

## Docs actualizadas
- [ ] docs/roadmap.md
- [ ] docs/architecture.md  
- [ ] [otro documento impactado]
```

### Antes de solicitar review

```txt
□ CI verde (ver pestaña Checks en el PR)
□ Sin conflictos con la rama destino
□ Documentación actualizada si hay cambio funcional
□ Descripción del PR completa
□ El PR incluye solo los cambios relacionados con su objetivo
```

---

## 6. Code Review

### Quién hace review

- En equipo pequeño (1-2 personas): el propio desarrollador puede auto-mergear a `dev` si CI está verde
- Para merges a `qa` y `main`: siempre requiere review de otra persona

### Qué revisar

```txt
□ El cambio hace lo que dice que hace
□ No introduce regresiones obvias
□ No hay hardcode de valores de ambiente o credenciales
□ La documentación fue actualizada si hay cambio funcional
□ El scope del PR es el correcto (no incluye cambios no relacionados)
```

### Qué NO es responsabilidad del reviewer

- Verificar que el CI pasa (eso lo hace GitHub automáticamente)
- Validar funcionalidad en dispositivo (eso es del desarrollador antes del PR)

---

## 7. Expectativas de CI

Cuando se abre un PR, se ejecuta automáticamente:

```txt
Mobile • Lint & TypeCheck   → debe pasar (verde) antes del merge
Backend • Lint, Build & Validate → debe pasar (verde) si hay cambio en backend
```

Si algún check falla:
1. Ver el detalle del check en la pestaña "Checks" del PR
2. Corregir el error en una nueva comisión en la misma rama
3. CI se vuelve a ejecutar automáticamente

Los builds de Android (`Mobile • Build QA APK`, `Mobile • Build Production AAB`) **no corren en PRs** — solo después del merge. Son quality gates post-merge.

---

## 8. Documentación como parte del trabajo

**Un cambio funcional sin documentación no está terminado.**

Antes de cerrar un PR que incluye cambios funcionales, verificar:

| Tipo de cambio | Documentos a actualizar |
|----------------|------------------------|
| Nueva feature | `roadmap.md`, `feature-list.md`, `frontend-architecture.md` o `architecture.md` |
| Cambio de API | `api-reference.md`, `architecture.md` |
| Cambio de reglas de negocio | `business-rules.md`, `architecture.md` |
| Cambio de CI/CD | `roadmap.md`, `cicd-strategy.md`, `cicd-mobile.md` o `cicd-backend.md` |
| Cambio de navegación/UX | `ui-flows.md`, `frontend-architecture.md` |

El submódulo `docs` tiene su propio ciclo de commit. Al modificar documentación:
1. Hacer el commit dentro de `docs/` en la rama `main` del submódulo
2. Hacer push del submódulo: `git push origin main`
3. Actualizar el puntero en el repo principal: `git add docs && git commit && git push`

---

## Recursos

- Flujo completo CI/CD: `docs/cicd-strategy.md`
- Branch Protection: `docs/cicd-governance.md`
- Runbooks operativos: `docs/deployment-runbook.md`
- Roadmap del proyecto: `docs/roadmap.md`
