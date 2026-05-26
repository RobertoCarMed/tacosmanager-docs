# TacosManager — Business Model

Version: 1.0
Fecha: 2026-05-25

---

# Visión del Producto

TacosManager es una plataforma SaaS diseñada para pequeños y medianos restaurantes de tacos.

Objetivo principal:

Digitalizar la operación diaria de taquerías mediante una aplicación móvil conectada a una API centralizada.

Áreas de operación cubiertas:

- Meseros — creación y gestión de pedidos
- Cocina — Kitchen Display System (KDS)
- Administración básica de productos y pedidos

---

# Alcance del MVP

## Funcionalidades incluidas

- Autenticación multi-usuario con roles (COOK / WAITER)
- Gestión de productos con catálogo multi-tenant
- Pedidos clasificados por tipo: DINE_IN / TAKEAWAY / DELIVERY
- Cocina en tiempo real (KDS — Kitchen Display System)
- Socket.IO Realtime (actualizaciones instantáneas sin polling)
- Multi-tenant por taquería (aislamiento completo por restaurantCode)

## Funcionalidades NO incluidas en MVP

- Pedidos por QR (clientes escanean código)
- Self Ordering (clientes hacen pedidos directamente)
- Analytics avanzados
- Reportes avanzados
- Advanced Delivery Management (tracking, app de repartidores, estados adicionales)

Estas funcionalidades se evalúan post-lanzamiento en ETAPA 6.0.

Ver roadmap técnico completo: docs/roadmap.md

---

# Modelo de Suscripción

## Plan STARTER

```txt
Precio:   $199 MXN / mes
Usuarios: hasta 3
```

Cliente objetivo: Taquerías pequeñas — operación básica de 1 cocinero + 1-2 meseros.

---

## Plan GROWTH

```txt
Precio:   $499 MXN / mes
Usuarios: hasta 8
```

Cliente objetivo: Taquerías medianas con mayor volumen de pedidos y equipo más amplio.

---

## Plan PRO

```txt
Precio:   $899 MXN / mes
Usuarios: ilimitados
```

Cliente objetivo: Operaciones más grandes o con múltiples locaciones.

---

# Mercado Objetivo

Segmento: Pequeñas y medianas taquerías.

Primer mercado: México.

---

# Infraestructura Objetivo MVP

## Stack

| Capa         | Tecnología                        |
|--------------|-----------------------------------|
| Backend      | NestJS + PostgreSQL + Socket.IO   |
| Frontend     | React Native (Android)            |
| Storage      | Firebase Storage (imágenes)       |
| Despliegue   | Railway + PostgreSQL administrado |

## Dispositivos objetivo

- Tablets de 10 pulgadas — Kitchen Display System (cocina)
- Teléfonos Android — app de meseros

## Razón de usar Railway

Para MVP y primeras validaciones se prioriza:

- Simplicidad de despliegue
- Velocidad de onboarding
- Menor carga operativa

sobre optimización extrema de costos.

Migración futura a AWS u otro proveedor puede evaluarse cuando exista tracción comercial suficiente.

---

# Costos Estimados

Los valores son aproximados y sujetos a cambios según uso real.

| Concepto              | Estimado mensual |
|-----------------------|------------------|
| Infraestructura       | ≈ $500 MXN       |
| Herramientas IA       | ≈ $700 MXN       |
| **Costo operativo**   | **≈ $1,200 MXN** |

---

# Punto de Equilibrio

Plan STARTER: $199 MXN / mes

```txt
Punto de equilibrio: ≈ 7 clientes STARTER

7 × $199 = $1,393 MXN/mes ≈ costo operativo total
```

---

# Objetivos de Validación

## Meta 1 — 7 clientes

Validar disposición de pago del mercado.

---

## Meta 2 — 20 clientes

Cubrir la operación cómodamente con margen positivo.

---

## Meta 3 — 50 clientes

Negocio secundario rentable y autosustentable.

---

## Meta 4 — 100+ clientes

Evaluar crecimiento serio y potencial de expansión de mercado.

---

# Roadmap Comercial

## Inmediato: ETAPA 4.7 Realtime Reliability ⬜

Objetivo: Confiabilidad operativa para producción.

Implementar: Reconnection Strategy, Heartbeats, Connection Recovery, Cleanup.

---

## Lanzamiento: ETAPA 5.0 MVP Launch ⬜

Objetivo: Lanzamiento productivo.

Sin nuevas funcionalidades de negocio — el foco es infraestructura y despliegue.

```txt
5.0.1 — Environment Strategy (DEV / QA / PROD)
5.0.2 — Backend Deployment (Railway + PostgreSQL)
5.0.3 — Mobile Release Pipeline (Build flavors)
5.0.4 — CI/CD Automation (Backend + Frontend)
5.0.5 — Monitoring & Recovery (Sentry)
5.0.6 — Production Validation
5.0.7 — Play Store Release (Internal → Closed → Production)
```

---

## Post-Lanzamiento: ETAPA 6.0 Post Launch Features ⬜

Evaluadas después del lanzamiento y tracción comercial inicial:

- QR Ordering
- Customer Self Ordering
- Analytics & Reports
- Advanced Delivery Management
- Reporting avanzado

Ver: docs/roadmap.md

---

# Decisiones Documentadas

## Firebase Storage en MVP

Firebase Storage se conserva únicamente para imágenes de productos.

Firebase Auth y Firestore fueron eliminados en ETAPA 4.5.

Migración futura de Storage al backend puede evaluarse post-lanzamiento.

## DELIVERY en MVP

Los pedidos DELIVERY son capturados exclusivamente por personal interno:

```txt
Cliente llama → Mesero captura en el sistema → Pedido registrado con deliveryAddress
```

No existe app de clientes ni tracking de domicilio en MVP.

## Sin reportes en MVP

Los reportes y analytics generan valor a partir de volumen real de datos.

Se diseñaron los modelos de datos para soportarlos en el futuro, pero no se implementan antes del lanzamiento.

---

# Documentos Relacionados

- [docs/roadmap.md](roadmap.md) — Roadmap técnico completo de etapas
- [docs/business-rules.md](business-rules.md) — Reglas funcionales del sistema (dominio técnico)
- [docs/architecture.md](architecture.md) — Arquitectura técnica
- [docs/feature-list.md](feature-list.md) — Lista completa de funcionalidades implementadas

---

*Este documento contiene exclusivamente información estratégica y comercial. Las reglas funcionales del sistema están en docs/business-rules.md.*
