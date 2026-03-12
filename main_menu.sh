#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/config.sh"
source "${SCRIPT_DIR}/scripts/lib/ui.sh"
source "${SCRIPT_DIR}/scripts/lib/utils.sh"

show_splash() {
    tput clear
    echo "${CYAN}${BOLD}"
    echo "  _  __      __ _ "
    echo " | |/ /__ _ / _| | ____ _"
    echo " | ' // _' | |_| |/ / _' |"
    echo " | . \ (_| |  _|   < (_| |"
    echo " |_|\_\__,_|_| |_|\_\__,_|"
    echo "  ____            _ "
    echo " / ___| _   _ ___| |_ ___ _ __ ___ "
    echo " \___ \| | | / __| __/ _ \ '_ ' _ \ "
    echo "  ___) | |_| \__ \ ||  __/ | | | | |"
    echo " |____/ \__, |___/\__\___|_| |_| |_|"
    echo "        |___/                       "
    echo "   ____            _             _ "
    echo "  / ___|___  _ __ | |_ _ __ ___ | |"
    echo " | |   / _ \| '_ \| __| '__/ _ \| |"
    echo " | |__| (_) | | | | |_| | | (_) | |"
    echo "  \____\___/|_| |_|\__|_|  \___/|_|"
    echo "" 
    echo "  :: ${YELLOW}Egorich88${RESET} :: версия ${VERSION}"
    echo ""
    sleep 2
}

main_menu() {
    while true; do
        draw_header "ГЛАВНОЕ МЕНЮ" "О С Н О В Н О Е  М Е Н Ю" 12 5 14
        PS3="$(print_prompt 'Выберите действие [1-4]') "
        options=(
            "📋 Описание (describe)"
            "➕ Создание (create)"
            "🗑️ Удаление (delete)"
            "🚪 Выход"
        )
        select opt in "${options[@]}"; do
            case $opt in
                "📋 Описание (describe)")
                    "${SCRIPT_DIR}/scripts/modules/describe.sh"
                    break
                    ;;
                "➕ Создание (create)")
                    "${SCRIPT_DIR}/scripts/modules/create.sh"
                    break
                    ;;
                "🗑️ Удаление (delete)")
                    "${SCRIPT_DIR}/scripts/modules/delete.sh"
                    break
                    ;;
                "🚪 Выход")
                    clear
                    echo "${GREEN}До свидания!${RESET}"
                    exit 0
                    ;;
                *)
                    echo "$(print_error 'Недействительный вариант') $REPLY"
                    sleep 1
                    break
                    ;;
            esac
        done
    done
}

show_splash
main_menu
