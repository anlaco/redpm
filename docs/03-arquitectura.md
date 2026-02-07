# Arquitectura de Software

> **Diseño de la estructura interna de redpm**
> Última actualización: 7 de febrero de 2026
> Autor: Dirección técnica — ANLACO

---

## Principio rector

> *"La complejidad se gestiona partiendo en trozos que se pueden entender por
> separado."*

La arquitectura de redpm se basa en una idea simple: **cada subsistema sabe
hacer una cosa, oculta cómo lo hace, y expone solo lo necesario**.

En Red, el mecanismo para esto es `context`. Cada módulo es un `context` que
encapsula sus datos y funciones internas, exponiendo solo la interfaz pública.

---

## Diagrama de subsistemas

```
┌─────────────────────────────────────────────────────────┐
│                      redpm.red                           │
│              (Entry point: CLI dispatch)                 │
│                                                          │
│   Lee los argumentos de línea de comandos y delega al    │
│   subsistema correspondiente. NO contiene lógica de     │
│   negocio.                                               │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                     MANAGER                              │
│               (src/manager.red)                          │
│                                                          │
│   Lógica de negocio: install, update, remove, list.      │
│   Orquesta los demás subsistemas.                        │
│   NO sabe nada de git, archivos, ni formatos.            │
├──────────────┬──────────────┬───────────────────────────┤
│              │              │                            │
│              ▼              ▼                            │
│   ┌──────────────┐ ┌──────────────┐  ┌───────────────┐ │
│   │   REGISTRY   │ │  GIT-CLIENT  │  │  FILESYSTEM   │ │
│   │(src/registry │ │(src/git-     │  │(src/filesystem│ │
│   │      .red)   │ │  client.red) │  │        .red)  │ │
│   ├──────────────┤ ├──────────────┤  ├───────────────┤ │
│   │Leer/escribir │ │Clonar repos  │  │Crear/borrar   │ │
│   │deps.red      │ │Hacer pull    │  │directorios    │ │
│   │Leer/escribir │ │Obtener SHA   │  │Comprobar      │ │
│   │deps.lock     │ │Checkout tag  │  │existencia     │ │
│   │Transformar   │ │              │  │Listar archivos│ │
│   │formato ↔ ADT │ │              │  │               │ │
│   └──────────────┘ └──────────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐
│    VALIDATOR      │  │     LOGGER        │
│ (src/validator   │  │ (src/logger.red)  │
│         .red)    │  │                    │
├──────────────────┤  ├──────────────────┤
│ Sanitizar URLs   │  │ print-ok/err/     │
│ Validar nombres  │  │   info/warn       │
│ Verificar        │  │ Colores ANSI      │
│   formato de     │  │ Niveles de        │
│   deps.red       │  │   verbosidad      │
│ Verificar        │  │ Adaptación por    │
│   respuestas git │  │   plataforma      │
└──────────────────┘  └──────────────────┘

┌──────────────────┐
│    PACKAGE (ADT)  │
│ (src/package.red) │
├──────────────────┤
│ Definición del   │
│   tipo "paquete" │
│ Constructores    │
│ Accesores        │
│ Predicados       │
└──────────────────┘
```

---

## Estructura de archivos (objetivo post-Sprint 1)

```
redpm/
├── redpm.red                 ;-- Entry point: solo CLI dispatch
│
├── src/                      ;-- Código fuente modular
│   ├── package.red           ;-- ADT del paquete
│   ├── registry.red          ;-- Lectura/escritura de deps.red y deps.lock
│   ├── git-client.red        ;-- Wrapper sobre operaciones git
│   ├── filesystem.red        ;-- Operaciones de archivos cross-platform
│   ├── manager.red           ;-- Lógica de negocio
│   ├── validator.red         ;-- Barricada: sanitización de inputs
│   └── logger.red            ;-- Output con colores y niveles
│
├── tests/                    ;-- Tests
│   └── smoke-test.red        ;-- Test end-to-end básico
│
├── docs/                     ;-- Documentación de ingeniería
│   ├── README.md             ;-- Índice de documentos
│   ├── 01-definicion-del-problema.md
│   ├── 02-plan-maestro.md
│   ├── 03-arquitectura.md    ;-- Este documento
│   ├── 04-convenciones-de-codigo.md
│   └── 05-guia-de-calidad.md
│
├── deps.red                  ;-- Dependencias de redpm (el propio proyecto)
├── Makefile                  ;-- Build script
├── README.md                 ;-- Guía de usuario
├── ROADMAP.md                ;-- Hoja de ruta pública
└── .gitignore
```

