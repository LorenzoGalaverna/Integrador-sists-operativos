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
# HELPERS PARA SCORE, EASTER EGGS Y CERTIFICADO
# -------------------------------------------------------------------
# Funciones internas que se usan en roast_completo para calcular un
# puntaje final, detectar easter eggs y generar el certificado.
# ===================================================================

# -------------------------------------------------------------------
# _roast_easter_eggs - busca contenido especial en la carpeta y
# devuelve mensajes sorpresa si los encuentra.
#
# Usa grep -m1 (parar al primer match) para ser rápido.
# Cada chequeo busca un patrón distinto y genera una frase especial.
#
# args: $1 = directorio
# stdout: líneas con los easter eggs encontrados (puede estar vacío)
# -------------------------------------------------------------------
_roast_easter_eggs() {
    local dir="$1"
    local output=""

    # 1. Passwords en texto plano (archivos con nombre sospechoso)
    if find "${dir}" -type f \( -iname '*passw*' -o -iname '*contrase*' \) \
        2>/dev/null | grep -q .; then
        output+="  ALERTA: Guardás passwords en texto plano? Vivís peligrosamente."
        output+=$'\n'
    fi

    # 2. Contenido romántico
    if grep -rqiIm1 -e 'te quiero' -e 'te amo' "${dir}" 2>/dev/null; then
        output+="  <3 Encontré sentimientos entre tus archivos. Qué tierno."
        output+=$'\n'
    fi

    # 3. Abuso de sudo
    local sudo_count=0
    sudo_count=$(grep -rciI 'sudo' "${dir}" 2>/dev/null \
        | awk -F: '{sum+=$NF} END{print sum+0}') || sudo_count=0
    sudo_count=${sudo_count:-0}
    if (( sudo_count > 10 )); then
        output+="  ${sudo_count}x \"sudo\". Nivel de pereza: sudo make me a sandwich."
        output+=$'\n'
    fi

    # 4. Referencias a Torvalds
    if grep -rqiIm1 'torvalds' "${dir}" 2>/dev/null; then
        output+="  Mencionás a Torvalds. Persona de cultura detectada."
        output+=$'\n'
    fi

    # 5. Rickroll escondido
    if grep -rqiIm1 'never gonna give you up' "${dir}" 2>/dev/null; then
        output+="  Never gonna give you up... TE RICKROLLEASTE SOLO."
        output+=$'\n'
    fi

    # 6. Muchos comentarios de copyright/licencia
    local lic_count=0
    lic_count=$(grep -rciIE 'copyright|licen[cs]' "${dir}" 2>/dev/null \
        | awk -F: '{sum+=$NF} END{print sum+0}') || lic_count=0
    lic_count=${lic_count:-0}
    if (( lic_count > 20 )); then
        output+="  ${lic_count} menciones de copyright/licencia. Abogado o programador?"
        output+=$'\n'
    fi

    printf '%s' "${output}"
}

# -------------------------------------------------------------------
# _roast_calcular_score - calcula un puntaje 0-100 para la carpeta.
#
# Arranca en 50 (base neutra) y suma/resta según las estadísticas.
# Es un sistema de scoring humorístico — no pretende ser justo.
#
# Penalizaciones:
#   - TODOs pendientes (-1 cada uno, máximo -10)
#   - Puteadas excesivas (-5 o -10)
#   - Archivos muy viejos (-3 a -15 según antigüedad)
#   - Archivo muy corto (-5)
#   - Archivo muy largo (-5)
#   - Palabra muy repetida (-5)
#   - Muy pocos archivos (-10)
#
# Bonificaciones:
#   - Cero TODOs (+15)
#   - Cero puteadas (+10)
#   - Cantidad razonable de archivos (+10)
#   - Buen volumen de palabras (+5)
#   - Archivos recientes (+10)
#
# args: $1 = directorio
# stdout: número 0-100
# -------------------------------------------------------------------
_roast_calcular_score() {
    local dir="$1"
    local score=50

    local todo_count puteadas_count file_count total_words
    todo_count=$(stats_todos_count "${dir}")
    puteadas_count=$(stats_puteadas "${dir}")
    file_count=$(stats_file_count "${dir}")
    total_words=$(stats_total_words "${dir}")

    local shortest shortest_lines=0
    shortest=$(stats_shortest_file "${dir}")
    [[ -n "${shortest}" ]] && shortest_lines=$(cut -f1 <<< "${shortest}")

    local longest longest_lines=0
    longest=$(stats_longest_file "${dir}")
    [[ -n "${longest}" ]] && longest_lines=$(cut -f1 <<< "${longest}")

    local oldest dias_oldest=0
    oldest=$(stats_oldest_file "${dir}")
    if [[ -n "${oldest}" ]]; then
        local epoch
        epoch=$(cut -f1 <<< "${oldest}")
        dias_oldest=$(stats_dias_desde_epoch "${epoch}")
    fi

    local top top_count=0
    top=$(stats_top_words "${dir}" 1)
    [[ -n "${top}" ]] && top_count=$(awk '{print $1}' <<< "${top}")
    top_count=${top_count:-0}

    # --- Penalizaciones ---
    local todo_penalty=$(( todo_count > 10 ? 10 : todo_count ))
    score=$(( score - todo_penalty ))

    (( puteadas_count > 5 ))  && score=$((score - 5))
    (( puteadas_count > 20 )) && score=$((score - 5))

    if   (( dias_oldest > 365 )); then score=$((score - 15))
    elif (( dias_oldest > 180 )); then score=$((score - 8))
    elif (( dias_oldest > 90 ));  then score=$((score - 3))
    fi

    (( shortest_lines > 0 && shortest_lines < 3 )) && score=$((score - 5))
    (( longest_lines > 500 ))                       && score=$((score - 5))
    (( top_count > 50 ))                            && score=$((score - 5))
    (( file_count > 0 && file_count < 3 ))          && score=$((score - 10))

    # --- Bonificaciones ---
    (( todo_count == 0 && file_count > 0 ))       && score=$((score + 15))
    (( puteadas_count == 0 && file_count > 0 ))   && score=$((score + 10))
    (( file_count >= 5 && file_count <= 30 ))     && score=$((score + 10))
    (( total_words > 1000 ))                      && score=$((score + 5))
    (( dias_oldest >= 0 && dias_oldest < 30 ))    && score=$((score + 10))

    # Clamp 0-100
    (( score < 0 ))   && score=0
    (( score > 100 )) && score=100

    printf '%d' "${score}"
}

