#!/usr/bin/env bash
#
# lib/ui.sh
# -------------------------------------------------------------------
# Wrappers de interfaz de usuario. Cada función tiene dos caminos:
#   - "fancy": usa dialog/figlet/lolcat/boxes/pv si están instalados
#   - "fallback": texto plano con echo/read si no
#
# Convención de retorno:
#   - Las funciones que reciben input (menu, inputbox, dselect) lo
#     devuelven por stdout con printf.
#   - El exit code refleja el de dialog: 0 = OK, 1 = cancel, 255 = esc.
#   - Los callers deben usar `if ! resultado=$(ui_foo ...); then return; fi`
#     para manejar cancelaciones sin que set -e aborte el script.
# -------------------------------------------------------------------

# ===================================================================
# TAMAÑOS STANDARD PARA DIALOG
# -------------------------------------------------------------------
# Si se necesita ajustar por terminales chicas, cambiar acá.
# ===================================================================
readonly UI_MENU_ROWS=22
readonly UI_MENU_COLS=74
readonly UI_MENU_ITEMS=14
readonly UI_INPUT_ROWS=10
readonly UI_INPUT_COLS=72
readonly UI_MSG_ROWS=20
readonly UI_MSG_COLS=74
readonly UI_TEXT_ROWS=30
readonly UI_TEXT_COLS=100
readonly UI_YESNO_ROWS=10
readonly UI_YESNO_COLS=62

# ===================================================================
# BANNER (figlet + lolcat)
# ===================================================================

