# Convenciones de Código

> **Guía de estilo y reglas de escritura para redpm**
> Última actualización: 7 de febrero de 2026
> Autor: Dirección técnica — ANLACO

---

## ¿Por qué convenciones?

En un equipo (de humanos o de IAs), cada persona tiene su estilo de
programación preferido. Sin acuerdos explícitos, el código se convierte en una
mezcla incoherente donde cada archivo parece escrito por alguien diferente.

Estas convenciones no son caprichosas — cada una tiene una razón. Cuando la
razón deja de tener sentido, la convención se cambia.

---

## 1. Nomenclatura

### Funciones: `verbo-sustantivo`

Las funciones se nombran con **verbo-sustantivo** en minúsculas separadas por
guiones. El nombre debe decir **qué hace**, no **cómo lo hace**.

```red
;-- ✅ Bien: dice qué hace
install-package
load-config
validate-url
remove-directory

;-- ❌ Mal: dice cómo lo hace
git-clone-into-deps-folder
read-and-parse-block-from-file
loop-through-and-delete

;-- ❌ Mal: no dice qué hace
process
handle
do-stuff
run
```

### Variables: `sustantivo` o `adjetivo-sustantivo`

```red
;-- ✅ Bien
deps-dir
package-list
current-sha
is-installed

;-- ❌ Mal: abreviaturas crípticas
d
pkg-lst
sha
inst
```

### Predicados (funciones que devuelven logic!): terminan en `?`

```red
;-- ✅ Bien
installed?
valid-url?
dir-exists?

;-- ❌ Mal
check-installed    ;-- ¿Qué devuelve? ¿Qué hace si no está?
is-valid           ;-- Aceptable, pero "?" es más idiomático en Red
```

### Contextos: `sustantivo` en singular

```red
;-- ✅ Bien
logger: context [...]
registry: context [...]
validator: context [...]

;-- ❌ Mal
logging-functions: context [...]
my-utils: context [...]
```

---

## 2. Uso de tipos nativos de Red

Red tiene más de 45 tipos de datos. Usarlos nos da validación gratis y hace
el código más expresivo. **No representar como string lo que tiene tipo propio.**

| Concepto | Tipo Red | Ejemplo |
|----------|----------|---------|
| URL de repositorio | `url!` | `https://github.com/ANLACO/Red-Serial` |
| Ruta de archivo | `file!` | `%deps/Red-Serial/` |
| Versión | `string!` con convención | `"v1.0.0"` |
| Estado de paquete | `word!` | `'installed` `'missing` `'outdated` |
| Lista de paquetes | `block!` de objetos | `[pkg1 pkg2 pkg3]` |
| Metadatos | `object!` | `make object! [name: "..." url: https://...]` |

```red
;-- ✅ Bien: usa tipos nativos
url: https://github.com/ANLACO/Red-Serial
path: %deps/Red-Serial/
status: 'installed

;-- ❌ Mal: todo es string
url: "https://github.com/ANLACO/Red-Serial"
path: "deps/Red-Serial/"
status: "installed"
```

---

## 3. Estructura de un archivo fuente

Cada archivo `.red` del proyecto sigue esta estructura:

```red
Red [
    Title:   "Nombre descriptivo del módulo"
    Author:  "ANLACO"
    File:    %nombre-archivo.red
    Version: 0.2.0
    Purpose: {
        Descripción breve de qué hace este módulo
        y por qué existe.
    }
]

;-- Includes necesarios (solo los estrictamente necesarios)
#include %../otro-modulo.red

;-- El módulo como context
nombre-modulo: context [

    ;-------------------------------------------------------
    ;-- INTERFAZ PÚBLICA
    ;-- (las funciones que otros módulos pueden usar)
    ;-------------------------------------------------------

    ;-- Inicializa el módulo con la configuración dada.
    ;-- config: object! con los campos necesarios
    ;-- Devuelve: logic! indicando éxito
    init: func [config [object!]] [
        ...
    ]

    ;-------------------------------------------------------
    ;-- IMPLEMENTACIÓN PRIVADA
    ;-- (nadie fuera de este context debería usar esto)
    ;-------------------------------------------------------

    internal-helper: func [...] [
        ...
    ]
]
```

---

## 4. Comentarios

### Comentarios de intento, NO de mecánica

Los comentarios explican **por qué** se hace algo o **qué** se pretende lograr.
Nunca explican **qué hace el código** línea por línea (eso ya lo dice el código).

```red
;-- ✅ Bien: explica el por qué
;-- Usamos depth 1 porque solo necesitamos el último commit.
;-- Descargar todo el historial desperdicia ancho de banda.
cmd: rejoin ["git clone --depth 1 " url " " path]

;-- ❌ Mal: repite lo que el código ya dice
;-- Concatenamos "git clone --depth 1" con la url y el path
cmd: rejoin ["git clone --depth 1 " url " " path]
```

### Pseudocódigo: herramienta de diseño, NO decoración del código

Para funciones no triviales (más de 10 líneas o con lógica condicional),
el flujo de desarrollo es:

1. Escribir el **intento** en pseudocódigo (lenguaje natural) — en un
   borrador, papel, issue o PR. **No en el archivo fuente.**
2. Revisar el pseudocódigo (otra persona, tú mismo tras un descanso, o
   un modelo de IA como herramienta auxiliar).
3. Una vez conforme, implementar el código real.
4. El pseudocódigo **no se copia al archivo**. Se descarta.

