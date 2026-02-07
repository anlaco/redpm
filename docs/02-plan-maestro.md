# Plan Maestro de Desarrollo

> **Ruta de implementación de redpm**
> Última actualización: 7 de febrero de 2026
> Autor: Dirección técnica — ANLACO

---

## Filosofía de trabajo

Antes de leer los sprints, todo el equipo debe interiorizar estos principios.
No son sugerencias — son reglas del juego:

1. **Conquistar la complejidad.** Si una solución es ingeniosa pero difícil de
   entender, es una mala solución. El código más inteligente es el que no
   necesita explicación.

2. **Programar "hacia" Red.** Red tiene `url!`, `file!`, `version!`, `object!`,
   `context`, y datos que son código. Usarlos. No reinventar lo que el lenguaje
   ya ofrece.

3. **Código para humanos.** El código se lee 10x más de lo que se escribe. Los
   nombres deben decir **qué** hace algo, no **cómo** lo hace.

4. **Medir dos veces, cortar una.** Antes de escribir código, escribir
   pseudocódigo en lenguaje natural. Un error de diseño en la construcción cuesta
   10x más que detectarlo en el diseño.

5. **No escribir código especulativo.** Si una funcionalidad "podría necesitarse
   algún día", no se implementa hoy. Se implementa cuando se necesita.

---

## Visión general de los sprints

```
Sprint 0 ──► Sprint 1 ──► Sprint 2 ──► Sprint 3 ──► Sprint 4
 Higiene     Arquitectura  Robustez    Versionado   Dependencias
 y cimientos  interna      y cross-    y lockfile   transitivas
                           platform                 y testing
```

Cada sprint deja el software **funcional y desplegable**. Nunca se rompe lo que
ya funciona para añadir algo nuevo.

---

## Sprint 0: Higiene y Cimientos

> **Objetivo:** Limpiar el terreno antes de construir.
> **Versión resultante:** v0.1.1

### ¿Por qué este sprint?

No se puede construir software de calidad sobre un repositorio con artefactos
binarios trackeados, código debug en producción, y sin convenciones. Esto se
arregla primero porque es de bajo riesgo y alto impacto.

### Tareas

| # | Tarea | Detalle | Criterio de aceptación |
|---|-------|---------|----------------------|
| 0.1 | Limpiar artefactos del repo | Ejecutar `git rm --cached` sobre `redc`, `red-cli`, `redpm`, `libRedRT*`. El `.gitignore` ya los cubre. | `git status` no muestra binarios trackeados |
| 0.2 | Eliminar código debug | Quitar el `probe name` de la función `cmd-remove` en `redpm.red` | No hay `probe` en el código fuente |
| 0.3 | Crear documento de convenciones | Ver [04-convenciones-de-codigo.md](04-convenciones-de-codigo.md) | Documento revisado y aprobado |
| 0.4 | Crear script de build | Un `Makefile` o script documentado que compile el proyecto | Un nuevo contribuidor puede compilar leyendo un solo archivo |
| 0.5 | Documentar el problema | Ver [01-definicion-del-problema.md](01-definicion-del-problema.md) | Documento revisado y aprobado |
| 0.6 | Renombrar `package.red` → `deps.red` | El archivo de configuración del usuario pasa a llamarse `deps.red` para evitar colisión con el módulo ADT interno `src/package.red`. Actualizar el código fuente (`redpm.red`) y la documentación de usuario (`README.md`). | El comando `redpm init` genera `deps.red`. Todas las referencias son coherentes. |

### Riesgos del sprint

Ninguno significativo. Son cambios de bajo riesgo.

### Entregable

- Repositorio limpio
- Documentos fundacionales creados
- El software sigue funcionando exactamente igual que antes

---

## Sprint 1: Arquitectura de Caja Negra

> **Objetivo:** Reestructurar el código en subsistemas aislados con `context`.
> **Versión resultante:** v0.2.0

### ¿Por qué este sprint?

El código actual es un archivo monolítico de 215 líneas donde todas las
variables y funciones viven en el scope global. Esto hace que:

- Cualquier cambio pueda romper algo inesperado (acoplamiento alto).
- No se pueda trabajar en paralelo (todos tocan el mismo archivo).
- No se puedan testear partes individuales.