---

## Descripción de cada subsistema

### 1. Entry Point (`redpm.red`)

**Responsabilidad:** Leer los argumentos de la línea de comandos y delegar al
subsistema `manager`.

**Lo que hace:**
- Parsear `system/options/args`
- Validar que el comando existe
- Llamar a la función correspondiente de `manager`
- Devolver código de salida apropiado

**Lo que NO hace:**
- No contiene lógica de negocio
- No manipula archivos directamente
- No ejecuta comandos git

**Pseudocódigo:**

```
Programa principal:
  Leer argumentos de la línea de comandos
  Si no hay argumentos → mostrar ayuda
  Si git no está disponible → error y salir
  Según el primer argumento:
    "init"    → manager/inicializar-proyecto
    "install" → manager/instalar-dependencias
    "update"  → manager/actualizar-dependencias
    "remove"  → manager/eliminar-paquete (segundo argumento)
    "list"    → manager/listar-dependencias
    "tree"    → manager/mostrar-arbol
    "help"    → mostrar-ayuda
    otro      → error: comando desconocido
```

---

### 2. Package ADT (`src/package.red`)

**Responsabilidad:** Definir qué es un "paquete" conceptualmente.

**Estructura del tipo:**

```
Un paquete tiene:
  - name:     string!   → Nombre legible (ej. "Red-Serial")
  - url:      url!      → URL del repositorio origen
  - version:  string!   → Especificación de versión ("latest", "v1.0", sha...)
  - ver-type: word!     → Tipo de versión: 'latest | 'tag | 'branch | 'commit
  - status:   word!     → Estado local: 'installed | 'missing | 'outdated
  - path:     file!     → Directorio local donde está instalado
```

**Operaciones públicas:**

| Función | Entrada | Salida | Descripción |
|---------|---------|--------|-------------|
| `make-package` | name, url, version | package object | Constructor |
| `package-name` | package | string! | Obtener nombre |
| `package-url` | package | url! | Obtener URL |
| `package-installed?` | package | logic! | ¿Está instalado localmente? |
| `package-outdated?` | package | logic! | ¿Hay actualizaciones disponibles? |

**Principio:** Ningún otro subsistema accede a los campos internos del paquete
directamente. Siempre a través de estas funciones.

---

### 3. Registry (`src/registry.red`)

**Responsabilidad:** Leer y escribir `deps.red` y `deps.lock`. Transformar
entre el formato de archivo y el ADT de paquete.

**Operaciones públicas:**

| Función | Descripción |
|---------|-------------|
| `load-packages` | Leer `deps.red` y devolver una lista de objetos package |
| `save-packages` | Escribir una lista de packages a `deps.red` |
| `load-lockfile` | Leer `deps.lock` y devolver un mapa de nombre → commit |
| `save-lockfile` | Escribir el lockfile con los commits actuales |
| `create-default-config` | Crear un `deps.red` inicial (para `init`) |

**Lo que oculta:** El formato exacto del archivo. Si mañana cambiamos la
sintaxis de `deps.red`, solo cambia este módulo.

---

### 4. Git Client (`src/git-client.red`)

**Responsabilidad:** Toda interacción con el ejecutable `git`.

**Operaciones públicas:**

| Función | Descripción |
|---------|-------------|
| `git-available?` | Verificar que git está instalado |
| `clone-repo` | Clonar un repositorio (con depth 1) |
| `pull-repo` | Hacer pull en un repositorio existente |
| `checkout-version` | Hacer checkout de un tag, branch o commit |
| `get-current-sha` | Obtener el SHA del commit actual |
| `repo-has-changes?` | ¿Hay cambios locales sin commitear? |

**Lo que oculta:** Los comandos shell exactos, el parseo de la salida de git,
las diferencias de comportamiento entre plataformas.

**Barricada:** Toda entrada (URLs, paths) se valida ANTES de pasarla a `call`.
Toda salida de `call` se parsea y verifica ANTES de devolverla.

---

### 5. Filesystem (`src/filesystem.red`)

**Responsabilidad:** Operaciones de directorio y archivos cross-platform.

**Operaciones públicas:**

