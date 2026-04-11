#!/usr/bin/env bash
#
# ===================================================================
#  ROAST MY FILES
# -------------------------------------------------------------------
#  Proyecto Integrador — Sistemas Operativos
#  Tema: Gestor de búsqueda de contenidos en archivos de texto
#
#  Script Bash interactivo con interfaz TUI (dialog) que funciona
#  como un gestor completo de búsqueda de contenidos en archivos de
#  texto (modo serio), y además incluye un modo "roast" que analiza
#  la carpeta del usuario y se burla de ella con datos reales.
#
#  Uso:
#      ./roast.sh [-d DIR] [--no-color] [-h] [-v]
#
#  Dependencias obligatorias:
#      bash, grep, awk, sed, find, wc, sort, uniq, tr, cut, head,
#      tail, stat, mktemp, tput
#
#  Dependencias decorativas (con fallback):
#      dialog, figlet, lolcat, boxes, pv, fzf, shuf
# ===================================================================

# -------------------------------------------------------------------
# Modo estricto: aborta ante errores, variables no definidas y
# fallas en pipelines. Clave para detectar bugs temprano.
#   -e             salir si un comando falla
#   -u             error si se usa una variable no definida
#   -o pipefail    el exit code del pipe es el primero que falló
# -------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# ===================================================================
# CONSTANTES GLOBALES
# -------------------------------------------------------------------
# SCRIPT_DIR se calcula resolviendo el path absoluto de este archivo
# para que los `source` funcionen sin importar desde qué cwd se
# invoque el script.
# ===================================================================
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly DATA_DIR="${SCRIPT_DIR}/data"
readonly REPORTES_DIR="${SCRIPT_DIR}/reportes"

readonly NOMBRE_PROYECTO="Roast My Files"
readonly VERSION="1.0.0"
readonly AUTORES="Proyecto Integrador — Sistemas Operativos"

# ===================================================================
# FLAGS GLOBALES (modificadas por parsear_argumentos)
# ===================================================================
DIRECTORIO_VICTIMA=""
USAR_COLOR=1

# ===================================================================
# CARGA DE MÓDULOS
# -------------------------------------------------------------------
# El orden importa:
#   1. utils.sh  — define logs, colores, traps y helpers
#   2. deps.sh   — chequea qué hay instalado (usa logs de utils)
#   3. ui.sh     — wrappers de interfaz (consulta flags de deps)
#   4. stats.sh  — motor de análisis (usa tempfiles de utils)
#   5. search.sh — modo serio (usa stats + ui)
#   6. roasts.sh — roasts (usa stats + ui)
#   7. report.sh — exportación (usa stats + ui)
#   8. menu.sh   — menús principales (usa todo)
# ===================================================================
# shellcheck source=lib/utils.sh
source "${LIB_DIR}/utils.sh"
# shellcheck source=lib/deps.sh
source "${LIB_DIR}/deps.sh"
# shellcheck source=lib/ui.sh
source "${LIB_DIR}/ui.sh"
# shellcheck source=lib/stats.sh
source "${LIB_DIR}/stats.sh"
# shellcheck source=lib/search.sh
source "${LIB_DIR}/search.sh"
# shellcheck source=lib/roasts.sh
source "${LIB_DIR}/roasts.sh"
# shellcheck source=lib/report.sh
source "${LIB_DIR}/report.sh"
# shellcheck source=lib/menu.sh
source "${LIB_DIR}/menu.sh"

# ===================================================================
# AYUDA Y VERSIÓN
# ===================================================================

# -------------------------------------------------------------------
# mostrar_ayuda - imprime el mensaje de --help.
# -------------------------------------------------------------------
mostrar_ayuda() {
    cat <<EOF
${NOMBRE_PROYECTO} v${VERSION}
${AUTORES}

DESCRIPCIÓN
    Gestor de búsqueda de contenidos en archivos de texto con un
    modo "roast" que analiza tu carpeta y se burla de ella.

USO
    ./roast.sh [OPCIONES]

OPCIONES
    -d DIR          Carpeta víctima a analizar (si no se pasa, se
                    pregunta interactivamente al iniciar).
    --no-color      Desactiva los colores ANSI y lolcat.
    -h, --help      Muestra esta ayuda y sale.
    -v, --version   Muestra la versión y sale.

EJEMPLOS
    ./roast.sh
    ./roast.sh -d ~/apuntes
    ./roast.sh -d ./test_files --no-color

CÓDIGOS DE SALIDA
    0   éxito
    1   error general
    2   falta una dependencia obligatoria
    3   input inválido
    130 cancelado por el usuario (Ctrl+C)
EOF
}

# -------------------------------------------------------------------
# mostrar_version - imprime nombre + versión y sale.
# -------------------------------------------------------------------
mostrar_version() {
    printf '%s v%s\n' "${NOMBRE_PROYECTO}" "${VERSION}"
}

# ===================================================================
# PARSEO DE ARGUMENTOS
# ===================================================================

# -------------------------------------------------------------------
# parsear_argumentos - procesa los argumentos de línea de comandos.
# Modifica las variables globales DIRECTORIO_VICTIMA y USAR_COLOR.
# args: los argumentos originales del script ($@)
# -------------------------------------------------------------------
parsear_argumentos() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)
                if [[ -z "${2:-}" ]]; then
                    die "La opción -d requiere un directorio como argumento" 3
                fi
                DIRECTORIO_VICTIMA="$2"
                shift 2
                ;;
            --no-color)
                USAR_COLOR=0
                shift
                ;;
            -h|--help)
                mostrar_ayuda
                exit 0
                ;;
            -v|--version)
                mostrar_version
                exit 0
                ;;
            *)
                err "Argumento desconocido: $1"
                echo "Usá -h para ver la ayuda." >&2
                exit 3
                ;;
        esac
    done
}

# ===================================================================
# MAIN
# ===================================================================

# -------------------------------------------------------------------
# main - punto de entrada del script.
# -------------------------------------------------------------------
main() {
    # 1. Parsear argumentos antes que nada
    parsear_argumentos "$@"

    # 2. Instalar traps de limpieza (Ctrl+C, errores, salida normal)
    instalar_trap_limpieza

    # 3. Chequear dependencias (aborta si falta algo obligatorio)
    deps_check

    # 4. Splash de bienvenida con banner
    ui_splash

    # 5. Si no se pasó -d, pedir la carpeta víctima
    if [[ -z "${DIRECTORIO_VICTIMA}" ]]; then
        menu_pedir_directorio_victima
    else
        # Validar el -d que pasó el usuario
        if ! require_dir "${DIRECTORIO_VICTIMA}"; then
            die "El directorio pasado con -d no es válido: ${DIRECTORIO_VICTIMA}" 3
        fi
    fi

    # 6. Loop del menú principal
    menu_main

    # 7. Despedida
    clear 2>/dev/null || true
    ui_banner "CHAU"
    echo
    if (( HAS_LOLCAT == 1 )) && (( USAR_COLOR == 1 )); then
        echo "  Gracias por usar ${NOMBRE_PROYECTO}. Tus archivos no." | lolcat
    else
        echo "  Gracias por usar ${NOMBRE_PROYECTO}. Tus archivos no."
    fi
    echo
}

# -------------------------------------------------------------------
# Ejecutar main con todos los argumentos.
# -------------------------------------------------------------------
main "$@"
