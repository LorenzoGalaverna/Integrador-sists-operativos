#!/usr/bin/env bash
#
# lib/search.sh
# -------------------------------------------------------------------
# MODO SERIO — Gestor de búsqueda de contenidos en archivos de texto.
# Esta es la parte que cumple el enunciado del proyecto.
#
# Cada función es un "ejercicio" distinto con los comandos clásicos
# de búsqueda de Linux (grep/find/sed) envuelto en una UI con dialog.
#
# Todas las búsquedas guardan su resultado en la variable global
# ULTIMO_RESULTADO (ruta a un tempfile), así el usuario puede
# exportarlas después con "Exportar último resultado".
# -------------------------------------------------------------------

# ===================================================================
# ESTADO GLOBAL DEL MÓDULO
# ===================================================================
# Ruta al archivo con el último resultado de búsqueda (para exportar)
ULTIMO_RESULTADO=""

# ===================================================================
# HELPERS INTERNOS
# ===================================================================

# -------------------------------------------------------------------
# _search_pedir_directorio - pide un directorio con valor por default
# al DIRECTORIO_VICTIMA actual.
# stdout: ruta elegida
# return: 0 ok, 1 cancelado
# -------------------------------------------------------------------
_search_pedir_directorio() {
    local titulo="$1"
    local dir
    local default="${DIRECTORIO_VICTIMA:-${PWD}}"

    if ! dir=$(ui_inputbox "${titulo}" "Directorio donde buscar:" "${default}"); then
        return 1
    fi

    if ! require_dir "${dir}" 2>/dev/null; then
        ui_msgbox "Error" "Directorio inválido: ${dir}"
        return 1
    fi

    printf '%s' "${dir}"
    return 0
}

# -------------------------------------------------------------------
# _search_pedir_archivo - pide un archivo individual.
# -------------------------------------------------------------------
_search_pedir_archivo() {
    local titulo="$1"
    local archivo
    local default="${DIRECTORIO_VICTIMA:-${PWD}}/"

    if ! archivo=$(ui_inputbox "${titulo}" "Archivo a buscar:" "${default}"); then
        return 1
    fi

    if ! require_file "${archivo}" 2>/dev/null; then
        ui_msgbox "Error" "Archivo inválido: ${archivo}"
        return 1
    fi

    printf '%s' "${archivo}"
    return 0
}

# -------------------------------------------------------------------
# _search_pedir_patron - pide un patrón no vacío.
# -------------------------------------------------------------------
_search_pedir_patron() {
    local titulo="$1"
    local prompt="${2:-Patrón a buscar:}"
    local patron

    if ! patron=$(ui_inputbox "${titulo}" "${prompt}"); then
        return 1
    fi

    if [[ -z "${patron}" ]]; then
        ui_msgbox "Error" "El patrón no puede estar vacío"
        return 1
    fi

    printf '%s' "${patron}"
    return 0
}

# -------------------------------------------------------------------
# _search_mostrar_resultado - muestra un tempfile con los resultados
# y ofrece exportarlo.
# args: $1 = título, $2 = tempfile con resultados
# -------------------------------------------------------------------
_search_mostrar_resultado() {
    local titulo="$1"
    local tmp="$2"

    if [[ ! -s "${tmp}" ]]; then
        ui_msgbox "Sin resultados" "La búsqueda no arrojó ningún resultado."
        return 0
    fi

    ULTIMO_RESULTADO="${tmp}"
    ui_textbox "${titulo}" "${tmp}"

    if ui_yesno "Exportar" "¿Querés exportar este resultado a un archivo?"; then
        search_exportar_ultimo
    fi
}

# ===================================================================
# OPCIÓN 1: BÚSQUEDA SIMPLE
# -------------------------------------------------------------------
# Comando base: grep -n PATRÓN ARCHIVO
# ===================================================================
search_simple() {
    local archivo patron tmp
    local -a flags=(-n)

    archivo=$(_search_pedir_archivo "Búsqueda simple") || return 0
    patron=$(_search_pedir_patron "Búsqueda simple") || return 0

    if ui_yesno "Opción" "¿Ignorar mayúsculas/minúsculas? (case-insensitive)"; then
        flags+=(-i)
    fi

    tmp=$(crear_tempfile)

    # Agregamos '|| true' porque grep retorna 1 cuando no encuentra
    # y con set -e eso abortaría el script. La ausencia de resultados
    # es un caso legítimo, no un error.
    grep "${flags[@]}" -- "${patron}" "${archivo}" > "${tmp}" 2>&1 || true

    _search_mostrar_resultado "Resultados: ${patron}" "${tmp}"
}

