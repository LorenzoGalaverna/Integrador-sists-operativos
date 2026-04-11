#!/usr/bin/env bash
#
# lib/utils.sh
# -------------------------------------------------------------------
# Helpers genéricos del proyecto: logging, errores, traps, cleanup,
# validaciones de paths y tempfiles.
#
# Este archivo no se ejecuta solo: se carga con `source` desde roast.sh
# después de que las variables globales estén definidas.
#
# Expone (funciones públicas):
#   err "mensaje"                 -> imprime error a stderr
#   die "mensaje" [codigo]        -> err + exit
#   log_info  "mensaje"           -> log informativo a stderr
#   log_warn  "mensaje"           -> warning a stderr
#   log_ok    "mensaje"           -> mensaje de éxito a stderr
#   require_dir "path"            -> valida que una ruta sea un dir legible
#   confirm "pregunta"            -> sí/no interactivo
#   crear_tempfile                -> mktemp registrado para limpieza
#   instalar_trap_limpieza        -> instala traps EXIT/INT/TERM
# -------------------------------------------------------------------

# ===================================================================
# COLORES ANSI
# -------------------------------------------------------------------
# Solo se activan si stderr es una terminal (-t 2) y el usuario no
# pidió --no-color. Si no, los códigos quedan vacíos y los mensajes
# salen como texto plano.
# ===================================================================
if [[ -t 2 ]] && [[ "${USAR_COLOR:-1}" == "1" ]]; then
    COLOR_ROJO=$'\033[0;31m'
    COLOR_VERDE=$'\033[0;32m'
    COLOR_AMARILLO=$'\033[0;33m'
    COLOR_AZUL=$'\033[0;34m'
    COLOR_MAGENTA=$'\033[0;35m'
    COLOR_CYAN=$'\033[0;36m'
    COLOR_NEGRITA=$'\033[1m'
    COLOR_RESET=$'\033[0m'
else
    COLOR_ROJO=""
    COLOR_VERDE=""
    COLOR_AMARILLO=""
    COLOR_AZUL=""
    COLOR_MAGENTA=""
    COLOR_CYAN=""
    COLOR_NEGRITA=""
    COLOR_RESET=""
fi
readonly COLOR_ROJO COLOR_VERDE COLOR_AMARILLO COLOR_AZUL
readonly COLOR_MAGENTA COLOR_CYAN COLOR_NEGRITA COLOR_RESET

# ===================================================================
# ESTADO INTERNO
# -------------------------------------------------------------------
# Lista de archivos temporales que hay que borrar cuando el script
# termina (se limpian en el trap EXIT).
# ===================================================================
declare -a TEMPFILES_A_LIMPIAR=()

# ===================================================================
# LOGGING
# ===================================================================

# -------------------------------------------------------------------
# err - imprime un mensaje de error a stderr con prefijo rojo.
# args:
#   $1 - mensaje a mostrar
# -------------------------------------------------------------------
err() {
    printf '%s[ERROR]%s %s\n' "${COLOR_ROJO}" "${COLOR_RESET}" "$1" >&2
}

# -------------------------------------------------------------------
# die - imprime error y sale con el código dado.
# args:
#   $1 - mensaje de error
#   $2 - código de salida (opcional, default 1)
# -------------------------------------------------------------------
die() {
    err "$1"
    exit "${2:-1}"
}

# -------------------------------------------------------------------
# log_info - mensaje informativo neutro.
# Va a stderr para no ensuciar la stdout (que puede estar siendo
# capturada por otro comando).
# -------------------------------------------------------------------
log_info() {
    printf '%s[INFO]%s %s\n' "${COLOR_AZUL}" "${COLOR_RESET}" "$1" >&2
}

# -------------------------------------------------------------------
# log_warn - advertencia (no es error fatal).
# -------------------------------------------------------------------
log_warn() {
    printf '%s[WARN]%s %s\n' "${COLOR_AMARILLO}" "${COLOR_RESET}" "$1" >&2
}

# -------------------------------------------------------------------
# log_ok - mensaje de éxito.
# -------------------------------------------------------------------
log_ok() {
    printf '%s[OK]%s %s\n' "${COLOR_VERDE}" "${COLOR_RESET}" "$1" >&2
}

