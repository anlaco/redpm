# Guía de Calidad y Revisión

> **Checklist de verificación y procesos de calidad para redpm**
> Última actualización: 7 de febrero de 2026
> Autor: Dirección técnica — ANLACO

---

## Propósito de este documento

Este documento define **cómo verificamos que el software está bien hecho**.
No basta con que funcione — tiene que ser mantenible, robusto y comprensible.

Las inspecciones de código encuentran hasta el 60% de los defectos, mucho más
que el testing solitario. Este documento es la herramienta del equipo para
hacer esas inspecciones de forma sistemática.

---

## 1. Checklist de revisión de código

Antes de aprobar cualquier cambio (pull request, merge, o entrega de sprint),
el director y el equipo verifican estos puntos:

### Arquitectura y diseño

- [ ] **¿Está dentro de un `context`?** Toda función y variable nueva debe
  vivir dentro del contexto apropiado. No se permiten funciones globales sueltas.

- [ ] **¿Respeta las dependencias?** Un módulo de nivel bajo (`logger`,
  `validator`, `package`) nunca importa uno de nivel alto (`manager`).
  Ver [03-arquitectura.md](03-arquitectura.md).

- [ ] **¿El paquete se manipula solo a través del ADT?** Nadie accede
  directamente a los campos internos de un paquete. Se usan los accesores.

- [ ] **¿Se ha evitado código especulativo?** No se escribe código para
  funcionalidades que "podrían necesitarse algún día". Si no está en el sprint
  actual, no existe.

### Legibilidad y nombres

- [ ] **¿Los nombres dicen QUÉ, no CÓMO?** `install-package` sí,
  `git-clone-into-deps` no.

- [ ] **¿Se entiende sin comentarios?** Si el código necesita un comentario
  para entenderse, probablemente debería reescribirse con mejores nombres.

- [ ] **¿Los comentarios explican el POR QUÉ?** Los comentarios existentes
  deben explicar la intención o decisiones no obvias, nunca parafrasear el código.

- [ ] **¿Menos de 50 líneas por función?** Si no, dividir.

- [ ] **¿Menos de 3 niveles de anidamiento?** Si no, extraer o usar early return.

### Robustez

- [ ] **¿Se validan los inputs externos?** Toda entrada del usuario, de archivos,
  o de git pasa por el `validator` antes de usarse.

- [ ] **¿Se manejan los errores?** Toda operación de I/O está envuelta en
  `try`/`attempt` con mensajes descriptivos.

- [ ] **¿Los mensajes de error son útiles?** Deben decir: qué falló, por qué
  (si se sabe), y qué puede hacer el usuario.

- [ ] **¿Se ha probado el caso límite?** ¿Qué pasa si el archivo no existe?
  ¿Si la URL es inválida? ¿Si no hay internet? ¿Si el disco está lleno?

### Higiene

- [ ] **¿No hay `probe` ni código debug?** Solo `logger/log-debug` para
  debugging, y solo se ve con `--verbose`.

- [ ] **¿No hay código comentado?** Si no se usa, se borra. Git lo recuerda.

- [ ] **¿El commit message sigue el formato?** `tipo: descripción breve`.

- [ ] **¿El smoke test pasa?** (después del Sprint 3)

---

## 2. Proceso de Programación con Pseudocódigo (PPP)

Para funciones no triviales, el proceso es:

### Paso 1: Pseudocódigo

El desarrollador (humano o IA) escribe el algoritmo en **lenguaje natural**,
enfocado en el **intento** (qué se quiere lograr), no en la sintaxis.

```
Para instalar un paquete:
  Primero verificar que la URL es válida
  Luego crear el directorio de destino si no existe
  Después clonar el repositorio con profundidad 1
  Si el clonado falló, informar al usuario y limpiar
  Si tuvo éxito, registrar el SHA del commit en el lockfile
  Finalmente confirmar la instalación al usuario
```

### Paso 2: Revisión

El director (o un compañero) revisa el pseudocódigo y verifica:

- ¿Se manejan todos los caminos (éxito y error)?
- ¿Hay pasos que se podrían simplificar?
- ¿Falta algún caso límite?

### Paso 3: Pseudocódigo → Comentarios

El pseudocódigo aprobado se convierte en los comentarios del archivo:

```red
install-single: func [pkg [object!]] [
    ;-- Verificar que la URL es válida
    unless validator/valid-url? package/get-url pkg [...]
    
    ;-- Crear el directorio de destino si no existe
    filesystem/ensure-dir package/get-path pkg
    
    ;-- Clonar el repositorio con profundidad 1
    result: git-client/clone-repo ...
    
    ;-- Si el clonado falló, informar y limpiar
    unless result [...]
    
    ;-- Registrar el SHA del commit en el lockfile
    sha: git-client/get-current-sha ...
    
    ;-- Confirmar la instalación al usuario
    logger/log-ok rejoin [...]
]
```

### Paso 4: Código

El código real se escribe debajo de cada comentario.

---

## 3. Niveles de testing

### Nivel 0: Smoke test (desde Sprint 0)

**Manual.** Verificar que los comandos básicos no crashean:

```bash
./redpm help                  # ¿Muestra ayuda?
./redpm init                  # ¿Crea deps.red?
./redpm install               # ¿Instala las dependencias?
./redpm list                  # ¿Lista correctamente?
./redpm remove Red-Utils      # ¿Elimina?
```

Ejecutar este checklist después de cada cambio significativo.

### Nivel 1: Smoke test automatizado (desde Sprint 3)

