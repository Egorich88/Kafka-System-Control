#!/bin/bash

# Kafka System Control - Главное меню (версия 3.1)
# Автор: Egorich88

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/config.sh"
source "${SCRIPT_DIR}/scripts/lib/ui.sh"
source "${SCRIPT_DIR}/scripts/lib/utils.sh"

# Отключаем курсор
tput civis
trap 'tput cnorm; exit' EXIT INT TERM

# ASCII-арт
draw_logo() {
    echo "${CYAN}${BOLD}"
    echo "   ╔═════════════════════════════════════════════════════════╗"
    echo "   ║         ██╗  ██╗ █████╗ ███████╗██╗  ██╗ █████║         ║"
    echo "   ║         ██║ ██╔╝██╔══██╗██╔════╝██║ ██╔╝██╔══██╗        ║"
    echo "   ║         █████╔╝ ███████║█████╗  █████╔╝ ███████║        ║"
    echo "   ║         ██╔═██╗ ██╔══██║██╔══╝  ██╔═██╗ ██╔══██║        ║"
    echo "   ║         ██║  ██╗██║  ██║██║     ██║  ██╗██║  ██║        ║"
    echo "   ║         ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝        ║"
    echo "   ║  ╔═══════════════════════════════════════════════════╗  ║"
    echo "   ║  ║           S Y S T E M   C O N T R O L             ║  ║"
    echo "   ║  ╚═══════════════════════════════════════════════════╝  ║"
    echo "   ║            версия ${VERSION}       ::Egorich88::               ║"
    echo "   ╚═════════════════════════════════════════════════════════╝"
    echo "${RESET}"
}

# Массив пунктов меню
MENU_ITEMS=(
    "📋 Описание (describe)"
    "➕ Создание (create)"
    "🗑️ Удаление (delete)"
    "🚪 Выход"
)

MODULES=(
    "${SCRIPT_DIR}/scripts/modules/describe.sh"
    "${SCRIPT_DIR}/scripts/modules/create.sh"
    "${SCRIPT_DIR}/scripts/modules/delete.sh"
    "exit"
)

selected=0

draw_menu() {
    tput clear
    draw_logo
    echo ""
    echo "   ${YELLOW}Используйте стрелки ↑ ↓ для навигации, Enter для выбора${RESET}"
    echo ""
    for i in "${!MENU_ITEMS[@]}"; do
        if [[ $i -eq $selected ]]; then
            echo -n "   ${REV}${GREEN} ▶ ${MENU_ITEMS[$i]} ${RESET}"
        else
            echo -n "     ${MENU_ITEMS[$i]}"
        fi
        echo ""
    done
}

handle_input() {
    local key
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 key
        case "$key" in
            '[A') ((selected--)); [[ $selected -lt 0 ]] && selected=$((${#MENU_ITEMS[@]} - 1)) ;;
            '[B') ((selected++)); [[ $selected -ge ${#MENU_ITEMS[@]} ]] && selected=0 ;;
        esac
    elif [[ $key == "" ]]; then
        return 0
    elif [[ $key == "q" || $key == "Q" ]]; then
        selected=$((${#MENU_ITEMS[@]} - 1))
        return 0
    fi
    return 1
}

main_loop() {
    while true; do
        draw_menu
        if handle_input; then
            choice=$selected
            if [[ ${MODULES[$choice]} == "exit" ]]; then
                clear
                echo "${GREEN}Спасибо за использование Kafka System Control!${RESET}"
                echo "${YELLOW}«Movement – life!»${RESET}"
                sleep 1
                break
            else
                tput cnorm
                ${MODULES[$choice]}
                tput civis
            fi
        fi
    done
}

main_loop
