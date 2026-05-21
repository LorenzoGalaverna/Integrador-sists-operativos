#!/usr/bin/env bash
# test_mejora1.sh
# Verifica la mejora #1: guards de resultado vacío en stats.sh
# Prueba cada función modificada en dos escenarios:
#   A) Directorio con archivos de texto (debe producir output)
#   B) Directorio vacío (debe retornar vacío, sin error)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
DATA_DIR="${SCRIPT_DIR}/data"
export DATA_DIR

TESTS_OK=0
TESTS_FAIL=0

pass() { printf '  [PASS] %s\n' "$1"; TESTS_OK=$((TESTS_OK + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; TESTS_FAIL=$((TESTS_FAIL + 1)); }

# Cargar solo lo necesario (utils para crear_tempfile, stats)
USAR_COLOR=0
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/stats.sh"

DIR_TEST="${SCRIPT_DIR}/test_files"
DIR_VACIO=$(mktemp -d)
trap 'rm -rf "${DIR_VACIO}"' EXIT

printf '\n=== Mejora #1: guards de resultado vacío en stats.sh ===\n\n'

# ------------------------------------------------------------------
# stats_top_words
# ------------------------------------------------------------------
printf '\n--- stats_top_words ---\n'

result=$(stats_top_words "${DIR_TEST}" 5)
if [[ -n "${result}" ]]; then
    pass "con archivos: produce output"
    printf '     (primeras 2 líneas: %s)\n' "$(printf '%s\n' "${result}" | head -2 | tr '\n' '|')"
else
    fail "con archivos: esperaba output, obtuvo vacío"
fi

result=$(stats_top_words "${DIR_VACIO}" 5)
if [[ -z "${result}" ]]; then
    pass "directorio vacío: retorna vacío sin error"
else
    fail "directorio vacío: esperaba vacío, obtuvo '${result}'"
fi

# ------------------------------------------------------------------
# stats_oldest_file
# ------------------------------------------------------------------
printf '\n--- stats_oldest_file ---\n'

result=$(stats_oldest_file "${DIR_TEST}")
if [[ -n "${result}" ]]; then
    pass "con archivos: produce output"
    printf '     (resultado: %s)\n' "${result}"
else
    fail "con archivos: esperaba output, obtuvo vacío"
fi

result=$(stats_oldest_file "${DIR_VACIO}")
if [[ -z "${result}" ]]; then
    pass "directorio vacío: retorna vacío sin error"
else
    fail "directorio vacío: esperaba vacío, obtuvo '${result}'"
fi

# ------------------------------------------------------------------
# stats_shortest_file
# ------------------------------------------------------------------
printf '\n--- stats_shortest_file ---\n'

result=$(stats_shortest_file "${DIR_TEST}")
if [[ -n "${result}" ]]; then
    pass "con archivos: produce output"
    printf '     (resultado: %s)\n' "${result}"
else
    fail "con archivos: esperaba output, obtuvo vacío"
fi

result=$(stats_shortest_file "${DIR_VACIO}")
if [[ -z "${result}" ]]; then
    pass "directorio vacío: retorna vacío sin error"
else
    fail "directorio vacío: esperaba vacío, obtuvo '${result}'"
fi

# ------------------------------------------------------------------
# stats_longest_file
# ------------------------------------------------------------------
printf '\n--- stats_longest_file ---\n'

result=$(stats_longest_file "${DIR_TEST}")
if [[ -n "${result}" ]]; then
    pass "con archivos: produce output"
    printf '     (resultado: %s)\n' "${result}"
else
    fail "con archivos: esperaba output, obtuvo vacío"
fi

result=$(stats_longest_file "${DIR_VACIO}")
if [[ -z "${result}" ]]; then
    pass "directorio vacío: retorna vacío sin error"
else
    fail "directorio vacío: esperaba vacío, obtuvo '${result}'"
fi

# ------------------------------------------------------------------
# Regresión: verificar que callers no se rompen con salida vacía
# ------------------------------------------------------------------
printf '\n--- regresion: callers con directorio vacio ---\n'

shortest=$(stats_shortest_file "${DIR_VACIO}")
shortest_lines=0
[[ -n "${shortest}" ]] && shortest_lines=$(cut -f1 <<< "${shortest}")
if [[ "${shortest_lines}" == "0" ]]; then
    pass "achievements caller: shortest_lines=0 cuando no hay archivos"
else
    fail "achievements caller: shortest_lines='${shortest_lines}', esperaba 0"
fi

oldest=$(stats_oldest_file "${DIR_VACIO}")
dias_oldest=0
if [[ -n "${oldest}" ]]; then
    dias_oldest=$(stats_dias_desde_epoch "$(cut -f1 <<< "${oldest}")")
fi
if [[ "${dias_oldest}" == "0" ]]; then
    pass "roast caller: dias_oldest=0 cuando no hay archivos"
else
    fail "roast caller: dias_oldest='${dias_oldest}', esperaba 0"
fi

top=$(stats_top_words "${DIR_VACIO}" 1)
if [[ -z "${top}" ]]; then
    pass "roast_repetido caller: top vacío cuando no hay archivos"
else
    fail "roast_repetido caller: top='${top}', esperaba vacío"
fi

# ------------------------------------------------------------------
# Resumen
# ------------------------------------------------------------------
printf '\n=== Resultado: %d pasaron, %d fallaron ===\n\n' \
    "${TESTS_OK}" "${TESTS_FAIL}"

(( TESTS_FAIL == 0 ))