# -------------------------------------------------------------------
# ui_banner - imprime un título grande.
# args: $1 = texto del banner
# -------------------------------------------------------------------
ui_banner() {
    local texto="$1"

    if (( HAS_FIGLET == 1 )); then
        if (( HAS_LOLCAT == 1 )) && (( USAR_COLOR == 1 )); then
            figlet -f standard -- "${texto}" | lolcat
        else
            figlet -f standard -- "${texto}"
        fi
    else
        # Fallback: marco con signos igual
        local len=${#texto}
        local borde=""
        printf -v borde '%*s' $((len + 6)) ''
        borde="${borde// /=}"
        printf '%s\n' "${borde}"
        printf '   %s   \n' "${texto}"
        printf '%s\n' "${borde}"
    fi
}

# ===================================================================
# CAJA DECORATIVA (boxes)
# ===================================================================

# -------------------------------------------------------------------
# ui_box - envuelve un texto en una caja decorativa.
# args: $1 = texto (puede tener múltiples líneas)
# -------------------------------------------------------------------
ui_box() {
    local texto="$1"

    if (( HAS_BOXES == 1 )); then
        printf '%s\n' "${texto}" | boxes -d stone -p h2
    else
        # Fallback: marco ASCII hecho a mano
        local -a lineas=()
        mapfile -t lineas <<< "${texto}"

        local max=0
        local linea
        for linea in "${lineas[@]}"; do
            if (( ${#linea} > max )); then
                max=${#linea}
            fi
        done

        local borde=""
        printf -v borde '%*s' $((max + 4)) ''
        borde="+${borde// /-}+"

        printf '%s\n' "${borde}"
        for linea in "${lineas[@]}"; do
            printf '|  %-*s  |\n' "${max}" "${linea}"
        done
        printf '%s\n' "${borde}"
    fi
}

# ===================================================================
# CUTSCENE (barra de carga falsa con pv)
# ===================================================================

# -------------------------------------------------------------------
# ui_cutscene - muestra un mensaje con barra de carga dramática.
# args: $1 = mensaje a mostrar
# -------------------------------------------------------------------
ui_cutscene() {
    local mensaje="$1"
    local i

    echo
    printf '  %s\n' "${mensaje}"

    if (( HAS_PV == 1 )); then
        # Usamos pv en modo "line counting" con un stream generado
        # a mano. Así conocemos el total y podemos mostrar una barra
        # con porcentaje y tiempo.
        {
            for i in $(seq 1 25); do
                echo "."
                sleep 0.04
            done
        } | pv -l -s 25 -N "  " -p -t -e >/dev/null 2>&1 || sleep 1
    else
        # Fallback: barra hecha con echo + sleep
        printf '  ['
        for i in 1 2 3 4 5 6 7 8 9 10; do
            printf '#'
            sleep 0.08
        done
        printf '] listo\n'
    fi
    echo
}

# ===================================================================
# SPLASH INICIAL
# ===================================================================

# -------------------------------------------------------------------
# ui_splash - pantalla de bienvenida con banner y tagline.
# -------------------------------------------------------------------
ui_splash() {
    clear 2>/dev/null || true
    echo
    ui_banner "ROAST MY FILES"
    echo

    local tagline="  >> La verdad duele. Tus archivos, más. <<"
    if (( HAS_LOLCAT == 1 )) && (( USAR_COLOR == 1 )); then
        printf '%s\n' "${tagline}" | lolcat
    else
        printf '%s\n' "${tagline}"
    fi

    echo
    sleep 1
}

# ===================================================================
# MENÚS (dialog --menu)
# ===================================================================

# -------------------------------------------------------------------
# ui_menu - muestra un menú de opciones y devuelve la tag elegida.
# args:
#   $1         título
#   $2         texto descriptivo
#   $3..$N     pares tag-descripción
# return:
#   stdout: tag elegida; exit code: 0 ok, 1 cancel, 255 esc
# -------------------------------------------------------------------
ui_menu() {
    local titulo="$1"
    local texto="$2"
    shift 2

    if (( HAS_DIALOG == 1 )); then
        dialog --stdout --clear --title "${titulo}" \
            --menu "${texto}" \
            "${UI_MENU_ROWS}" "${UI_MENU_COLS}" "${UI_MENU_ITEMS}" \
            "$@"
        return $?
    fi

    # ---- Fallback: menú de texto plano ----
    clear 2>/dev/null || true
    echo
    printf '===== %s =====\n' "${titulo}"
    printf '%s\n\n' "${texto}"

    local -a tags_validas=()
    while [[ $# -gt 0 ]]; do
        tags_validas+=("$1")
        printf '  %s) %s\n' "$1" "$2"
        shift 2
    done

    echo
    local opcion
    read -r -p "Elegí una opción: " opcion

    # Validar que la tag exista
    local valida
    for valida in "${tags_validas[@]}"; do
        if [[ "${opcion}" == "${valida}" ]]; then
            printf '%s' "${opcion}"
            return 0
        fi
    done

    # Si no matcheó, tratamos como cancel
    return 1
}

# ===================================================================
# INPUTBOX (dialog --inputbox)
# ===================================================================

# -------------------------------------------------------------------
# ui_inputbox - pide un texto al usuario.
# args: $1 = título, $2 = prompt, $3 = valor inicial (opcional)
# return: stdout con el texto; exit 1 si canceló
# -------------------------------------------------------------------
ui_inputbox() {
    local titulo="$1"
    local prompt="$2"
    local inicial="${3:-}"

    if (( HAS_DIALOG == 1 )); then
        dialog --stdout --clear --title "${titulo}" \
            --inputbox "${prompt}" \
            "${UI_INPUT_ROWS}" "${UI_INPUT_COLS}" \
            "${inicial}"
        return $?
    fi

    echo
    printf '===== %s =====\n' "${titulo}"
    local respuesta=""
    if [[ -n "${inicial}" ]]; then
        read -r -e -i "${inicial}" -p "${prompt}: " respuesta
    else
        read -r -p "${prompt}: " respuesta
    fi
    printf '%s' "${respuesta}"
}

# ===================================================================
# YESNO (dialog --yesno)
# ===================================================================

# -------------------------------------------------------------------
# ui_yesno - pregunta sí/no.
# args: $1 = título, $2 = pregunta
# return: 0 si sí, 1 si no
# -------------------------------------------------------------------
ui_yesno() {
    local titulo="$1"
    local pregunta="$2"

    if (( HAS_DIALOG == 1 )); then
        dialog --clear --title "${titulo}" \
            --yesno "${pregunta}" \
            "${UI_YESNO_ROWS}" "${UI_YESNO_COLS}"
        return $?
    fi

    echo
    printf '===== %s =====\n' "${titulo}"
    confirm "${pregunta}"
    return $?
}

# ===================================================================
# MSGBOX (dialog --msgbox)
# ===================================================================

# -------------------------------------------------------------------
# ui_msgbox - muestra un mensaje al usuario (sin input).
# args: $1 = título, $2 = mensaje
# -------------------------------------------------------------------
ui_msgbox() {
    local titulo="$1"
    local mensaje="$2"

    if (( HAS_DIALOG == 1 )); then
        dialog --clear --title "${titulo}" \
            --msgbox "${mensaje}" \
            "${UI_MSG_ROWS}" "${UI_MSG_COLS}"
        return 0
    fi

    echo
    printf '===== %s =====\n' "${titulo}"
    printf '%s\n\n' "${mensaje}"
    read -r -p "(Enter para continuar) " _
}

# ===================================================================
# TEXTBOX (dialog --textbox para ver archivos)
# ===================================================================

# -------------------------------------------------------------------
# ui_textbox - muestra el contenido de un archivo con scroll.
# args: $1 = título, $2 = ruta del archivo
# -------------------------------------------------------------------
ui_textbox() {
    local titulo="$1"
    local archivo="$2"

    if [[ ! -f "${archivo}" ]]; then
        ui_msgbox "Error" "Archivo no encontrado: ${archivo}"
        return 1
    fi

    if (( HAS_DIALOG == 1 )); then
        dialog --clear --title "${titulo}" \
            --textbox "${archivo}" \
            "${UI_TEXT_ROWS}" "${UI_TEXT_COLS}"
        return 0
    fi

    echo
    printf '===== %s =====\n' "${titulo}"
    if command -v less >/dev/null 2>&1; then
        less -F -X "${archivo}"
    else
        cat "${archivo}"
    fi
    echo
    read -r -p "(Enter para continuar) " _
}

# ===================================================================
# DSELECT (elegir directorio)
# ===================================================================

# -------------------------------------------------------------------
# ui_dselect - pide al usuario que seleccione un directorio.
# args: $1 = título, $2 = directorio inicial (opcional)
# return: stdout con la ruta; exit 1 si canceló
# -------------------------------------------------------------------
ui_dselect() {
    local titulo="$1"
    local inicial="${2:-${PWD}/}"

    if (( HAS_DIALOG == 1 )); then
        dialog --stdout --clear --title "${titulo}" \
            --dselect "${inicial}" 15 72
        return $?
    fi

    echo
    printf '===== %s =====\n' "${titulo}"
    local ruta=""
    read -r -e -i "${inicial}" -p "Directorio: " ruta
    printf '%s' "${ruta}"
}

# ===================================================================
# INFOBOX (mensaje breve que no bloquea)
# ===================================================================

# -------------------------------------------------------------------
# ui_infobox - mensaje efímero, no espera confirmación.
# Útil para "Procesando..." antes de una operación.
# args: $1 = título, $2 = mensaje
# -------------------------------------------------------------------
ui_infobox() {
    local titulo="$1"
    local mensaje="$2"

    if (( HAS_DIALOG == 1 )); then
        dialog --clear --title "${titulo}" \
            --infobox "${mensaje}" 8 60
        return 0
    fi

    printf '[%s] %s\n' "${titulo}" "${mensaje}"
}
