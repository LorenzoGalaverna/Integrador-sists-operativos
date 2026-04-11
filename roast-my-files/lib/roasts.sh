#!/usr/bin/env bash
#
# lib/roasts.sh
# -------------------------------------------------------------------
# Funciones de "roast" — toman datos reales de stats.sh y los
# combinan con frases graciosas de data/frases_roast.txt para
# burlarse de los archivos del usuario.
#
# Cada roast:
#   1. Muestra una cutscene con ui_cutscene
#   2. Invoca las funciones de stats.sh para extraer datos
#   3. Elige una frase random de la categoría correspondiente
#   4. Reemplaza los placeholders (%FILE%, %COUNT%, etc.)
#   5. Arma un tempfile con el resultado formateado
#   6. Lo muestra con ui_textbox
# -------------------------------------------------------------------

# ===================================================================
# PARSER DE FRASES_ROAST.TXT
# ===================================================================

# -------------------------------------------------------------------
# _frases_cargar_categoria - imprime todas las frases de una sección
# del archivo data/frases_roast.txt.
#
# El archivo está en formato INI: secciones [nombre] seguidas de
# líneas de texto. Ignora comentarios (#) y líneas vacías.
#
# args: $1 = nombre de la categoría (sin los corchetes)
# -------------------------------------------------------------------
_frases_cargar_categoria() {
    local categoria="$1"
    local archivo="${DATA_DIR}/frases_roast.txt"

    if [[ ! -f "${archivo}" ]]; then
        return 1
    fi

    # awk con flag que se activa al entrar a la sección y se apaga
    # al entrar a la siguiente.
    awk -v cat="[${categoria}]" '
        /^#/   { next }
        /^$/   { next }
        /^\[.*\]$/ {
            if ($0 == cat) { in_section=1 }
            else           { in_section=0 }
            next
        }
        in_section == 1 { print }
    ' "${archivo}"
}

# -------------------------------------------------------------------
# _frase_random - elige una frase al azar de una categoría.
# args: $1 = categoría
# stdout: una frase (con los placeholders sin reemplazar todavía)
# -------------------------------------------------------------------
_frase_random() {
    local categoria="$1"
    local frases
    frases=$(_frases_cargar_categoria "${categoria}")

    if [[ -z "${frases}" ]]; then
        printf 'Me quedé sin frases para %%FILE%% (%s)' "${categoria}"
        return 0
    fi

    if (( HAS_SHUF == 1 )); then
        printf '%s\n' "${frases}" | shuf -n 1
    else
        # Fallback: usar $RANDOM para elegir una línea
        local total
        total=$(printf '%s\n' "${frases}" | wc -l)
        local idx=$(( (RANDOM % total) + 1 ))
        printf '%s\n' "${frases}" | sed -n "${idx}p"
    fi
}

# -------------------------------------------------------------------
# _frase_aplicar_placeholders - reemplaza %KEY% por valores en una
# frase template.
#
# args: $1 = frase template
#       $2..$N = pares KEY=VALOR (ej: "FILE=mi.txt" "COUNT=42")
# stdout: frase con los placeholders reemplazados
# -------------------------------------------------------------------
_frase_aplicar_placeholders() {
    local frase="$1"
    shift

    local kv key val
    for kv in "$@"; do
        key="${kv%%=*}"
        val="${kv#*=}"
        # Reemplazo global con bash: ${var//pattern/replacement}
        frase="${frase//%${key}%/${val}}"
    done

    printf '%s' "${frase}"
}

# ===================================================================
# ROAST 1: EL ARCHIVO MÁS PATÉTICO
# -------------------------------------------------------------------
# Usa stats_shortest_file (archivo con menos líneas > 0).
# ===================================================================
roast_patetico() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local resultado lineas archivo nombre frase tmp

    ui_cutscene "Buscando tu archivo más patético..."

    resultado=$(stats_shortest_file "${dir}")
    if [[ -z "${resultado}" ]]; then
        ui_msgbox "Roast patético" "No encontré archivos de texto para analizar."
        return 0
    fi

    lineas=$(cut -f1 <<< "${resultado}")
    archivo=$(cut -f2 <<< "${resultado}")
    nombre=$(basename -- "${archivo}")

    frase=$(_frase_random "patetico")
    frase=$(_frase_aplicar_placeholders "${frase}" "FILE=${nombre}" "COUNT=${lineas}")

    tmp=$(crear_tempfile)
    {
        printf '===================================\n'
        printf '    EL MÁS PATÉTICO\n'
        printf '===================================\n\n'
        printf '%s\n\n' "${frase}"
        printf '%s\n' '-----------------------------------'
        printf 'Archivo: %s\n' "${archivo}"
        printf 'Líneas:  %d\n\n' "${lineas}"
        printf '%s\n' '--- Contenido (primeras 20 líneas) ---'
        head -20 -- "${archivo}" 2>/dev/null || printf '(no se pudo leer)\n'
    } > "${tmp}"

    ui_textbox "Roast: el más patético" "${tmp}"
}

