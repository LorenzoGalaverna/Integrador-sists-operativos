#!/usr/bin/env bash
#
# lib/report.sh
# -------------------------------------------------------------------
# Exportación de reportes completos a archivos .txt con timestamp.
# Junta todas las estadísticas en un solo documento formateado.
# -------------------------------------------------------------------

# ===================================================================
# GENERACIÓN DE REPORTE
# ===================================================================

# -------------------------------------------------------------------
# report_generate - genera un reporte completo de la carpeta víctima
# y lo guarda en reportes/roast_TIMESTAMP.txt.
#
# Secciones del reporte:
#   1. Metadata (fecha, carpeta, usuario, hostname)
#   2. Estadísticas generales
#   3. Top palabras
#   4. TODOs encontrados
#   5. Puteadas
#   6. Archivos extremos (más corto, más largo, más viejo)
#
# args: $1 = directorio a analizar (default: DIRECTORIO_VICTIMA)
# -------------------------------------------------------------------
report_generate() {
    local dir="${1:-${DIRECTORIO_VICTIMA}}"

    if ! require_dir "${dir}"; then
        ui_msgbox "Error" "No se puede generar reporte: directorio inválido"
        return 1
    fi

    # Crear el directorio de reportes si no existe
    if ! mkdir -p "${REPORTES_DIR}"; then
        ui_msgbox "Error" "No se pudo crear el directorio de reportes: ${REPORTES_DIR}"
        return 1
    fi

    local timestamp destino
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    destino="${REPORTES_DIR}/roast_${timestamp}.txt"

    ui_cutscene "Generando reporte completo..."

    # Recolectamos todo lo que vamos a necesitar (caché)
    local total_files total_words total_lines
    local shortest longest oldest top_words todos_list todos_count puteadas_total puteadas_rank

    total_files=$(stats_file_count  "${dir}")
    total_words=$(stats_total_words "${dir}")
    total_lines=$(stats_total_lines "${dir}")
    shortest=$(stats_shortest_file  "${dir}")
    longest=$(stats_longest_file    "${dir}")
    oldest=$(stats_oldest_file      "${dir}")
    top_words=$(stats_top_words     "${dir}" 15)
    todos_list=$(stats_todos        "${dir}")
    todos_count=$(stats_todos_count "${dir}")
    puteadas_total=$(stats_puteadas "${dir}")
    puteadas_rank=$(stats_puteadas_ranking "${dir}")

    # Escribir el archivo de reporte
    {
        printf '===================================================================\n'
        printf '  ROAST MY FILES — REPORTE COMPLETO\n'
        printf '===================================================================\n\n'

        printf '1. METADATA\n'
        printf '%s\n' '-------------------------------------------------------------------'
        printf '  Generado:     %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '  Carpeta:      %s\n' "${dir}"
        printf '  Usuario:      %s\n' "${USER:-$(whoami)}"
        printf '  Hostname:     %s\n' "$(hostname)"
        printf '  Script:       %s v%s\n' "${NOMBRE_PROYECTO}" "${VERSION}"
        printf '\n'

        printf '2. ESTADÍSTICAS GENERALES\n'
        printf '%s\n' '-------------------------------------------------------------------'
        printf '  Archivos de texto analizados: %d\n' "${total_files}"
        printf '  Total de palabras:            %d\n' "${total_words}"
        printf '  Total de líneas:              %d\n' "${total_lines}"
        printf '\n'

        printf '3. ARCHIVOS EXTREMOS\n'
        printf '%s\n' '-------------------------------------------------------------------'
        if [[ -n "${shortest}" ]]; then
            printf '  Más corto:  %s líneas  -->  %s\n' \
                "$(cut -f1 <<< "${shortest}")" "$(cut -f2 <<< "${shortest}")"
        fi
        if [[ -n "${longest}" ]]; then
            printf '  Más largo:  %s líneas  -->  %s\n' \
                "$(cut -f1 <<< "${longest}")" "$(cut -f2 <<< "${longest}")"
        fi
        if [[ -n "${oldest}" ]]; then
            local oldest_epoch oldest_file dias
            oldest_epoch=$(cut -f1 <<< "${oldest}")
            oldest_file=$(cut -f2 <<< "${oldest}")
            dias=$(stats_dias_desde_epoch "${oldest_epoch}")
            printf '  Más viejo:  %s (hace %d días)  -->  %s\n' \
                "$(stats_fecha_legible "${oldest_epoch}")" "${dias}" "${oldest_file}"
        fi
        printf '\n'

        printf '4. TOP 15 PALABRAS MÁS USADAS\n'
        printf '%s\n' '-------------------------------------------------------------------'
        printf '  CONTEO  PALABRA\n'
        if [[ -n "${top_words}" ]]; then
            printf '%s\n' "${top_words}"
        else
            printf '  (sin datos)\n'
        fi
        printf '\n'

        printf '5. TODOs / FIXMEs / XXX / HACK\n'
        printf '%s\n' '-------------------------------------------------------------------'
        printf '  Total: %d\n\n' "${todos_count}"
        if [[ -n "${todos_list}" ]]; then
            printf '%s\n' "${todos_list}"
        else
            printf '  (ninguno)\n'
        fi
        printf '\n'

        printf '6. PUTEADAS\n'
        printf '%s\n' '-------------------------------------------------------------------'
        printf '  Total detectadas: %d\n\n' "${puteadas_total}"
        if [[ -n "${puteadas_rank}" ]]; then
            printf '  Ranking (CONTEO PALABRA):\n'
            printf '%s\n' "${puteadas_rank}"
        else
            printf '  (ninguna — sos formal)\n'
        fi
        printf '\n'

        printf '===================================================================\n'
        printf '  Fin del reporte\n'
        printf '===================================================================\n'
    } > "${destino}"

    ui_msgbox "Reporte generado" "Reporte guardado en:\n\n${destino}\n\nPodés verlo con:\n  less ${destino}"

    # Ofrecer abrirlo ahora
    if ui_yesno "Ver reporte" "¿Querés ver el reporte ahora?"; then
        ui_textbox "Reporte: ${timestamp}" "${destino}"
    fi
}
