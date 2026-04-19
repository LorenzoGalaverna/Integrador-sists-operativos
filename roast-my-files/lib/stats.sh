#!/usr/bin/env bash
#
# lib/stats.sh
# -------------------------------------------------------------------
# Motor de análisis estadístico de archivos de texto.
# Cada función toma un archivo o directorio y devuelve datos crudos
# que después consumen los roasts y el generador de reportes.
#
# Todas las salidas se hacen por stdout en formato simple (una línea
# por registro, separadas por tabs) para que sean fáciles de parsear
# con `read` en bash.
# -------------------------------------------------------------------

# ===================================================================
# LISTADO DE ARCHIVOS DE TEXTO
# ===================================================================

# -------------------------------------------------------------------
# stats_listar_archivos - lista archivos de texto en un directorio,
# excluyendo binarios y archivos ocultos.
#
# Truco clave: `grep -Iq .` trata binarios como no-coincidentes, así
# que -print solo dispara para archivos de texto.
#
# args: $1 = directorio
# stdout: una ruta por línea
# -------------------------------------------------------------------
stats_listar_archivos() {
    local dir="$1"
    find "${dir}" \
        -type f \
        -not -path '*/\.*' \
        -exec grep -Iq . {} \; \
        -print 2>/dev/null
}

# -------------------------------------------------------------------
# stats_file_count - cantidad de archivos de texto en el directorio.
# args: $1 = directorio
# stdout: número entero
# -------------------------------------------------------------------
stats_file_count() {
    local dir="$1"
    stats_listar_archivos "${dir}" | wc -l | tr -d ' '
}

# ===================================================================
# CONTEOS POR ARCHIVO
# ===================================================================

# -------------------------------------------------------------------
# stats_word_count_file - palabras en un archivo.
# args: $1 = archivo
# stdout: número
# -------------------------------------------------------------------
stats_word_count_file() {
    local archivo="$1"
    wc -w < "${archivo}" | tr -d ' '
}

# -------------------------------------------------------------------
# stats_line_count_file - líneas en un archivo.
# args: $1 = archivo
# stdout: número
# -------------------------------------------------------------------
stats_line_count_file() {
    local archivo="$1"
    wc -l < "${archivo}" | tr -d ' '
}

# -------------------------------------------------------------------
# stats_char_count_file - caracteres en un archivo.
# -------------------------------------------------------------------
stats_char_count_file() {
    local archivo="$1"
    wc -c < "${archivo}" | tr -d ' '
}

# ===================================================================
# TOTALES POR DIRECTORIO
# ===================================================================

# -------------------------------------------------------------------
# stats_total_words - suma de todas las palabras en todos los
# archivos de texto del directorio.
# -------------------------------------------------------------------
stats_total_words() {
    local dir="$1"
    local total=0
    local palabras
    local archivo

    while IFS= read -r archivo; do
        palabras=$(stats_word_count_file "${archivo}")
        total=$((total + palabras))
    done < <(stats_listar_archivos "${dir}")

    printf '%d' "${total}"
}

# -------------------------------------------------------------------
# stats_total_lines - suma de líneas en todos los archivos.
# -------------------------------------------------------------------
stats_total_lines() {
    local dir="$1"
    local total=0
    local lineas
    local archivo

    while IFS= read -r archivo; do
        lineas=$(stats_line_count_file "${archivo}")
        total=$((total + lineas))
    done < <(stats_listar_archivos "${dir}")

    printf '%d' "${total}"
}

# ===================================================================
# TOP PALABRAS (la joya del proyecto)
# ===================================================================