| Función | Descripción |
|---------|-------------|
| `ensure-dir` | Crear directorio si no existe (con padres) |
| `remove-dir` | Eliminar directorio recursivamente |
| `dir-exists?` | Verificar si un directorio existe |
| `list-subdirs` | Listar subdirectorios de una ruta |

**Lo que oculta:** Las diferencias entre Linux (`/`), Windows (`\`), la
implementación de borrado recursivo (.que hoy está en Red-Utils).

---

### 6. Validator (`src/validator.red`)

**Responsabilidad:** La barricada. Todo dato externo pasa por aquí antes de
entrar a la lógica interna.

**Operaciones públicas:**

| Función | Entrada | Validación |
|---------|---------|-----------|
| `valid-url?` | string | ¿Es una URL HTTPS/HTTP válida de un repositorio git? |
| `valid-package-name?` | string | ¿Contiene solo caracteres permitidos? ¿Longitud razonable? |
| `valid-version-spec?` | string | ¿Es un tag, branch o SHA válido? |
| `sanitize-path` | string | Eliminar `..`, caracteres especiales, path traversal |

**Principio:** Es mejor rechazar una entrada válida que aceptar una peligrosa.

---

### 7. Logger (`src/logger.red`)

**Responsabilidad:** Toda salida al usuario.

**Operaciones públicas:**

| Función | Descripción |
|---------|-------------|
| `log-ok` | Mensaje de éxito (verde) |
| `log-error` | Mensaje de error (rojo) |
| `log-info` | Mensaje informativo (cyan) |
| `log-warn` | Mensaje de advertencia (amarillo) |
| `log-debug` | Solo visible si el flag `--verbose` está activo |

**Lo que oculta:** Los códigos ANSI, la detección de si la terminal soporta
colores, el nivel de verbosidad actual.

---

## Reglas de dependencia entre subsistemas

```
redpm.red → manager → registry, git-client, filesystem, validator, logger
                       registry → package, validator, logger
                       git-client → validator, logger
                       filesystem → logger
                       validator → (sin dependencias internas)
                       logger → (sin dependencias internas)
                       package → (sin dependencias internas)
```

**Regla:** Las dependencias fluyen siempre hacia abajo. Nunca un módulo de
nivel inferior depende de uno de nivel superior. `logger`, `validator` y
`package` son los módulos base sin dependencias.

---

## Flujo de una operación: `redpm install`

Para entender cómo colaboran los subsistemas, este es el flujo completo de un
`redpm install`:

```
1. [redpm.red]    Parsea args → detecta comando "install"
2. [redpm.red]    Llama a manager/install-all
3. [manager]      Llama a registry/load-packages → obtiene lista de package!
4. [manager]      Para cada paquete:
   a. [manager]     ¿Existe lockfile? → registry/load-lockfile
   b. [manager]     ¿Ya está instalado? → package/installed?
   c. [manager]     Si no: filesystem/ensure-dir
   d. [manager]     git-client/clone-repo (con url y version del package)
   e. [manager]     git-client/get-current-sha → obtener commit real
   f. [manager]     Acumular info para lockfile
   g. [logger]      log-ok "Paquete X instalado"
5. [manager]      registry/save-lockfile (con todos los SHAs)
6. [logger]       log-ok "Hecho!"
```

---

## Decisiones de diseño importantes

### ¿Por qué `context` y no archivos separados sin encapsulación?

Porque `context` en Red es el mecanismo nativo para **ocultar información**.
Sin él, todas las funciones y variables son globales y pueden colisionar.
Con `context`, cada módulo tiene su espacio de nombres privado.

### ¿Por qué un ADT para paquete y no un simple `block!`?

Porque un `block!` es transparente — cualquiera puede acceder a cualquier
posición por índice. Eso crea **acoplamiento**: si cambiamos el orden de los
campos, se rompe todo el código que accede por posición.

Con un ADT, el acceso es por nombre (semántico) y la representación interna
se puede cambiar sin afectar al resto.

### ¿Por qué una barricada (validator) separada?

Porque los datos del exterior son "sucios" por definición. Un URL puede tener
inyección de comandos. Un nombre de paquete puede contener `../` para escapar
del directorio. La barricada centraliza toda la sanitización en un solo punto,
en lugar de dispersar validaciones por todo el código.

---

*Este documento se actualiza cada vez que cambia la arquitectura. Los cambios
se discuten antes de implementarse.*