# ===================================================================
# OPCIÓN 2: BÚSQUEDA RECURSIVA
# -------------------------------------------------------------------
# Comando base: grep -rn PATRÓN DIR/
# El flag -I excluye archivos binarios.
# ===================================================================
search_recursiva() {
    local dir patron tmp
    local -a flags=(-rnI)

    dir=$(_search_pedir_directorio "Búsqueda recursiva") || return 0
    patron=$(_search_pedir_patron "Búsqueda recursiva") || return 0

    if ui_yesno "Opción" "¿Ignorar mayúsculas/minúsculas?"; then
        flags+=(-i)
    fi

    tmp=$(crear_tempfile)
    grep "${flags[@]}" -- "${patron}" "${dir}" > "${tmp}" 2>&1 || true

    _search_mostrar_resultado "Recursivo: ${patron}" "${tmp}"
}

# ===================================================================
# OPCIÓN 3: BÚSQUEDA CON REGEX
# -------------------------------------------------------------------
# Comando base: grep -En REGEX
# -E activa regex extendidas (alternancia, grupos, +, ?, etc.)
# ===================================================================
search_regex() {
    local dir regex tmp
    local -a flags=(-rnIE)

    dir=$(_search_pedir_directorio "Regex") || return 0
    regex=$(_search_pedir_patron "Regex" "Expresión regular (POSIX extendida):") || return 0

    if ui_yesno "Opción" "¿Ignorar mayúsculas/minúsculas?"; then
        flags+=(-i)
    fi

    tmp=$(crear_tempfile)

    # Validar la regex intentando compilarla contra stdin vacío.
    # Si es inválida, grep escupe error a stderr.
    if ! echo "" | grep -E "${regex}" >/dev/null 2>&1; then
        # grep exit 2 = error de sintaxis; exit 1 = sin matches (OK)
        if [[ $? -eq 2 ]]; then
            ui_msgbox "Error" "La expresión regular es inválida: ${regex}"
            return 1
        fi
    fi

    grep "${flags[@]}" -- "${regex}" "${dir}" > "${tmp}" 2>&1 || true
    _search_mostrar_resultado "Regex: ${regex}" "${tmp}"
}

# ===================================================================
# OPCIÓN 4: BÚSQUEDA CON CONTEXTO
# -------------------------------------------------------------------
# Comando base: grep -C N PATRÓN
# Muestra N líneas antes y después de cada match.
# ===================================================================
search_contexto() {
    local dir patron contexto tmp

    dir=$(_search_pedir_directorio "Con contexto") || return 0
    patron=$(_search_pedir_patron "Con contexto") || return 0

    if ! contexto=$(ui_inputbox "Con contexto" "Cantidad de líneas de contexto (antes y después):" "2"); then
        return 0
    fi

    # Validar que sea un número entero no negativo
    if ! [[ "${contexto}" =~ ^[0-9]+$ ]]; then
        ui_msgbox "Error" "Tenés que ingresar un número entero (0, 1, 2, ...)"
        return 1
    fi

    tmp=$(crear_tempfile)
    grep -rnI -C "${contexto}" -- "${patron}" "${dir}" > "${tmp}" 2>&1 || true

    _search_mostrar_resultado "Contexto ±${contexto}: ${patron}" "${tmp}"
}

# ===================================================================
# OPCIÓN 5: CONTAR OCURRENCIAS
# -------------------------------------------------------------------
# Comando base: grep -c PATRÓN
# Devuelve el conteo por archivo.
# ===================================================================
search_contar() {
    local dir patron tmp

    dir=$(_search_pedir_directorio "Contar ocurrencias") || return 0
    patron=$(_search_pedir_patron "Contar ocurrencias") || return 0

    tmp=$(crear_tempfile)

    # -c conteo, -r recursivo, -I sin binarios.
    # grep -v ':0$' filtra los archivos con cero ocurrencias.
    grep -rcI -- "${patron}" "${dir}" 2>/dev/null \
        | grep -v ':0$' \
        | sort -t: -k2 -rn \
        > "${tmp}" || true

    if [[ -s "${tmp}" ]]; then
        # Agregar header con el total
        local total
        total=$(awk -F: '{sum += $NF} END {print sum}' "${tmp}")
        {
            printf '=== Conteo de "%s" ===\n' "${patron}"
            printf 'Total de ocurrencias: %d\n' "${total}"
            printf '\nPor archivo:\n'
            cat "${tmp}"
        } > "${tmp}.final"
        mv "${tmp}.final" "${tmp}"
    fi

    _search_mostrar_resultado "Conteo: ${patron}" "${tmp}"
}