# -------------------------------------------------------------------
# stats_top_words - top N palabras más frecuentes excluyendo stopwords.
#
# Pipeline:
#   1. Concatenar el contenido de todos los archivos de texto
#   2. Awk: para cada línea, reemplazar no-letras por espacios y
#      escupir cada palabra (en minúsculas, mín 3 letras) en una
#      línea propia. Awk es más portable que sed con \+ y maneja
#      mejor UTF-8 con la locale apropiada.
#   3. Filtrar stopwords del español (data/stopwords_es.txt)
#   4. Ordenar, contar únicos con uniq -c, ordenar por conteo
#   5. Tomar los primeros N
#
# args: $1 = dir, $2 = N (default 10)
# stdout: líneas con formato "  COUNT PALABRA"
# -------------------------------------------------------------------
stats_top_words() {
    local dir="$1"
    local n="${2:-10}"
    local stopwords="${DATA_DIR}/stopwords_es.txt"
    local tmp_texto
    tmp_texto=$(crear_tempfile)

    # Pasos 1-2: concatenar todo, tokenizar con awk
    while IFS= read -r archivo; do
        cat -- "${archivo}" 2>/dev/null || true
    done < <(stats_listar_archivos "${dir}") \
        | awk '{
            # Reemplazar cualquier cosa que no sea letra (incluyendo
            # acentuadas en español) con un espacio. Después iterar
            # sobre los campos resultantes.
            gsub(/[^[:alpha:]áéíóúüñÁÉÍÓÚÜÑ]/, " ")
            for (i = 1; i <= NF; i++) {
                w = tolower($i)
                # Filtrar palabras muy cortas (ruido tipo "a", "el", "de")
                if (length(w) > 2) {
                    print w
                }
            }
        }' > "${tmp_texto}" || true

    # Paso 3-5: filtrar stopwords y rankear
    if [[ -s "${stopwords}" ]]; then
        grep -vxFf "${stopwords}" "${tmp_texto}" 2>/dev/null \
            | sort | uniq -c | sort -rn | head -n "${n}" || true
    else
        sort "${tmp_texto}" | uniq -c | sort -rn | head -n "${n}"
    fi
}

# ===================================================================
# TODOs Y FIXMEs
# ===================================================================

# -------------------------------------------------------------------
# stats_todos - busca todos los TODO/FIXME/XXX/HACK en los archivos.
# args: $1 = directorio
# stdout: líneas tipo "archivo:linea:contenido"
# -------------------------------------------------------------------
stats_todos() {
    local dir="$1"
    # -r recursivo, -n con número de línea, -I ignora binarios,
    # -E regex extendida
    grep -rnIE '(TODO|FIXME|XXX|HACK)' "${dir}" 2>/dev/null || true
}

# -------------------------------------------------------------------
# stats_todos_count - cantidad total de TODOs.
# -------------------------------------------------------------------
stats_todos_count() {
    stats_todos "$1" | wc -l | tr -d ' '
}

# ===================================================================
# PUTEADAS
# ===================================================================

# -------------------------------------------------------------------
# stats_puteadas - cuenta la aparición total de palabrotas.
# Usa la lista en data/puteadas.txt como patrones de grep.
#
# args: $1 = directorio
# stdout: número total de ocurrencias
# -------------------------------------------------------------------
stats_puteadas() {
    local dir="$1"
    local patrones="${DATA_DIR}/puteadas.txt"
    local total=0
    local count
    local archivo

    if [[ ! -s "${patrones}" ]]; then
        printf '0'
        return 0
    fi

    while IFS= read -r archivo; do
        # -c cuenta, -i case-insensitive, -w palabra completa,
        # -f lee patrones desde archivo.
        # grep -c siempre imprime un número (0 si no hay matches),
        # solo necesitamos '|| true' para que no aborte con set -e
        # cuando no hay matches.
        count=$(grep -ciwf "${patrones}" "${archivo}" 2>/dev/null || true)
        count=${count:-0}
        total=$((total + count))
    done < <(stats_listar_archivos "${dir}")

    printf '%d' "${total}"
}

# -------------------------------------------------------------------
# stats_puteadas_ranking - ranking de palabrotas más usadas.
# stdout: "CONTEO PALABRA" una por línea
# -------------------------------------------------------------------
stats_puteadas_ranking() {
    local dir="$1"
    local patrones="${DATA_DIR}/puteadas.txt"
    local archivo

    if [[ ! -s "${patrones}" ]]; then
        return 0
    fi

    {
        while IFS= read -r archivo; do
            grep -oiwf "${patrones}" "${archivo}" 2>/dev/null || true
        done < <(stats_listar_archivos "${dir}")
    } \
        | tr '[:upper:]' '[:lower:]' \
        | sort | uniq -c | sort -rn | head -10 || true
}

# ===================================================================
# ARCHIVOS EXTREMOS (el más viejo, más corto, más largo)
# ===================================================================

# -------------------------------------------------------------------
# stats_oldest_file - archivo más antiguo por fecha de modificación.
# args: $1 = directorio
# stdout: "EPOCH<TAB>RUTA"
# -------------------------------------------------------------------
stats_oldest_file() {
    local dir="$1"
    local archivo
    local epoch

    {
        while IFS= read -r archivo; do
            epoch=$(stat -c '%Y' "${archivo}" 2>/dev/null || echo 0)
            printf '%d\t%s\n' "${epoch}" "${archivo}"
        done < <(stats_listar_archivos "${dir}")
    } | sort -n | head -1
}

