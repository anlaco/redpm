# Definición del Problema

> **Documento fundacional de redpm**
> Última actualización: 7 de febrero de 2026
> Autor: Dirección técnica — ANLACO

---

## ¿Qué problema resuelve redpm?

Red es un lenguaje de programación con una comunidad creciente, pero carece de un
sistema estandarizado para compartir y reutilizar código entre proyectos.

Hoy, un desarrollador que quiere usar una librería de Red en su proyecto tiene que:

1. Buscar el repositorio manualmente (no hay catálogo central).
2. Clonar el repositorio a mano en algún directorio.
3. Averiguar la ruta correcta para hacer `#include`.
4. Recordar qué versión descargó (no hay lockfile ni versionado).
5. Si la librería tiene sus propias dependencias, repetir el proceso para cada una.
6. Rezar para que todo funcione en otro sistema operativo.

Esto hace que compartir código en Red sea **frágil, manual y no reproducible**.

---

## La solución: redpm

**redpm** (Red Package Manager) es una herramienta de línea de comandos que
automatiza la gestión de dependencias para proyectos Red.

### Lo que redpm debe ser

- **Simple:** Un desarrollador debe poder añadir una dependencia con un solo
  comando y usarla con un solo `#include`.
- **Reproducible:** Dos personas que ejecuten `redpm install` en el mismo proyecto
  deben obtener exactamente las mismas dependencias.
- **Cross-platform:** Debe funcionar en Linux, macOS y Windows sin cambios.
- **Transparente:** El formato de configuración (`deps.red`) debe ser legible
  por un humano sin documentación.

### Lo que redpm NO debe ser

- **Un repositorio de binarios.** redpm gestiona código fuente, no artefactos
  compilados.
- **Un sistema de build.** redpm no compila tu proyecto; eso es trabajo del
  compilador de Red.
- **Una plataforma social.** No hay cuentas de usuario, likes ni estadísticas.
  Es una herramienta Unix: hace una cosa y la hace bien.

---

## Usuarios objetivo

| Perfil | Necesidad |
|--------|-----------|
| Desarrollador individual | Reutilizar sus propias librerías entre proyectos sin copiar archivos |
| Equipo pequeño | Compartir código interno con builds reproducibles |
| Autor de librería | Publicar su trabajo para que otros lo usen fácilmente |
| Contribuidor open source | Entender y montar rápidamente un proyecto con dependencias |

---

## Métricas de éxito

Sabremos que redpm funciona cuando:

1. Un usuario nuevo puede hacer `redpm init && redpm install` sin leer más
   documentación.
2. Un proyecto con dependencias se puede clonar y poner en marcha en < 2 minutos.
3. El mismo proyecto funciona sin cambios en Linux, macOS y Windows.
4. Las dependencias transitivas se resuelven automáticamente.

---

## Contexto técnico de Red relevante

Para entender las decisiones de diseño, es importante conocer estos aspectos de Red:

- **`#include`** es la forma nativa de importar código. No hay sistema de módulos
  con resolución automática. Un `#include %ruta/archivo.red` inserta literalmente
  el contenido del archivo.
- **Red tiene 45+ tipos de datos nativos**, incluyendo `url!`, `file!`, `version!`,
  que podemos usar directamente en los metadatos de paquetes sin inventar
  formatos propios.
- **Homoiconicidad:** El código Red *es* datos Red. El archivo `deps.red` puede
  ser un bloque Red válido que el propio lenguaje puede cargar con `load`.
- **Cross-platform por diseño:** Red compila a los tres sistemas mayores, pero
  las abstracciones de filesystem y shell varían y hay que manejarlas.

---

## Alcance del MVP actual (v0.1.0)

Lo que ya existe hoy:

| Funcionalidad | Estado | Limitaciones |
|---------------|--------|-------------|
| `redpm init` | ✅ Funcional | Genera un `deps.red` básico |
| `redpm install` | ✅ Funcional | Solo `git clone`, sin versionado, sin lockfile |
| `redpm update` | ✅ Funcional | Solo `git pull`, sin control de versiones |
| `redpm remove` | ✅ Funcional | Contiene código debug (`probe`) |
| `redpm list` | ✅ Funcional | Solo muestra instalado/no instalado |
| `redpm help` | ✅ Funcional | — |

**Lo que falta para ser un gestor de paquetes real:**
versionado, lockfile, dependencias transitivas, validación de inputs, manejo de
errores robusto, multiplataforma, tests, y una arquitectura interna que permita
evolucionar sin reescribir.

---

*Este documento es la base sobre la que se toman todas las decisiones de diseño.
Si alguna funcionalidad propuesta no resuelve el problema descrito aquí,
no pertenece a redpm.*
