#!/usr/bin/env bash
#
# lib/achievements.sh
# -------------------------------------------------------------------
# Sistema de logros/achievements — gamificación del análisis.
# Evalúa la carpeta víctima y desbloquea "medallas" según lo que
# encuentra en los archivos.
#
# Usa stats.sh para evaluar cada condición y ui.sh para mostrar
# los resultados con una barra de progreso visual.
#
# Demuestra: condicionales, aritmética bash, printf con formato,
# integración con el motor de stats, loops de evaluación.
# -------------------------------------------------------------------

# ===================================================================
# EVALUACIÓN Y DISPLAY DE LOGROS
# ===================================================================

# -------------------------------------------------------------------
# achievements_mostrar - evalúa todos los logros posibles contra la
# carpeta víctima y muestra cuáles se desbloquearon.
#
# Logros disponibles (14 en total):
#   - Minimalista Extremo: archivo < 3 líneas
#   - Novelista Frustrado: archivo > 500 líneas
#   - Loro Repetidor: palabra usada > 50 veces
#   - Boca Sucia: > 10 puteadas
#   - Coleccionista de TODOs: > 20 TODOs
#   - Procrastinador Serial: archivo sin tocar > 365 días
#   - Carpeta Fantasma: < 3 archivos de texto
#   - Acumulador Digital: > 50 archivos
#   - Perfeccionista: 0 TODOs
#   - Gritón: > 10 líneas en MAYÚSCULAS
#   - Ctrl+C Ctrl+V: > 15 líneas duplicadas
#   - Buen Samaritano: 0 puteadas
#   - Arqueólogo: archivo de hace > 2 años
#   - Grafómano: > 10.000 palabras en total
#
# args: $1 = directorio a analizar
# -------------------------------------------------------------------
achievements_mostrar() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"
    local desbloqueados=0
    local total=14
    local tmp

    ui_cutscene "Evaluando logros desbloqueados..."

    # --- Cachear estadísticas para no recalcular ---
    local file_count shortest longest oldest top_words
    local todo_count puteadas_count total_words
    local shortest_lines=0 longest_lines=0 top_count=0
    local dias_oldest=0

    file_count=$(stats_file_count "${dir}")

    shortest=$(stats_shortest_file "${dir}")
    [[ -n "${shortest}" ]] && shortest_lines=$(cut -f1 <<< "${shortest}")

    longest=$(stats_longest_file "${dir}")
    [[ -n "${longest}" ]] && longest_lines=$(cut -f1 <<< "${longest}")

    oldest=$(stats_oldest_file "${dir}")
    if [[ -n "${oldest}" ]]; then
        local oldest_epoch
        oldest_epoch=$(cut -f1 <<< "${oldest}")
        dias_oldest=$(stats_dias_desde_epoch "${oldest_epoch}")
    fi

    top_words=$(stats_top_words "${dir}" 1)
    if [[ -n "${top_words}" ]]; then
        top_count=$(awk '{print $1}' <<< "${top_words}" | head -1)
    fi
    top_count=${top_count:-0}

    todo_count=$(stats_todos_count "${dir}")
    puteadas_count=$(stats_puteadas "${dir}")
    total_words=$(stats_total_words "${dir}")

    # Stats nuevas para logros especiales
    local gritando duplicadas
    gritando=$(stats_lineas_gritando "${dir}")
    duplicadas=$(stats_lineas_duplicadas "${dir}")

    # --- Construir output ---
    tmp=$(crear_tempfile)

    {
        printf '===================================================\n'
        printf '           LOGROS DESBLOQUEADOS\n'
        printf '===================================================\n\n'

        # Logro 1: Minimalista Extremo
        if (( shortest_lines > 0 && shortest_lines < 3 )); then
            printf '  [X]  Minimalista Extremo\n'
            printf '       Archivo de menos de 3 líneas. ¿Para qué existe?\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 2: Novelista Frustrado
        if (( longest_lines > 500 )); then
            printf '  [X]  Novelista Frustrado\n'
            printf '       Archivo de +500 líneas. Tolstoy te envidia.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 3: Loro Repetidor
        if (( top_count > 50 )); then
            printf '  [X]  Loro Repetidor\n'
            printf '       Una palabra usada +50 veces. Diccionario, te suena?\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 4: Boca Sucia
        if (( puteadas_count > 10 )); then
            printf '  [X]  Boca Sucia\n'
            printf '       +10 puteadas detectadas. Tu mamá estaría orgullosa.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 5: Coleccionista de TODOs
        if (( todo_count > 20 )); then
            printf '  [X]  Coleccionista de TODOs\n'
            printf '       +20 TODOs pendientes. Maestro de la procrastinación.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 6: Procrastinador Serial
        if (( dias_oldest > 365 )); then
            printf '  [X]  Procrastinador Serial\n'
            printf '       Archivo sin tocar hace más de un año.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 7: Carpeta Fantasma
        if (( file_count > 0 && file_count < 3 )); then
            printf '  [X]  Carpeta Fantasma\n'
            printf '       Menos de 3 archivos. ¿Recién arrancás?\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 8: Acumulador Digital
        if (( file_count > 50 )); then
            printf '  [X]  Acumulador Digital\n'
            printf '       +50 archivos. Marie Kondo lloraría.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 9: Perfeccionista
        if (( todo_count == 0 && file_count > 0 )); then
            printf '  [X]  Perfeccionista\n'
            printf '       Cero TODOs pendientes. ¿Sos real?\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 10: Gritón
        if (( gritando > 10 )); then
            printf '  [X]  Gritón\n'
            printf '       +10 líneas en MAYÚSCULAS. DEJÁ DE GRITAR.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 11: Ctrl+C Ctrl+V
        if (( duplicadas > 15 )); then
            printf '  [X]  Ctrl+C Ctrl+V\n'
            printf '       +15 líneas duplicadas. Copy-paste profesional.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 12: Buen Samaritano
        if (( puteadas_count == 0 && file_count > 0 )); then
            printf '  [X]  Buen Samaritano\n'
            printf '       Cero puteadas. ¿Escribís para tu abuela?\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 13: Arqueólogo
        if (( dias_oldest > 730 )); then
            printf '  [X]  Arqueólogo\n'
            printf '       Archivo de hace más de 2 años. Hallazgo fósil.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # Logro 14: Grafómano
        if (( total_words > 10000 )); then
            printf '  [X]  Grafómano\n'
            printf '       +10.000 palabras en total. Escribiste una tesis.\n\n'
            desbloqueados=$((desbloqueados + 1))
        fi

        # --- Resumen ---
        if (( desbloqueados == 0 )); then
            printf '  (ningún logro desbloqueado)\n'
            printf '  Tu carpeta es... normal. Qué aburrido.\n\n'
        fi

        printf '===================================================\n'
        printf '  Desbloqueaste %d de %d logros\n' \
            "${desbloqueados}" "${total}"
        printf '===================================================\n'

        # Barra de progreso visual con caracteres ASCII
        local barras vacios pct i
        if (( total > 0 )); then
            pct=$(( (desbloqueados * 100) / total ))
            barras=$(( (desbloqueados * 20) / total ))
        else
            pct=0
            barras=0
        fi
        vacios=$(( 20 - barras ))

        printf '\n  ['
        for (( i=0; i<barras; i++ )); do printf '#'; done
        for (( i=0; i<vacios; i++ )); do printf '.'; done
        printf '] %d%%\n' "${pct}"

    } > "${tmp}"

    ui_textbox "Logros desbloqueados" "${tmp}"
}