# ===================================================================
# ROAST 2: EGO EN LÍNEAS
# -------------------------------------------------------------------
# Usa stats_longest_file.
# ===================================================================
roast_ego() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local resultado lineas archivo nombre frase tmp

    ui_cutscene "Midiendo tu ego en líneas de texto..."

    resultado=$(stats_longest_file "${dir}")
    if [[ -z "${resultado}" ]]; then
        ui_msgbox "Roast ego" "No encontré archivos de texto para analizar."
        return 0
    fi

    lineas=$(cut -f1 <<< "${resultado}")
    archivo=$(cut -f2 <<< "${resultado}")
    nombre=$(basename -- "${archivo}")

    frase=$(_frase_random "egocentrico")
    frase=$(_frase_aplicar_placeholders "${frase}" "FILE=${nombre}" "COUNT=${lineas}")

    tmp=$(crear_tempfile)
    {
        printf '===================================\n'
        printf '    EGO EN LÍNEAS\n'
        printf '===================================\n\n'
        printf '%s\n\n' "${frase}"
        printf '%s\n' '-----------------------------------'
        printf 'Archivo: %s\n' "${archivo}"
        printf 'Líneas:  %d\n' "${lineas}"
    } > "${tmp}"

    ui_textbox "Roast: ego en líneas" "${tmp}"
}

# ===================================================================
# ROAST 3: PALABRAS REPETIDAS
# -------------------------------------------------------------------
# Usa stats_top_words — pipeline clásico: tr + sort + uniq -c.
# ===================================================================
roast_repetido() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local top primera count word frase tmp

    ui_cutscene "Analizando qué palabras repetís como loro..."

    top=$(stats_top_words "${dir}" 5)

    if [[ -z "${top}" ]]; then
        ui_msgbox "Roast repetido" "No pude extraer palabras analizables."
        return 0
    fi

    # Primera línea del ranking = palabra más repetida
    primera=$(printf '%s\n' "${top}" | head -1)
    count=$(awk '{print $1}' <<< "${primera}")
    word=$(awk '{print $2}' <<< "${primera}")

    frase=$(_frase_random "repetido")
    frase=$(_frase_aplicar_placeholders "${frase}" "WORD=${word}" "COUNT=${count}")

    tmp=$(crear_tempfile)
    {
        printf '===================================\n'
        printf '    LO QUE REPETÍS\n'
        printf '===================================\n\n'
        printf '%s\n\n' "${frase}"
        printf '%s\n' '-----------------------------------'
        printf '%s\n' '--- Top 5 palabras más usadas ---'
        printf '%s\n' "${top}"
    } > "${tmp}"

    ui_textbox "Roast: palabras repetidas" "${tmp}"
}

# ===================================================================
# ROAST 4: CEMENTERIO DE TODOs
# -------------------------------------------------------------------
# Usa stats_todos (grep -rn TODO|FIXME|XXX|HACK).
# ===================================================================
roast_todos() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local count frase tmp

    ui_cutscene "Abriendo el cementerio de TODOs..."

    count=$(stats_todos_count "${dir}")

    if (( count == 0 )); then
        ui_msgbox "Roast TODOs" "No encontré ningún TODO pendiente.\n\n¿Terminás lo que empezás? Increíble."
        return 0
    fi

    frase=$(_frase_random "todos")
    frase=$(_frase_aplicar_placeholders "${frase}" "COUNT=${count}")

    tmp=$(crear_tempfile)
    {
        printf '===================================\n'
        printf '    CEMENTERIO DE TODOs\n'
        printf '===================================\n\n'
        printf '%s\n\n' "${frase}"
        printf '%s\n' '-----------------------------------'
        printf 'Total encontrados: %d\n\n' "${count}"
        printf '%s\n' '--- Primeros 15 TODOs ---'
        stats_todos "${dir}" | head -15
    } > "${tmp}"

    ui_textbox "Roast: TODOs" "${tmp}"
}