# ===================================================================
# OPCIÓN 6: BÚSQUEDA FUZZY (fzf)
# -------------------------------------------------------------------
# Lanza fzf con preview del archivo al costado.
# El usuario va filtrando interactivamente con letras y ve el
# contenido del archivo que tiene seleccionado en vivo.
# ===================================================================
search_fuzzy() {
    if (( HAS_FZF == 0 )); then
        ui_msgbox "fzf no instalado" "La búsqueda fuzzy requiere 'fzf'.\n\nInstalalo con: sudo apt install fzf"
        return 1
    fi

    local dir seleccionado

    dir=$(_search_pedir_directorio "Búsqueda fuzzy") || return 0

    # Limpiamos la pantalla porque fzf toma control total
    clear 2>/dev/null || true

    # Pipeline:
    #   find lista archivos de texto (grep -Iq filtra binarios)
    #   fzf permite filtrar en vivo y muestra preview al costado
    #
    # '|| true' porque fzf retorna 130 si el usuario cancela con ESC
    seleccionado=$(
        find "${dir}" -type f -not -path '*/\.*' \
            -exec grep -Iq . {} \; -print 2>/dev/null \
        | fzf \
            --preview 'cat {} 2>/dev/null | head -200' \
            --preview-window 'right:60%:wrap' \
            --height 100% \
            --prompt 'Buscar archivo > ' \
            --header 'ENTER para ver, ESC para cancelar'
    ) || true

    if [[ -n "${seleccionado}" ]] && [[ -f "${seleccionado}" ]]; then
        ui_textbox "Contenido: $(basename -- "${seleccionado}")" "${seleccionado}"
    fi
}

# ===================================================================
# OPCIÓN 7: BUSCAR ARCHIVOS POR NOMBRE (find)
# -------------------------------------------------------------------
# Comando base: find DIR -iname '*PATRÓN*'
# ===================================================================
search_archivos() {
    local dir patron tmp

    dir=$(_search_pedir_directorio "Buscar archivos") || return 0
    patron=$(_search_pedir_patron "Buscar archivos" "Nombre (o parte del nombre):") || return 0

    tmp=$(crear_tempfile)

    # -iname: case-insensitive. Los asteriscos agregan match parcial.
    find "${dir}" -type f -iname "*${patron}*" 2>/dev/null > "${tmp}" || true

    _search_mostrar_resultado "Archivos con '${patron}' en el nombre" "${tmp}"
}

