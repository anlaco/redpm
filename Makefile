# PSEUDOCÓDIGO (PPP)
# Objetivo: Makefile mínimo para Sprint 0 — sólo lo necesario.
#
# METADATOS
# - Archivo: Makefile
# - Targets: build, clean, help
# - Principio: implementar sólo lo requerido en Sprint 0 (Principio 5).
#
# PRERREQUISITOS
# 1. Verificar que ./redc exista y sea ejecutable. Si no, abortar con mensaje.
#
# TARGET: build
# - Crear `bin/` si no existe
# - Ejecutar el comando de compilación del proyecto:
#     ./redc -r -o redpm redpm.red
# - Mover el binario resultante a `bin/` (si fue generado en el cwd)
# - Establecer permisos ejecutables (chmod +x) cuando aplique
# - En caso de fallo, imprimir la salida y devolver código != 0
#
# TARGET: clean
# - Eliminar `bin/` y artefactos generados por la compilación (p. ej. libRedRT*)
# - Ser idempotente (no fallar si ya están ausentes)
#
# TARGET: help
# - Mostrar uso mínimo y prerequisitos
#
# CRITERIO DE ACEPTACIÓN
# - Un contribuidor ejecuta `make build` y obtiene `bin/redpm` ejecutable

.PHONY: all build clean help check-prereqs
.PHONY: build-debug-env

# Use bash for recipe execution so behavior matches interactive shell
SHELL := /bin/bash

# Export PATH so make recipes inherit the interactive PATH
export PATH

all: build

check-prereqs:
	@if [ ! -x ./redc ]; then \
		echo "Error: ./redc not found or not executable. Build requires the local ./redc compiler."; \
		exit 1; \
	fi

build: check-prereqs
	@mkdir -p bin
	@echo "Compiling redpm with ./redc..."
	@./redc -r -o redpm redpm.red
	@# Move binary to bin/ if produced in current directory
	@if [ -f redpm ]; then \
		mv -f redpm bin/; \
		chmod +x bin/redpm 2>/dev/null || true; \
		echo "Built: bin/redpm"; \
	else \
		echo "Warning: build finished but no 'redpm' binary found in cwd"; \
		false; \
	fi

clean:
	@rm -rf bin/
	@rm -f libRedRT* 2>/dev/null || true
	@echo "Cleaned build artifacts"

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build   Compile project using ./redc -r -o redpm redpm.red and place binary in bin/"
	@echo "  clean   Remove build artifacts (bin/, libRedRT*)"
	@echo "  help    Show this message"
	@echo ""
	@echo "Prerequisites: ./redc must be present and executable in repository root"