# ===================================================================
# ROAST 5: RANKING DE PUTEADAS
# -------------------------------------------------------------------
# Usa stats_puteadas + stats_puteadas_ranking.
# ===================================================================
roast_puteadas() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local total frase tmp

    ui_cutscene "Catalogando tus groserías..."

    total=$(stats_puteadas "${dir}")

    if (( total == 0 )); then
        ui_msgbox "Roast puteadas" "No puteaste ni una vez.\n\nSos demasiado formal. Aburrido."
        return 0
    fi

    frase=$(_frase_random "puteadas")
    frase=$(_frase_aplicar_placeholders "${frase}" "COUNT=${total}")

    tmp=$(crear_tempfile)
    {
        printf '===================================\n'
        printf '    RANKING DE PUTEADAS\n'
        printf '===================================\n\n'
        printf '%s\n\n' "${frase}"
        printf '%s\n' '-----------------------------------'
        printf 'Total de palabrotas: %d\n\n' "${total}"
        printf '%s\n' '--- Ranking ---'
        stats_puteadas_ranking "${dir}" || printf '(sin datos)\n'
    } > "${tmp}"

    ui_textbox "Roast: puteadas" "${tmp}"
}

# ===================================================================
# ROAST 6: ARCHIVOS ABANDONADOS
# -------------------------------------------------------------------
# Usa stats_oldest_file + conversión de epoch a días.
# ===================================================================
roast_abandonados() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local resultado epoch archivo nombre dias fecha frase tmp

    ui_cutscene "Buscando archivos en estado de abandono..."

    resultado=$(stats_oldest_file "${dir}")
    if [[ -z "${resultado}" ]]; then
        ui_msgbox "Roast abandonados" "No encontré archivos para analizar."
        return 0
    fi

    epoch=$(cut -f1 <<< "${resultado}")
    archivo=$(cut -f2 <<< "${resultado}")
    nombre=$(basename -- "${archivo}")
    dias=$(stats_dias_desde_epoch "${epoch}")
    fecha=$(stats_fecha_legible "${epoch}")

    frase=$(_frase_random "abandonados")
    frase=$(_frase_aplicar_placeholders "${frase}" "FILE=${nombre}" "DAYS=${dias}")

    tmp=$(crear_tempfile)
    {
        printf '===================================\n'
        printf '    EL MÁS ABANDONADO\n'
        printf '===================================\n\n'
        printf '%s\n\n' "${frase}"
        printf '%s\n' '-----------------------------------'
        printf 'Archivo:       %s\n' "${archivo}"
        printf 'Última mod:    %s\n' "${fecha}"
        printf 'Días sin tocar: %d\n' "${dias}"
    } > "${tmp}"

    ui_textbox "Roast: abandonados" "${tmp}"
}

# ===================================================================
# ROAST COMPLETO — encadena los 6 anteriores
# ===================================================================

# -------------------------------------------------------------------
# roast_completo - corre todos los roasts en cascada.
# -------------------------------------------------------------------
roast_completo() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"

    # Intro dramática
    clear 2>/dev/null || true
    ui_banner "ROAST COMPLETO"
    echo
    ui_cutscene "Activando modo destrucción..."
    sleep 1

    roast_patetico    "${dir}"
    roast_ego         "${dir}"
    roast_repetido    "${dir}"
    roast_todos       "${dir}"
    roast_puteadas    "${dir}"
    roast_abandonados "${dir}"

    # Resumen final
    local total_files total_words total_lines mensaje
    total_files=$(stats_file_count  "${dir}")
    total_words=$(stats_total_words "${dir}")
    total_lines=$(stats_total_lines "${dir}")

    mensaje=$(cat <<EOF
ROAST TERMINADO

Estadísticas finales:
  Archivos analizados: ${total_files}
  Total de palabras:   ${total_words}
  Total de líneas:     ${total_lines}

Gracias por dejarme burlarme de tu carpeta.
(Igual, mereces cada una.)
EOF
)
    ui_msgbox "Fin del roast" "${mensaje}"
}