# ===================================================================
# OPCIÓN 8: REEMPLAZAR TEXTO (sed)
# -------------------------------------------------------------------
# Flujo en dos pasos:
#   1. Mostrar preview de qué líneas cambiarían (sed -n p)
#   2. Pedir confirmación y aplicar con sed -i (crea backup .bak)
# ===================================================================
search_reemplazar() {
    local archivo buscar reemplazar tmp

    archivo=$(_search_pedir_archivo "Reemplazar") || return 0

    if ! buscar=$(ui_inputbox "Reemplazar" "Texto a buscar:"); then return 0; fi
    if [[ -z "${buscar}" ]]; then
        ui_msgbox "Error" "El texto a buscar no puede estar vacío"
        return 1
    fi

    if ! reemplazar=$(ui_inputbox "Reemplazar" "Texto de reemplazo:"); then return 0; fi

    tmp=$(crear_tempfile)

    # Escapar caracteres especiales de sed en patron y reemplazo.
    # Regex: | \ & y los metachars de BRE.
    local esc_buscar esc_reemplazar
    esc_buscar=$(printf '%s' "${buscar}" | sed 's/[][\\/.*^$|]/\\&/g')
    esc_reemplazar=$(printf '%s' "${reemplazar}" | sed 's/[\\/&|]/\\&/g')

    {
        printf '=== PREVIEW DEL REEMPLAZO ===\n'
        printf 'Archivo:    %s\n' "${archivo}"
        printf 'Buscar:     %s\n' "${buscar}"
        printf 'Reemplazar: %s\n' "${reemplazar}"
        printf '\n'

        printf '=== Líneas que matchean ACTUALMENTE (máx 30) ===\n'
        grep -n -F -- "${buscar}" "${archivo}" 2>/dev/null | head -30 || true
        printf '\n'

        printf '=== Esas mismas líneas DESPUÉS del reemplazo ===\n'
        # sed -n con /p imprime solo las líneas donde ocurrió el reemplazo
        sed -n "s|${esc_buscar}|${esc_reemplazar}|gp" "${archivo}" 2>/dev/null | head -30 || true
    } > "${tmp}"

    ui_textbox "Preview" "${tmp}"

    if ! ui_yesno "Confirmar" "¿Aplicar el reemplazo al archivo?\n\nSe creará un backup en ${archivo}.bak"; then
        ui_msgbox "Cancelado" "No se aplicó ningún cambio."
        return 0
    fi

    # Backup antes de tocar nada
    if ! cp -- "${archivo}" "${archivo}.bak"; then
        ui_msgbox "Error" "No se pudo crear el backup. Abortando."
        return 1
    fi

    # Aplicar con sed -i
    if sed -i "s|${esc_buscar}|${esc_reemplazar}|g" "${archivo}" 2>/dev/null; then
        ui_msgbox "Hecho" "Reemplazo aplicado.\n\nBackup en:\n${archivo}.bak"
    else
        # Restaurar si falló
        mv -- "${archivo}.bak" "${archivo}"
        ui_msgbox "Error" "Falló el reemplazo. Se restauró el archivo original."
        return 1
    fi
}

# ===================================================================
# OPCIÓN 9: EXPORTAR ÚLTIMO RESULTADO
# -------------------------------------------------------------------
# Copia el tempfile con el último resultado a reportes/ con timestamp.
# ===================================================================
search_exportar_ultimo() {
    if [[ -z "${ULTIMO_RESULTADO:-}" ]] || [[ ! -f "${ULTIMO_RESULTADO}" ]]; then
        ui_msgbox "Sin resultado" "No hay ningún resultado de búsqueda para exportar.\n\nHacé una búsqueda primero."
        return 1
    fi

    mkdir -p "${REPORTES_DIR}" || {
        ui_msgbox "Error" "No se pudo crear el directorio de reportes: ${REPORTES_DIR}"
        return 1
    }

    local timestamp destino
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    destino="${REPORTES_DIR}/busqueda_${timestamp}.txt"

    if cp -- "${ULTIMO_RESULTADO}" "${destino}"; then
        ui_msgbox "Exportado" "Resultado guardado en:\n\n${destino}"
    else
        ui_msgbox "Error" "No se pudo escribir el archivo: ${destino}"
        return 1
    fi
}

# ===================================================================
# MENÚ DEL MODO SERIO
# ===================================================================

# -------------------------------------------------------------------
# menu_search - submenú con todas las opciones de búsqueda.
# Loop hasta que el usuario elija volver.
# -------------------------------------------------------------------
menu_search() {
    local opcion

    while true; do
        if ! opcion=$(ui_menu "Modo Serio - Búsqueda" \
            "Gestor de búsqueda de contenidos en archivos de texto\n(la parte seria del proyecto)" \
            "1" "Búsqueda simple (grep -n)" \
            "2" "Búsqueda recursiva (grep -rn)" \
            "3" "Búsqueda con regex (grep -En)" \
            "4" "Búsqueda con contexto (grep -C)" \
            "5" "Contar ocurrencias (grep -c)" \
            "6" "Búsqueda fuzzy (fzf)" \
            "7" "Buscar archivos por nombre (find)" \
            "8" "Reemplazar texto (sed)" \
            "9" "Exportar último resultado" \
            "0" "Volver al menú principal"); then
            return 0
        fi

        case "${opcion}" in
            1) search_simple ;;
            2) search_recursiva ;;
            3) search_regex ;;
            4) search_contexto ;;
            5) search_contar ;;
            6) search_fuzzy ;;
            7) search_archivos ;;
            8) search_reemplazar ;;
            9) search_exportar_ultimo ;;
            0|"") return 0 ;;
            *) ui_msgbox "Error" "Opción inválida: ${opcion}" ;;
        esac
    done
}