# -------------------------------------------------------------------
# stats_shortest_file - archivo con menos líneas (excluyendo vacíos).
# args: $1 = directorio
# stdout: "LINEAS<TAB>RUTA"
# -------------------------------------------------------------------
stats_shortest_file() {
    local dir="$1"
    local archivo
    local lineas

    {
        while IFS= read -r archivo; do
            lineas=$(stats_line_count_file "${archivo}")
            # Ignorar vacíos para no premiar el caso trivial
            if (( lineas > 0 )); then
                printf '%d\t%s\n' "${lineas}" "${archivo}"
            fi
        done < <(stats_listar_archivos "${dir}")
    } | sort -n | head -1
}

# -------------------------------------------------------------------
# stats_longest_file - archivo con más líneas.
# args: $1 = directorio
# stdout: "LINEAS<TAB>RUTA"
# -------------------------------------------------------------------
stats_longest_file() {
    local dir="$1"
    local archivo
    local lineas

    {
        while IFS= read -r archivo; do
            lineas=$(stats_line_count_file "${archivo}")
            printf '%d\t%s\n' "${lineas}" "${archivo}"
        done < <(stats_listar_archivos "${dir}")
    } | sort -rn | head -1
}

# ===================================================================
# HELPERS DE FORMATO
# ===================================================================

# -------------------------------------------------------------------
# stats_dias_desde_epoch - cuántos días pasaron desde un epoch.
# args: $1 = timestamp unix
# stdout: número de días
# -------------------------------------------------------------------
stats_dias_desde_epoch() {
    local epoch="$1"
    local ahora
    ahora=$(date +%s)
    echo $(( (ahora - epoch) / 86400 ))
}

# -------------------------------------------------------------------
# stats_fecha_legible - convierte epoch a fecha legible.
# args: $1 = epoch
# -------------------------------------------------------------------
stats_fecha_legible() {
    local epoch="$1"
    date -d "@${epoch}" '+%Y-%m-%d' 2>/dev/null || echo "fecha desconocida"
}

# ===================================================================
# DETECCIÓN DE MAYÚSCULAS Y DUPLICADOS
# ===================================================================

# -------------------------------------------------------------------
# stats_lineas_gritando - cuenta líneas que son mayormente MAYÚSCULAS
# (5+ caracteres alfabéticos, más del 70% en mayúsculas).
#
# Usa awk con gsub para contar mayúsculas y minúsculas por línea.
# El truco: gsub() devuelve el número de sustituciones hechas, y al
# reemplazar letras por sí mismas no altera el texto, solo las cuenta.
#
# Pipeline: concatenar archivos → awk analiza cada línea.
#
# args: $1 = directorio
# stdout: número de líneas "gritando"
# -------------------------------------------------------------------
stats_lineas_gritando() {
    local dir="$1"
    local archivo

    {
        while IFS= read -r archivo; do
            cat -- "${archivo}" 2>/dev/null || true
        done < <(stats_listar_archivos "${dir}")
    } | awk '
        length >= 5 {
            linea = $0
            upper = gsub(/[A-Z]/, "X", linea)
            linea = $0
            lower = gsub(/[a-z]/, "x", linea)
            alpha = upper + lower
            if (alpha > 0 && upper > alpha * 0.7) total++
        }
        END { print total+0 }
    '
}

# -------------------------------------------------------------------
# stats_lineas_duplicadas - cuenta cuántas líneas aparecen repetidas
# entre todos los archivos de texto del directorio.
#
# Ignora líneas vacías y muy cortas (< 3 chars) para evitar falsos
# positivos con líneas triviales como "}" o "fi".
#
# Pipeline: concatenar todo → awk cuenta frecuencias → suma extras.
# "Extras" = para cada línea que aparece N veces, cuenta N-1
# (la primera aparición es legítima, las demás son duplicados).
#
# args: $1 = directorio
# stdout: número de líneas duplicadas (extras, no el total)
# -------------------------------------------------------------------
stats_lineas_duplicadas() {
    local dir="$1"
    local archivo

    {
        while IFS= read -r archivo; do
            cat -- "${archivo}" 2>/dev/null || true
        done < <(stats_listar_archivos "${dir}")
    } | awk '
        NF > 0 && length >= 3 {
            count[$0]++
        }
        END {
            total = 0
            for (line in count) {
                if (count[line] > 1) {
                    total += count[line] - 1
                }
            }
            print total
        }
    '
}