# -------------------------------------------------------------------
# _roast_nota_y_frase - convierte un score numérico en una nota tipo
# escolar y una frase descriptiva humorística.
#
# args: $1 = score (0-100)
# stdout: "NOTA|frase descriptiva"
# -------------------------------------------------------------------
_roast_nota_y_frase() {
    local score="$1"
    if   (( score >= 90 )); then echo "S+|Impecable. Seguro hiciste trampa."
    elif (( score >= 80 )); then echo "A|Tu carpeta tiene dignidad. Raro."
    elif (( score >= 70 )); then echo "B|Bastante bien para lo que esperaba."
    elif (( score >= 60 )); then echo "C|Ahí nomás. Estudiante promedio."
    elif (( score >= 50 )); then echo "D|Mediocre. Como mate sin bombilla."
    elif (( score >= 40 )); then echo "E|Preocupante. Reconsiderá tus decisiones."
    elif (( score >= 30 )); then echo "F|Desastre. Reformateá y empezá de cero."
    elif (( score >= 10 )); then echo "F-|Sin palabras. Bueno sí, pero no las puedo decir."
    else                         echo "Z|Tu carpeta rompió la escala. Felicitaciones (?)."
    fi
}

# ===================================================================
# ROAST COMPLETO — encadena los 6 roasts + score + certificado
# ===================================================================

# -------------------------------------------------------------------
# roast_completo - corre todos los roasts en cascada y al final
# muestra un certificado con score, nota, easter eggs y estadísticas.
# -------------------------------------------------------------------
roast_completo() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"

    # Intro dramática
    clear 2>/dev/null || true
    ui_banner "ROAST COMPLETO"
    echo
    ui_cutscene "Activando modo destrucción..."
    sleep 1

    # Los 6 roasts en cascada
    roast_patetico    "${dir}"
    roast_ego         "${dir}"
    roast_repetido    "${dir}"
    roast_todos       "${dir}"
    roast_puteadas    "${dir}"
    roast_abandonados "${dir}"

    # Easter eggs (busca contenido especial)
    local eggs
    eggs=$(_roast_easter_eggs "${dir}")

    # Calcular score y nota final
    ui_cutscene "Calculando tu nota final..."

    local score nota frase nota_frase
    score=$(_roast_calcular_score "${dir}")
    nota_frase=$(_roast_nota_y_frase "${score}")
    nota=$(cut -d'|' -f1 <<< "${nota_frase}")
    frase=$(cut -d'|' -f2 <<< "${nota_frase}")

    # Estadísticas finales
    local total_files total_words total_lines
    total_files=$(stats_file_count  "${dir}")
    total_words=$(stats_total_words "${dir}")
    total_lines=$(stats_total_lines "${dir}")

    # Certificado final
    local tmp
    tmp=$(crear_tempfile)
    {
        printf '===================================================\n'
        printf '       CERTIFICADO DE ROAST OFICIAL\n'
        printf '===================================================\n\n'
        printf '  Carpeta analizada:\n'
        printf '  %s\n\n' "${dir}"
        printf '---------------------------------------------------\n\n'
        printf '                NOTA:  [ %s ]\n' "${nota}"
        printf '                SCORE: %d / 100\n\n' "${score}"
        printf '  "%s"\n\n' "${frase}"
        printf '---------------------------------------------------\n\n'
        printf '  Estadísticas finales:\n'
        printf '    Archivos analizados: %d\n' "${total_files}"
        printf '    Total de palabras:   %d\n' "${total_words}"
        printf '    Total de líneas:     %d\n' "${total_lines}"

        # Easter eggs encontrados
        if [[ -n "${eggs}" ]]; then
            printf '\n---------------------------------------------------\n\n'
            printf '  EASTER EGGS ENCONTRADOS:\n\n'
            printf '%s\n' "${eggs}"
        fi

        printf '\n---------------------------------------------------\n'
        printf '  Fecha: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '===================================================\n\n'
        printf '  Gracias por dejarme burlarme de tu carpeta.\n'
        printf '  (Igual, merecés cada una.)\n'
    } > "${tmp}"

    ui_textbox "Certificado de Roast" "${tmp}"
}
