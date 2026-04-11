#!/usr/bin/env bash
#
# lib/menu.sh
# -------------------------------------------------------------------
# Menú principal del script. Loop infinito que despacha a cada
# función según la opción elegida.
# -------------------------------------------------------------------

# ===================================================================
# SELECCIÓN INICIAL DE CARPETA VÍCTIMA
# ===================================================================

# -------------------------------------------------------------------
# menu_pedir_directorio_victima - al arrancar (si no se pasó -d),
# le pide al usuario qué carpeta analizar.
# -------------------------------------------------------------------
menu_pedir_directorio_victima() {
    local default="${DIRECTORIO_VICTIMA:-${PWD}}"
    local elegido

    while true; do
        if ! elegido=$(ui_inputbox "Carpeta víctima" \
            "¿Qué carpeta querés que analice?" \
            "${default}"); then
            # El usuario canceló — salimos del script limpiamente
            log_info "Cancelado por el usuario."
            exit 0
        fi

        if [[ -z "${elegido}" ]]; then
            ui_msgbox "Error" "Tenés que ingresar una ruta."
            continue
        fi

        # Expandir ~ manualmente (dialog no lo hace)
        elegido="${elegido/#\~/${HOME}}"

        if require_dir "${elegido}" 2>/dev/null; then
            DIRECTORIO_VICTIMA="${elegido}"
            return 0
        else
            ui_msgbox "Ruta inválida" "No es un directorio legible:\n\n${elegido}\n\nIntentá con otra."
        fi
    done
}

# ===================================================================
# MENÚ PRINCIPAL
# ===================================================================

# -------------------------------------------------------------------
# menu_main - loop principal con las 10 opciones del proyecto.
# -------------------------------------------------------------------
menu_main() {
    local opcion
    local texto_menu

    while true; do
        texto_menu="Carpeta actual: ${DIRECTORIO_VICTIMA}\n\n¿Qué querés hacer?"

        if ! opcion=$(ui_menu "🔥 ROAST MY FILES v${VERSION}" \
            "${texto_menu}" \
            "1" "🔥 Roast completo (todos los roasts)" \
            "2" "🗑️  El archivo más patético" \
            "3" "📏 Ego en líneas (el más largo)" \
            "4" "🔁 Palabras que repetís" \
            "5" "📌 Cementerio de TODOs" \
            "6" "🤬 Ranking de puteadas" \
            "7" "😴 Archivos abandonados" \
            "8" "🔍 Modo serio — gestor de búsqueda" \
            "9" "💾 Exportar reporte completo" \
            "c" "📂 Cambiar carpeta víctima" \
            "0" "❌ Salir"); then
            # Usuario canceló con ESC — preguntamos si quiere salir
            if ui_yesno "Salir" "¿Salir de Roast My Files?"; then
                return 0
            fi
            continue
        fi

        case "${opcion}" in
            1) roast_completo    "${DIRECTORIO_VICTIMA}" ;;
            2) roast_patetico    "${DIRECTORIO_VICTIMA}" ;;
            3) roast_ego         "${DIRECTORIO_VICTIMA}" ;;
            4) roast_repetido    "${DIRECTORIO_VICTIMA}" ;;
            5) roast_todos       "${DIRECTORIO_VICTIMA}" ;;
            6) roast_puteadas    "${DIRECTORIO_VICTIMA}" ;;
            7) roast_abandonados "${DIRECTORIO_VICTIMA}" ;;
            8) menu_search       ;;
            9) report_generate   "${DIRECTORIO_VICTIMA}" ;;
            c|C) menu_pedir_directorio_victima ;;
            0|"")
                if ui_yesno "Salir" "¿Salir de Roast My Files?"; then
                    return 0
                fi
                ;;
            *) ui_msgbox "Error" "Opción inválida: ${opcion}" ;;
        esac
    done
}
