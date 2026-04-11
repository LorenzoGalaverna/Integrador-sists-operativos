#!/usr/bin/env bash
#
# lib/deps.sh
# -------------------------------------------------------------------
# Chequeo de dependencias del sistema.
#
# Divide las dependencias en dos grupos:
#   - OBLIGATORIAS: sin ellas el script no corre (aborta con die).
#   - DECORATIVAS:  si faltan, se activa un fallback y se sigue.
#
# Después de correr deps_check, las variables globales HAS_<TOOL>
# quedan seteadas en 1 (presente) o 0 (ausente). El resto del código
# las consulta para decidir si usar la versión "fancy" o el fallback.
#
# Expone:
#   deps_check       -> corre el chequeo; aborta si falta algo obligatorio
#   deps_resumen     -> imprime una línea resumen de qué se detectó
# -------------------------------------------------------------------

# ===================================================================
# TABLAS DE DEPENDENCIAS
# ===================================================================

# Comandos sin los cuales el script no tiene sentido.
# Todos vienen en coreutils/util-linux de cualquier distro moderna.
readonly DEPS_OBLIGATORIAS=(
    "bash"
    "grep"
    "awk"
    "sed"
    "find"
    "wc"
    "sort"
    "uniq"
    "tr"
    "cut"
    "head"
    "tail"
    "stat"
    "mktemp"
    "tput"
)

# Comandos que mejoran la experiencia pero tienen fallback.
readonly DEPS_DECORATIVAS=(
    "dialog"
    "figlet"
    "lolcat"
    "boxes"
    "pv"
    "fzf"
    "shuf"
)

# ===================================================================
# FLAGS DE DISPONIBILIDAD
# -------------------------------------------------------------------
# El resto del código (ui.sh, roasts.sh, etc.) consulta estas
# variables para decidir qué camino tomar.
# ===================================================================
HAS_DIALOG=0
HAS_FIGLET=0
HAS_LOLCAT=0
HAS_BOXES=0
HAS_PV=0
HAS_FZF=0
HAS_SHUF=0

# ===================================================================
# HELPERS INTERNOS
# -------------------------------------------------------------------
# Los nombres con underscore al inicio son "privados" por convención.
# ===================================================================

# -------------------------------------------------------------------
# _tiene_comando - chequea si un comando está disponible en $PATH.
# args:
#   $1 - nombre del comando
# return:
#   0 si existe, 1 si no
# -------------------------------------------------------------------
_tiene_comando() {
    command -v "$1" >/dev/null 2>&1
}

# -------------------------------------------------------------------
# _instrucciones_instalacion - imprime cómo instalar un paquete en
# las distros más comunes.
# args:
#   $1 - nombre del paquete
# -------------------------------------------------------------------
_instrucciones_instalacion() {
    local paquete="$1"
    cat >&2 <<EOF

  Instalá '${paquete}' según tu distro:

    Debian/Ubuntu:  sudo apt update && sudo apt install ${paquete}
    Fedora:         sudo dnf install ${paquete}
    Arch/Manjaro:   sudo pacman -S ${paquete}
    openSUSE:       sudo zypper install ${paquete}

EOF
}

# -------------------------------------------------------------------
# _marca_disponible - devuelve un check verde o una cruz roja según
# el valor (1 o 0) del flag.
# args:
#   $1 - 1 o 0
# -------------------------------------------------------------------
_marca_disponible() {
    if (( $1 == 1 )); then
        printf '%s✓%s' "${COLOR_VERDE}" "${COLOR_RESET}"
    else
        printf '%s✗%s' "${COLOR_ROJO}" "${COLOR_RESET}"
    fi
}

# ===================================================================
# API PÚBLICA
# ===================================================================

# -------------------------------------------------------------------
# deps_check - ejecuta el chequeo completo de dependencias.
#
# 1) Verifica las obligatorias. Si falta alguna, muestra cómo
#    instalarlas y aborta con código 2.
# 2) Verifica las decorativas y setea los flags HAS_*. Para las que
#    faltan, muestra un warning pero sigue.
#
# Esta función debe invocarse una sola vez, al inicio del main().
# -------------------------------------------------------------------
deps_check() {
    local cmd
    local faltantes=()

    # ---------------------------------------------------------------
    # Paso 1: obligatorias
    # ---------------------------------------------------------------
    for cmd in "${DEPS_OBLIGATORIAS[@]}"; do
        if ! _tiene_comando "${cmd}"; then
            faltantes+=("${cmd}")
        fi
    done

    if (( ${#faltantes[@]} > 0 )); then
        err "Faltan dependencias obligatorias: ${faltantes[*]}"
        for cmd in "${faltantes[@]}"; do
            _instrucciones_instalacion "${cmd}"
        done
        exit 2
    fi

    # ---------------------------------------------------------------
    # Paso 2: decorativas -> setean flags, no abortan
    # ---------------------------------------------------------------
    _tiene_comando "dialog" && HAS_DIALOG=1
    _tiene_comando "figlet" && HAS_FIGLET=1
    _tiene_comando "lolcat" && HAS_LOLCAT=1
    _tiene_comando "boxes"  && HAS_BOXES=1
    _tiene_comando "pv"     && HAS_PV=1
    _tiene_comando "fzf"    && HAS_FZF=1
    _tiene_comando "shuf"   && HAS_SHUF=1

    # ---------------------------------------------------------------
    # Warnings amigables para las que faltan
    # ---------------------------------------------------------------
    if (( HAS_DIALOG == 0 )); then
        log_warn "'dialog' no está instalado — se usará modo texto plano"
        log_warn "Recomendado: instalarlo para una mejor experiencia"
        _instrucciones_instalacion "dialog"
    fi

    (( HAS_FIGLET == 0 )) && log_warn "'figlet' no encontrado — banners en texto plano"
    (( HAS_LOLCAT == 0 )) && log_warn "'lolcat' no encontrado — sin colores arcoíris"
    (( HAS_BOXES  == 0 )) && log_warn "'boxes' no encontrado — cajas con ASCII básico"
    (( HAS_PV     == 0 )) && log_warn "'pv' no encontrado — sin barras de carga animadas"
    (( HAS_FZF    == 0 )) && log_warn "'fzf' no encontrado — búsqueda fuzzy deshabilitada"
    (( HAS_SHUF   == 0 )) && log_warn "'shuf' no encontrado — las frases de roast no serán aleatorias"

    # Return explícito porque la última línea puede retornar 1
    # cuando todas las decorativas están instaladas (todos los
    # `(( == 0 ))` evalúan falso → exit 1 → set -e aborta).
    return 0
}

# -------------------------------------------------------------------
# deps_resumen - imprime en una sola línea qué se detectó y qué no.
# Útil para mostrar en el splash al arrancar.
# -------------------------------------------------------------------
deps_resumen() {
    printf '  dialog:%s  figlet:%s  lolcat:%s  boxes:%s  pv:%s  fzf:%s  shuf:%s\n' \
        "$(_marca_disponible ${HAS_DIALOG})" \
        "$(_marca_disponible ${HAS_FIGLET})" \
        "$(_marca_disponible ${HAS_LOLCAT})" \
        "$(_marca_disponible ${HAS_BOXES})"  \
        "$(_marca_disponible ${HAS_PV})"     \
        "$(_marca_disponible ${HAS_FZF})"    \
        "$(_marca_disponible ${HAS_SHUF})"
}