### Tareas

| # | Tarea | Detalle | Criterio de aceptación |
|---|-------|---------|----------------------|
| 1.1 | Definir el ADT de paquete | Un `package!` es un objeto Red con campos tipados: `name`, `url`, `version`, `status`, `path`. Todas las funciones manipulan paquetes a través de este ADT, nunca como strings sueltos. | No existen strings de nombre/url fuera del ADT |
| 1.2 | Crear contexto `logger` | Mover `print-ok`, `print-err`, `print-info`, `print-warn` y las constantes de color a un `context` dedicado. | La funcionalidad de logging no expone variables globales |
| 1.3 | Crear contexto `git-client` | Encapsular todas las llamadas a `call` que ejecutan git (`clone`, `pull`) en un `context` con interfaz pública mínima. | Ninguna otra parte del código ejecuta comandos git directamente |
| 1.4 | Crear contexto `registry` | Lectura y escritura de `deps.red`. Transforma el formato de archivo al ADT de paquete y viceversa. | El formato del archivo se puede cambiar sin afectar al resto |
| 1.5 | Crear contexto `filesystem` | Operaciones de directorio: crear, eliminar, comprobar existencia. Abstrae las diferencias entre plataformas. Absorbe lo que hoy es `Red-Utils/delete-dir`. | No hay llamadas directas a `make-dir`, `delete`, `exists?` fuera de este contexto |
| 1.6 | Crear contexto `manager` | Lógica de negocio: `install`, `update`, `remove`, `list`. Usa los otros contextos como dependencias. | La lógica de negocio no sabe nada de git, filesystem o formato de archivo |
| 1.7 | Implementar la barricada | Toda entrada del exterior (URLs, nombres de paquete, respuestas de git, contenido de `deps.red`) se valida y sanitiza antes de entrar a la lógica interna. | Existe una función `validate-*` para cada tipo de input externo |
| 1.8 | Reorganizar archivos | Mover cada contexto a su propio archivo en `src/`. El archivo principal `redpm.red` solo hace parsing de CLI y dispatch. | Ver estructura en [03-arquitectura.md](03-arquitectura.md) |

### Proceso obligatorio para cada tarea

1. **Escribir pseudocódigo** en lenguaje natural antes de codificar.
2. **Revisión** del pseudocódigo por el director.
3. El pseudocódigo aprobado se convierte en **comentarios** del archivo.
4. El código real se escribe **debajo** de cada comentario.

### Riesgos del sprint

| Riesgo | Mitigación |
|--------|------------|
| Red no soporta `#include` con paths dinámicos | Investigar antes de refactorizar; pueden necesitarse paths relativos fijos |
| Romper funcionalidad existente al reestructurar | Crear un smoke test manual ANTES de empezar y ejecutarlo después de cada cambio |

### Entregable

- Código modular en 6+ archivos con `context`
- ADT de paquete implementado
- Barricada de validación
- Todas las funcionalidades de v0.1 siguen operativas

---

## Sprint 2: Robustez y Cross-Platform

> **Objetivo:** Que redpm funcione bien en Linux, macOS y Windows con manejo
> de errores real.
> **Versión resultante:** v0.2.1

### ¿Por qué este sprint?

El MVP actual solo funciona en Linux. Usa colores ANSI que Windows no soporta
por defecto, ejecuta comandos shell sin verificar resultados, y no maneja
errores — simplemente falla silenciosamente o crashea.

Un gestor de paquetes que no inspira confianza no se usa.

### Tareas

| # | Tarea | Detalle | Criterio de aceptación |
|---|-------|---------|----------------------|
| 2.1 | Detección de SO | Usar `system/platform` para identificar el sistema operativo al inicio. Almacenar en el contexto `filesystem`. | El sistema sabe en qué OS está corriendo |
| 2.2 | Adaptar colores | En Windows: deshabilitar ANSI o habilitar VT100 explícitamente. En otros: mantener comportamiento actual. | Los mensajes se leen bien en los 3 sistemas |
| 2.3 | Manejo de errores en I/O | Envolver todas las operaciones de archivo y red en `try`. Producir mensajes de error descriptivos (qué falló, por qué, qué hacer). | Ninguna operación de I/O puede crashear la aplicación |
| 2.4 | Verificar resultados de git | Capturar el código de retorno de cada operación git. Distinguir entre errores de red, permisos, repo inexistente, etc. | El usuario recibe un mensaje específico, no un error críptico |
| 2.5 | Eliminar dependencias shell innecesarias | Reemplazar comandos shell por funciones nativas de Red donde sea posible (ej. `mkdir`, navegación de directorios). | Solo `git` se ejecuta con `call` |
| 2.6 | Probar en las 3 plataformas | Documentar los resultados de ejecutar la suite básica en Linux, macOS y Windows. | Documento de compatibilidad con resultados reales |

