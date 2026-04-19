#!/usr/bin/env bash
#
# lib/duelo.sh
# -------------------------------------------------------------------
# Duelo de archivos — enfrentamiento 1v1 entre dos archivos al azar.
# Compara estadísticas en 5 categorías y declara un ganador con
# frases dramáticas estilo juego de pelea.
#
# Demuestra: shuf/RANDOM, stat, wc, grep, awk, basename, printf
# con formato tabular, arrays bash, selección aleatoria.
# -------------------------------------------------------------------

# ===================================================================
# HELPERS INTERNOS
# ===================================================================

# -------------------------------------------------------------------
# _duelo_flecha_mas - devuelve una flecha que apunta al ganador
# en categorías donde "más es mejor" (palabras, líneas, etc.).
# args: $1 = valor izquierdo, $2 = valor derecho
# stdout: "<--" si izq gana, "-->" si der gana, " = " si empate
# -------------------------------------------------------------------
_duelo_flecha_mas() {
    if (( $1 > $2 )); then printf '<--'
    elif (( $2 > $1 )); then printf '-->'
    else printf ' = '
    fi
}

# -------------------------------------------------------------------
# _duelo_flecha_menos - devuelve una flecha que apunta al ganador
# en categorías donde "menos es mejor" (TODOs, antigüedad).
# args: $1 = valor izquierdo, $2 = valor derecho
# -------------------------------------------------------------------
_duelo_flecha_menos() {
    if (( $1 < $2 )); then printf '<--'
    elif (( $2 < $1 )); then printf '-->'
    else printf ' = '
    fi
}

# ===================================================================
# DUELO PRINCIPAL
# ===================================================================