**Los únicos comentarios que sobreviven en el código** son los que explican
decisiones no obvias (el *por qué*). Si el código necesita un comentario
para entender *qué* hace, el problema son los nombres, no la falta de
comentarios.

```red
;-- ✅ Bien: el código habla por sí mismo, el comentario explica el por qué
install-all: func [/local packages pkg] [
    packages: registry/load-packages
    if empty? packages [
        logger/log-warn "No hay dependencias declaradas"
        exit
    ]
    ;-- Creamos deps/ aquí y no antes para no dejar directorios vacíos
    ;-- si el usuario no tiene dependencias declaradas.
    filesystem/ensure-dir deps-dir
    foreach pkg packages [
        either package/installed? pkg [
            logger/log-info rejoin [package/get-name pkg " ya instalado"]
        ][
            install-single pkg
        ]
    ]
]

;-- ❌ Mal: pseudocódigo como comentarios que repiten lo que el código dice
install-all: func [/local packages pkg] [
    ;-- Cargar la lista de paquetes desde deps.red
    packages: registry/load-packages
    ;-- Si no hay paquetes declarados, avisar y salir
    if empty? packages [...]
    ;-- Asegurar que existe el directorio de dependencias
    filesystem/ensure-dir deps-dir
    ;-- Para cada paquete, instalarlo si no está ya
    foreach pkg packages [...]
]
```

### Marcadores de sección

Dentro de un `context` largo, usar marcadores de sección con línea de guiones:

```red
;-------------------------------------------------------
;-- SECCIÓN: Nombre descriptivo
;-------------------------------------------------------
```

---

## 5. Manejo de errores

### Regla: nunca fallar silenciosamente

Cada operación que puede fallar (I/O, red, git) debe:

1. Envolver la operación en `try` o `attempt`.
2. Verificar el resultado.
3. Producir un mensaje descriptivo: **qué falló**, **por qué** (si se sabe),
   y **qué puede hacer el usuario**.

```red
;-- ✅ Bien
result: attempt [read url]
unless result [
    logger/log-error rejoin [
        "No se pudo descargar desde " url ". "
        "Verifica tu conexión a internet y que la URL sea correcta."
    ]
    return none
]

;-- ❌ Mal: falla silenciosamente
result: attempt [read url]
;-- (sigue ejecutando como si nada, result puede ser none)
```

### La barricada

Los datos del exterior son "sucios" hasta que se demuestren inocentes:

```
         EXTERIOR (no confiable)          │     INTERIOR (confiable)
                                          │
  URLs del usuario ─────┐                │
  Nombres de paquetes ──┤  ► VALIDATOR ──┼──► Lógica de negocio
  Respuestas de git ────┤    (barricada) │    (trabaja con datos
  Contenido de archivos ┘                │     ya validados)
                                          │
```

---

## 6. Formato y estilo visual

### Indentación: 4 espacios

No tabuladores. 4 espacios. Sin excepciones.

### Longitud de línea: máximo 80 caracteres

Si una línea es más larga, romperla en varias con indentación de continuación.

### Bloques: alineación legible

```red
;-- ✅ Bien: alineado, fácil de escanear
make object! [
    name:     "Red-Serial"
    url:      https://github.com/ANLACO/Red-Serial
    version:  "v1.0.0"
    status:   'installed
]

;-- ❌ Mal: desordenado
make object! [name: "Red-Serial" url: https://github.com/ANLACO/Red-Serial version: "v1.0.0" status: 'installed]
```

### Líneas en blanco: separar bloques lógicos

Una línea en blanco entre funciones. Una línea en blanco entre bloques lógicos
dentro de una función. No más de dos líneas en blanco seguidas.

---

## 7. Prohibiciones

Estas prácticas están **prohibidas** en el código de redpm:

| Prohibición | Razón |
|-------------|-------|
| `probe` en código productivo | Es para debug temporal; usar `logger/log-debug` |
| Variables globales sueltas | Todo dentro de `context`; no contaminar el namespace |
| `call/shell` sin validar entrada | Inyección de comandos; pasar por `validator` primero |
| Código comentado ("por si acaso") | Si no se usa, se borra. Git tiene historial. |
| Nombres de una letra (`x`, `i`, `n`) | Excepto en bucles triviales de < 3 líneas |
| Funciones de más de 50 líneas | Dividir en subfunciones con nombres descriptivos |
| Más de 3 niveles de anidamiento | Extraer a funciones o usar early return |

---

## 8. Commits

### Formato del mensaje

```
<tipo>: <descripción breve>

<cuerpo opcional con más detalle>
```

### Tipos permitidos

| Tipo | Uso |
|------|-----|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Cambio interno sin cambio de comportamiento |
| `docs` | Solo cambios en documentación |
| `test` | Añadir o modificar tests |
| `chore` | Mantenimiento (build scripts, gitignore, etc.) |

### Ejemplos

```
feat: añadir soporte para versionado con tags

El formato extendido de deps.red ahora acepta bloques con
especificación de tag, branch o commit.

Formato: NombrePkg ["url" tag: "v1.0.0"]
```

```
fix: eliminar probe debug en cmd-remove
```

### Regla de oro

Cada commit deja el build funcional. Si el smoke test no pasa, el commit no
se hace.

---

*Estas convenciones se aprenden usándolas. 
En caso de duda, priorizar la legibilidad sobre la elegancia.*
