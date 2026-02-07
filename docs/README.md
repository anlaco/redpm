# Documentación de Ingeniería — redpm

> **ANLACO** — Software libre, documentación libre.

Bienvenido a la documentación interna de **redpm**, el gestor de paquetes
para el lenguaje Red.

Esta documentación está pensada para cualquier persona que quiera entender,
contribuir o dirigir el desarrollo de redpm. No se necesita contexto previo
más allá de saber programar.

---

## Documentos

Léelos en este orden si es tu primera vez:

| # | Documento | Qué encontrarás |
|---|-----------|-----------------|
| 1 | [Definición del Problema](01-definicion-del-problema.md) | Qué problema resuelve redpm, para quién, y qué NO es |
| 2 | [Plan Maestro](02-plan-maestro.md) | Los 5 sprints de desarrollo: tareas, criterios, riesgos |
| 3 | [Arquitectura](03-arquitectura.md) | Subsistemas, flujos de datos, estructura de archivos, decisiones de diseño |
| 4 | [Convenciones de Código](04-convenciones-de-codigo.md) | Nomenclatura, estilo, tipos, pseudocódigo, prohibiciones |
| 5 | [Guía de Calidad](05-guia-de-calidad.md) | Checklist de revisión, testing, refactorización, deuda técnica |

---

## Estado actual

| Campo | Valor |
|-------|-------|
| Versión | v0.1.0 (MVP) |
| Sprint actual | Sprint 0 — Higiene y Cimientos |
| Próxima versión | v0.1.1 |
| Plataformas | Solo Linux (32-bit) |

---

## Cómo contribuir

1. Lee los documentos de arriba (especialmente el 4 y el 5).
2. Mira las tareas del sprint actual en el [Plan Maestro](02-plan-maestro.md).
3. Sigue el proceso PPP: pseudocódigo → revisión → implementación.
4. Asegúrate de que tu cambio pasa el checklist de la [Guía de Calidad](05-guia-de-calidad.md).

---

## Otros documentos del proyecto

- [README.md](../README.md) — Guía de usuario (cómo usar redpm)
- [ROADMAP.md](../ROADMAP.md) — Hoja de ruta pública (visión a largo plazo)

---

*Si algo no está claro, es un bug de la documentación. Abre un issue.*