**Script Red** que ejecuta el flujo completo en un directorio temporal y
verifica resultados:

```
Crear directorio temporal
Ejecutar redpm init → verificar que deps.red existe
Editar deps.red con una dependencia real
Ejecutar redpm install → verificar que deps/ tiene el paquete
Ejecutar redpm list → verificar que muestra "●" (instalado)
Ejecutar redpm update → verificar que no crashea
Ejecutar redpm remove → verificar que el paquete ya no existe
Limpiar directorio temporal
Reportar: X de Y tests pasaron
```

### Nivel 2: Tests unitarios (desde Sprint 4)

**Tests por módulo** que verifican casos límite:

| Módulo | Casos a probar |
|--------|---------------|
| `validator` | URL vacía, URL sin protocolo, URL con inyección de comandos, nombre con `../`, nombre vacío, nombre muy largo |
| `registry` | `deps.red` vacío, malformado, con formato viejo, con formato nuevo, inexistente |
| `package` | Crear paquete con todos los campos, con campos faltantes, predicados |
| `git-client` | Repo inexistente, sin conexión, git no instalado |
| `filesystem` | Directorio ya existe, permisos insuficientes, path con espacios |

### Mini-framework de asserts

Ya que Red no tiene un framework de testing estándar, crearemos uno mínimo:

```red
;-- Pseudocódigo del framework de testing
assert-true:  [condición mensaje-si-falla]
assert-false: [condición mensaje-si-falla]
assert-equal: [valor-esperado valor-real mensaje-si-falla]
run-tests:    [bloque-de-tests] → reporte de resultados
```

---

## 4. Regla del Cardenal de la Refactorización

> *Cada cambio debe dejar el código mejor de lo que estaba.*

### Señales de que hay que refactorizar

| Señal | Acción |
|-------|--------|
| Función de más de 50 líneas | Dividir en subfunciones |
| Más de 3 niveles de anidamiento | Extraer función o usar early return |
| Código duplicado en 2+ sitios | Extraer a función compartida |
| Nombre que ya no refleja lo que hace | Renombrar |
| Comentario que dice "esto es un hack" | Buscar la solución correcta |
| Variable que se modifica en 5+ sitios | Encapsular en función |

### Proceso de refactorización

1. Verificar que el smoke test pasa (estado inicial bueno).
2. Hacer el cambio de refactorización (solo estructura, no comportamiento).
3. Verificar que el smoke test sigue pasando (mismo comportamiento).
4. Commit separado: `refactor: <descripción>`.

**Nunca** mezclar refactorización con funcionalidad nueva en el mismo commit.

---

## 5. Gestión de configuración (control de versiones)

### Branches

| Branch | Propósito |
|--------|-----------|
| `main` | Código estable. Siempre compila y pasa el smoke test. |
| `sprint-N` | Rama de trabajo para el sprint N. Se mergea a `main` al terminar. |
| `feat/nombre` | Feature branches para funcionalidades grandes dentro de un sprint. |

### Tags

Cada versión entregable recibe un tag:

```
v0.1.1  → Sprint 0 completado
v0.2.0  → Sprint 1 completado
v0.2.1  → Sprint 2 completado
v0.3.0  → Sprint 3 completado
v0.4.0  → Sprint 4 completado
```

### Regla de `main`

Un commit solo llega a `main` si:

1. El smoke test pasa.
2. El código ha sido revisado con el checklist de arriba.
3. El mensaje de commit sigue el formato establecido.

---

## 6. Deuda técnica conocida (inventario)

Esta tabla se mantiene actualizada. Registra los problemas técnicos conocidos
que aún no se han corregido, para que no se olviden ni se "descubran" por
sorpresa.

| # | Descripción | Sprint donde se detectó | Sprint donde se arregla | Estado |
|---|-------------|------------------------|------------------------|--------|
| DT-01 | Artefactos binarios trackeados en git | Pre-Sprint 0 | Sprint 0 | Pendiente |
| DT-02 | `probe` debug en `cmd-remove` | Pre-Sprint 0 | Sprint 0 | Pendiente |
| DT-03 | Variables globales sin encapsular | Pre-Sprint 0 | Sprint 1 | Pendiente |
| DT-04 | Sin validación de inputs externos | Pre-Sprint 0 | Sprint 1 | Pendiente |
| DT-05 | Colores ANSI no funcionan en Windows | Pre-Sprint 0 | Sprint 2 | Pendiente |
| DT-06 | `call/shell` sin verificar retorno | Pre-Sprint 0 | Sprint 2 | Pendiente |
| DT-07 | Sin tests | Pre-Sprint 0 | Sprint 3 | Pendiente |

Se añaden nuevas entradas conforme se descubren. Se marcan como "Resuelto" al
corregirse, pero no se eliminan del inventario (sirven como historial).

---

## 7. Criterio para "Hecho" (Definition of Done)

Una tarea de un sprint se considera **completada** cuando:

1. ✅ El código cumple todos los puntos del checklist de revisión.
2. ✅ El smoke test pasa (manual o automatizado según el sprint).
3. ✅ La documentación afectada está actualizada.
4. ✅ El commit message sigue el formato.
5. ✅ No se ha introducido deuda técnica nueva sin registrarla.

Un sprint se considera **completado** cuando:

1. ✅ Todas las tareas del sprint están "hechas".
2. ✅ El tag de versión correspondiente está creado.
3. ✅ El plan maestro está actualizado con los aprendizajes.
4. ✅ El inventario de deuda técnica está al día.

---

*La calidad no es un paso final — es el modo de trabajar.*