### Riesgos del sprint

| Riesgo | Mitigación |
|--------|------------|
| No tener acceso a las 3 plataformas para probar | Usar CI (GitHub Actions) con los 3 OS como runners |
| Comportamiento de paths (`/` vs `\`) | Usar `file!` nativo de Red que debería abstraer esto; verificar |

### Entregable

- redpm funciona en Linux, macOS y Windows
- Errores producen mensajes útiles, nunca crashes
- Documento de compatibilidad

---

## Sprint 3: Versionado y Lockfile

> **Objetivo:** Builds reproducibles. Que `install` instale siempre lo mismo.
> **Versión resultante:** v0.3.0

### ¿Por qué este sprint?

Sin versionado, un `redpm install` hoy puede producir un resultado diferente
que mañana (porque el branch principal del paquete cambió). Esto hace que los
builds no sean reproducibles, que es inaceptable para cualquier proyecto serio.

### Tareas

| # | Tarea | Detalle | Criterio de aceptación |
|---|-------|---------|----------------------|
| 3.1 | Extender formato `deps.red` | Soportar tags, branches y commits. Retrocompatible con el formato actual. | `Red-Serial "url"` sigue funcionando. `Red-Serial ["url" tag: "v1.0"]` también. |
| 3.2 | Implementar `deps.lock` | Después de `install`, generar un lockfile con el commit exacto de cada paquete instalado. | El lockfile contiene SHAs verificables |
| 3.3 | Respetar lockfile en `install` | Si existe `deps.lock`, instalar las versiones exactas registradas ahí, no las últimas. | Dos ejecuciones de `install` con el mismo `deps.lock` producen el mismo resultado |
| 3.4 | Regenerar lockfile en `update` | `redpm update` actualiza los paquetes Y regenera el lockfile. | El lockfile refleja el estado real después de `update` |
| 3.5 | Flag `--no-lock` | `redpm install --no-lock` ignora el lockfile e instala las últimas versiones. | El flag funciona y está documentado en `help` |
| 3.6 | Primer smoke test automatizado | Un script Red que ejecute el flujo completo: `init → install → list → update → remove` y verifique resultados. | El test pasa sin intervención humana |

### Formato propuesto para `deps.lock`

```red
[
    ;-- Generado automáticamente por redpm — NO EDITAR
    ;-- Fecha: 2026-02-07

    Red-Serial [
        url:       https://github.com/ANLACO/Red-Serial
        commit:    "a1b2c3d4e5f6789..."
        installed: "2026-02-07T10:30:00"
    ]
]
```

### Formato extendido para `deps.red`

```red
[
    ;-- Formato simple (última versión):
    Red-Utils "https://github.com/ANLACO/Red-Utils"

    ;-- Formato extendido (versión específica):
    Red-Serial ["https://github.com/ANLACO/Red-Serial" tag: "v1.0.0"]
    Red-JSON   ["https://github.com/user/Red-JSON" branch: "stable"]
    Red-Math   ["https://github.com/user/Red-Math" commit: "abc1234"]
]
```

### Riesgos del sprint

| Riesgo | Mitigación |
|--------|------------|
| `git` no está disponible en el sistema del usuario | Ya se verifica con `check-git`; asegurar que el mensaje sea claro |
| Formato retrocompatible difícil de parsear | Diseñar el parser con tests primero; la simplicidad del formato ayuda |

### Entregable

- Versionado funcional (tag, branch, commit)
- Lockfile que garantiza reproducibilidad
- Primer test automatizado

---

## Sprint 4: Dependencias Transitivas y Testing

> **Objetivo:** Resolución automática de sub-dependencias y suite de tests.
> **Versión resultante:** v0.4.0

### ¿Por qué este sprint?

Un paquete A puede depender de un paquete B, que a su vez depende de C. Hoy el
usuario tiene que declarar A, B y C manualmente. Eso no escala y es propenso a
errores.

### Tareas

| # | Tarea | Detalle | Criterio de aceptación |
|---|-------|---------|----------------------|
| 4.1 | Leer dependencias de paquetes instalados | Después de instalar un paquete, leer su `deps.red` para descubrir sub-dependencias. | Se detectan dependencias de segundo nivel |
| 4.2 | Construir grafo de dependencias | Representar las relaciones como un grafo acíclico dirigido (DAG). | Se puede recorrer y visualizar el grafo |
| 4.3 | Detectar ciclos | Si A depende de B y B depende de A, abortar con mensaje claro. | El ciclo se detecta antes de intentar instalar |
| 4.4 | Detectar conflictos de versión | Si A quiere `Red-Utils v1.0` y B quiere `Red-Utils v2.0`, advertir al usuario. | El conflicto se reporta con información suficiente para resolverlo |
| 4.5 | Instalar transitivas automáticamente | `redpm install` instala todo el árbol, no solo las dependencias directas. | Un paquete con sub-dependencias se instala completamente |
| 4.6 | Comando `redpm tree` | Muestra el árbol de dependencias en la terminal. | El árbol es visualmente claro y muestra profundidad |
| 4.7 | Suite de tests unitarios | Tests con casos límite: paquete inexistente, URL malformada, dependencia circular, `deps.red` vacío/malformado, sin conexión. | Los tests cubren los escenarios críticos y pasan todos |

### Algoritmo de resolución (pseudocódigo)

```
Para instalar un paquete P:
  1. Si P ya está en la lista de "visitados", hay un ciclo → abortar
  2. Marcar P como "visitado"
  3. Descargar P si no está instalado
  4. Leer el deps.red de P
  5. Para cada dependencia D de P:
     a. Si D ya está instalada con versión compatible → continuar
     b. Si D ya está instalada con versión incompatible → advertir
     c. Si D no está instalada → instalar D (recursión al paso 1)
  6. Registrar P en el lockfile
```

### Riesgos del sprint

| Riesgo | Mitigación |
|--------|------------|
| Red no tiene framework de testing estándar | Crear un mini-framework de asserts propio (simple, < 50 líneas) |
| La resolución de dependencias puede ser NP-hard en el caso general | Empezar con la estrategia más simple (primer match compatible) y evolucionar |
| Tests requieren repos reales de Git | Crear repos de test en la organización ANLACO de GitHub |

### Entregable

- Resolución transitiva de dependencias
- Detección de ciclos y conflictos
- Comando `tree`
- Suite de tests que cubre los escenarios críticos

---

## Resumen de versiones

| Versión | Sprint | Hito principal |
|---------|--------|---------------|
| v0.1.1 | Sprint 0 | Repo limpio, documentación base |
| v0.2.0 | Sprint 1 | Arquitectura modular con `context` |
| v0.2.1 | Sprint 2 | Cross-platform + manejo de errores |
| v0.3.0 | Sprint 3 | Versionado + lockfile |
| v0.4.0 | Sprint 4 | Dependencias transitivas + tests |

---

## Lo que queda fuera de este plan (y por qué)

Estas funcionalidades aparecen en el ROADMAP.md original pero **no** se abordan
en estos 5 sprints. No es que no sean importantes — es que primero hay que
construir unos cimientos sólidos:

| Funcionalidad | Por qué no ahora |
|---------------|------------------|
| Registro central de paquetes | Requiere infraestructura de servidor; primero el cliente |
| Publicación (`redpm publish`) | Requiere registro central |
| Caché global | Optimización prematura; primero que funcione |
| Auditoría de seguridad | Requiere base de datos de vulnerabilidades |
| Workspaces / monorepos | Funcionalidad avanzada para la v1.0+ |

---

*Este plan es un documento vivo. Se actualiza al inicio de cada sprint con
los aprendizajes del sprint anterior. Los cambios se registran en el historial
de git.*