# -------------------------------------------------------------------
# duelo_archivos - selecciona dos archivos al azar de la carpeta
# víctima, los enfrenta en 5 categorías y declara un ganador.
#
# Categorías:
#   1. Palabras (más = gana)
#   2. Líneas (más = gana)
#   3. Caracteres (más = gana)
#   4. TODOs (menos = gana)
#   5. Antigüedad en días (menos = gana, más nuevo es mejor)
#
# args: $1 = directorio
# -------------------------------------------------------------------
duelo_archivos() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"

    ui_cutscene "Preparando la arena de combate..."

    # Listar archivos de texto disponibles
    local tmp_lista
    tmp_lista=$(crear_tempfile)
    stats_listar_archivos "${dir}" > "${tmp_lista}"

    local total_archivos
    total_archivos=$(wc -l < "${tmp_lista}" | tr -d ' ')

    if (( total_archivos < 2 )); then
        ui_msgbox "Duelo" "Necesitás al menos 2 archivos de texto para un duelo."
        return 0
    fi

    # --- Elegir dos archivos al azar ---
    local archivo1 archivo2

    if (( HAS_SHUF == 1 )); then
        # shuf garantiza selección uniforme
        archivo1=$(shuf -n 1 "${tmp_lista}")
        archivo2=$(grep -vxF "${archivo1}" "${tmp_lista}" | shuf -n 1)
    else
        # Fallback: $RANDOM con módulo
        local idx1 idx2
        idx1=$(( (RANDOM % total_archivos) + 1 ))
        archivo1=$(sed -n "${idx1}p" "${tmp_lista}")
        idx2=$(( (RANDOM % total_archivos) + 1 ))
        while (( idx2 == idx1 && total_archivos > 1 )); do
            idx2=$(( (RANDOM % total_archivos) + 1 ))
        done
        archivo2=$(sed -n "${idx2}p" "${tmp_lista}")
    fi

    local n1 n2
    n1=$(basename -- "${archivo1}")
    n2=$(basename -- "${archivo2}")

    # --- Calcular stats para cada archivo ---
    local w1 w2 l1 l2 c1 c2 t1 t2 e1 e2 d1 d2

    w1=$(stats_word_count_file "${archivo1}")
    w2=$(stats_word_count_file "${archivo2}")
    l1=$(stats_line_count_file "${archivo1}")
    l2=$(stats_line_count_file "${archivo2}")
    c1=$(stats_char_count_file "${archivo1}")
    c2=$(stats_char_count_file "${archivo2}")

    # TODOs por archivo (grep -c devuelve 0 si no hay matches)
    t1=$(grep -cE '(TODO|FIXME|XXX|HACK)' "${archivo1}" 2>/dev/null || echo 0)
    t2=$(grep -cE '(TODO|FIXME|XXX|HACK)' "${archivo2}" 2>/dev/null || echo 0)

    # Epoch de última modificación
    e1=$(stat -c '%Y' "${archivo1}" 2>/dev/null || echo 0)
    e2=$(stat -c '%Y' "${archivo2}" 2>/dev/null || echo 0)
    d1=$(stats_dias_desde_epoch "${e1}")
    d2=$(stats_dias_desde_epoch "${e2}")

    # --- Calcular score (5 categorías) ---
    local s1=0 s2=0

    # Más palabras → gana
    (( w1 > w2 )) && s1=$((s1 + 1))
    (( w2 > w1 )) && s2=$((s2 + 1))

    # Más líneas → gana
    (( l1 > l2 )) && s1=$((s1 + 1))
    (( l2 > l1 )) && s2=$((s2 + 1))

    # Más caracteres → gana
    (( c1 > c2 )) && s1=$((s1 + 1))
    (( c2 > c1 )) && s2=$((s2 + 1))

    # Menos TODOs → gana
    (( t1 < t2 )) && s1=$((s1 + 1))
    (( t2 < t1 )) && s2=$((s2 + 1))

    # Más reciente (epoch mayor = más nuevo) → gana
    (( e1 > e2 )) && s1=$((s1 + 1))
    (( e2 > e1 )) && s2=$((s2 + 1))

    # --- Pool de frases para el resultado ---
    local -a frases_ganador=(
        "Victoria aplastante. Ni cerca."
        "Un combate desigual desde el inicio."
        "Humillación total. Sin piedad."
        "Fatality. Flawless victory."
        "No fue una pelea, fue una masacre."
        "K.O. en el primer round."
        "Esto no fue un duelo, fue una ejecución."
    )
    local -a frases_empate=(
        "Empate técnico. Ambos son igual de mediocres."
        "Draw. Ninguno merece ganar."
        "Tablas. La mediocridad no tiene favoritos."
    )

    # Elegir frase al azar
    local frase
    if (( s1 == s2 )); then
        if (( HAS_SHUF == 1 )); then
            frase=$(printf '%s\n' "${frases_empate[@]}" | shuf -n 1)
        else
            frase="${frases_empate[$((RANDOM % ${#frases_empate[@]}))]}"
        fi
    else
        if (( HAS_SHUF == 1 )); then
            frase=$(printf '%s\n' "${frases_ganador[@]}" | shuf -n 1)
        else
            frase="${frases_ganador[$((RANDOM % ${#frases_ganador[@]}))]}"
        fi
    fi

    # --- Construir la tarjeta de combate ---
    local tmp
    tmp=$(crear_tempfile)

    {
        printf '===================================================\n'
        printf '            DUELO DE ARCHIVOS\n'
        printf '===================================================\n\n'
        printf '  [1]  %s\n' "${n1}"
        printf '                VS\n'
        printf '  [2]  %s\n\n' "${n2}"

        printf '---------------------------------------------------\n'
        printf '  %-14s  %8s  %5s  %8s\n' "Categoría" "[1]" "" "[2]"
        printf '---------------------------------------------------\n'

        # La flecha <-- o --> apunta al ganador de cada categoría
        printf '  %-14s  %8d   %s   %-8d\n' \
            "Palabras" "${w1}" \
            "$(_duelo_flecha_mas "${w1}" "${w2}")" "${w2}"

        printf '  %-14s  %8d   %s   %-8d\n' \
            "Líneas" "${l1}" \
            "$(_duelo_flecha_mas "${l1}" "${l2}")" "${l2}"

        printf '  %-14s  %8d   %s   %-8d\n' \
            "Caracteres" "${c1}" \
            "$(_duelo_flecha_mas "${c1}" "${c2}")" "${c2}"

        printf '  %-14s  %8d   %s   %-8d\n' \
            "TODOs" "${t1}" \
            "$(_duelo_flecha_menos "${t1}" "${t2}")" "${t2}"

        printf '  %-14s  %7dd   %s   %-7dd\n' \
            "Antigüedad" "${d1}" \
            "$(_duelo_flecha_menos "${d1}" "${d2}")" "${d2}"

        printf '---------------------------------------------------\n\n'

        printf '  PUNTOS:  [1] %d  vs  %d [2]\n\n' "${s1}" "${s2}"

        # Anunciar ganador
        if (( s1 > s2 )); then
            printf '  GANADOR: %s\n' "${n1}"
        elif (( s2 > s1 )); then
            printf '  GANADOR: %s\n' "${n2}"
        else
            printf '  EMPATE\n'
        fi
        printf '  "%s"\n\n' "${frase}"

        printf '===================================================\n'
    } > "${tmp}"

    ui_textbox "Duelo de archivos" "${tmp}"
}