# ===================================================================
# VALIDACIONES
# ===================================================================

# -------------------------------------------------------------------
# require_dir - valida que la ruta exista, sea directorio y legible.
# args:
#   $1 - ruta a validar
# return:
#   0 si la ruta es válida
#   3 si hay algún problema (con mensaje de error mostrado)
# -------------------------------------------------------------------
require_dir() {
    local ruta="$1"

    if [[ -z "${ruta}" ]]; then
        err "La ruta está vacía"
        return 3
    fi
    if [[ ! -e "${ruta}" ]]; then
        err "La ruta no existe: ${ruta}"
        return 3
    fi
    if [[ ! -d "${ruta}" ]]; then
        err "La ruta no es un directorio: ${ruta}"
        return 3
    fi
    if [[ ! -r "${ruta}" ]]; then
        err "Sin permisos de lectura sobre: ${ruta}"
        return 3
    fi
    return 0
}

# -------------------------------------------------------------------
# require_file - valida que un archivo exista y sea legible.
# args:
#   $1 - ruta del archivo
# return:
#   0 si ok, 3 si no
# -------------------------------------------------------------------
require_file() {
    local ruta="$1"

    if [[ -z "${ruta}" ]]; then
        err "La ruta del archivo está vacía"
        return 3
    fi
    if [[ ! -f "${ruta}" ]]; then
        err "No es un archivo regular: ${ruta}"
        return 3
    fi
    if [[ ! -r "${ruta}" ]]; then
        err "Sin permisos de lectura sobre: ${ruta}"
        return 3
    fi
    return 0
}

# ===================================================================
# INTERACCIÓN CON USUARIO
# ===================================================================

# -------------------------------------------------------------------
# confirm - pregunta sí/no. Se usa como fallback cuando no hay dialog.
# args:
#   $1 - pregunta a mostrar
# return:
#   0 si el usuario dice sí, 1 si dice no
# -------------------------------------------------------------------
confirm() {
    local pregunta="$1"
    local respuesta

    while true; do
        read -r -p "${pregunta} [s/N] " respuesta
        # ${var,,} lowercasea la variable (bash 4+)
        case "${respuesta,,}" in
            s|si|sí|y|yes) return 0 ;;
            ""|n|no)       return 1 ;;
            *) echo "Respondé 's' o 'n', por favor." ;;
        esac
    done
}

# ===================================================================
# ARCHIVOS TEMPORALES
# ===================================================================

# -------------------------------------------------------------------
# crear_tempfile - crea un tempfile con mktemp y lo registra en la
# lista global para que se borre en el cleanup.
# Imprime la ruta del tempfile por stdout (para capturar con $()).
# -------------------------------------------------------------------
crear_tempfile() {
    local tmp
    tmp="$(mktemp)" || die "No se pudo crear archivo temporal" 1
    TEMPFILES_A_LIMPIAR+=("${tmp}")
    printf '%s' "${tmp}"
}

# ===================================================================
# LIMPIEZA Y TRAPS
# ===================================================================

# -------------------------------------------------------------------
# limpiar - se invoca automáticamente por el trap EXIT.
# Borra tempfiles y restaura el estado de la terminal.
# -------------------------------------------------------------------
limpiar() {
    local archivo
    for archivo in "${TEMPFILES_A_LIMPIAR[@]:-}"; do
        [[ -n "${archivo}" && -e "${archivo}" ]] && rm -f "${archivo}"
    done
    # Restaurar cursor por si dialog/tput lo escondió
    tput cnorm 2>/dev/null || true
}

# -------------------------------------------------------------------
# manejar_interrupcion - handler para Ctrl+C (SIGINT) y SIGTERM.
# Muestra un mensaje amigable y sale con el código convencional 130.
# -------------------------------------------------------------------
manejar_interrupcion() {
    echo
    log_warn "Operación cancelada por el usuario"
    exit 130
}

# -------------------------------------------------------------------
# instalar_trap_limpieza - instala los traps globales.
# Llamar una sola vez al inicio de main() en roast.sh.
# -------------------------------------------------------------------
instalar_trap_limpieza() {
    trap limpiar EXIT
    trap manejar_interrupcion INT TERM
}
