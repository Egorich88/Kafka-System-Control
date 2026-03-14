#!/bin/bash

# Kafka System Control - Главное меню (версия Dendy)
# Версия 3.0 | Егор Хоменко (Egorich88)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/config.sh"
source "${SCRIPT_DIR}/scripts/lib/ui.sh"
source "${SCRIPT_DIR}/scripts/lib/utils.sh"

# Отключаем курсор для чистоты интерфейса
tput civis

# Функция восстановления курсора при выходе
restore_cursor() {
    tput cnorm
    exit 0
}
trap restore_cursor EXIT INT TERM

# ASCII-арт в стиле NES (Mario-подобный)
draw_logo() {
    echo "${CYAN}${BOLD}"
    echo "   ╔═════════════════════════════════════════════════════════╗"
    echo "   ║  ██╗  ██╗ █████╗ ███████╗██╗  ██╗ █████╗                ║"
    echo "   ║  ██║ ██╔╝██╔══██╗██╔════╝██║ ██╔╝██╔══██╗               ║"
    echo "   ║  █████╔╝ ███████║█████╗  █████╔╝ ███████║               ║"
    echo "   ║  ██╔═██╗ ██╔══██║██╔══╝  ██╔═██╗ ██╔══██║               ║"
    echo "   ║  ██║  ██╗██║  ██║██║     ██║  ██╗██║  ██║               ║"
    echo "   ║  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝               ║"
    echo "   ║  ╔═══════════════════════════════════════════════════╗  ║"
    echo "   ║  ║           S Y S T E M   C O N T R O L             ║  ║"
    echo "   ║  ╚═══════════════════════════════════════════════════╝  ║"
    echo "   ║                  версия ${VERSION}                      ║"
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

# Соответствующие команды (скрипты)
MODULES=(
    "${SCRIPT_DIR}/scripts/modules/describe.sh"
    "${SCRIPT_DIR}/scripts/modules/create.sh"
    "${SCRIPT_DIR}/scripts/modules/delete.sh"
    "exit"
)

# Текущий выбранный пункт (0 - первый)
selected=0

# Функция отрисовки меню
draw_menu() {
    tput clear
    draw_logo
    echo ""
    echo "   ${YELLOW}Используйте стрелки ↑ ↓ для навигации, Enter для выбора${RESET}"
    echo ""

    for i in "${!MENU_ITEMS[@]}"; do
        if [[ $i -eq $selected ]]; then
            # Подсвеченный пункт (реверсивные цвета)
            echo -n "   ${REV}${GREEN} ▶ ${MENU_ITEMS[$i]} ${RESET}"
            # Добавим немного пробелов для ровности (опционально)
            # Можно использовать printf для выравнивания, но не обязательно
        else
            echo -n "     ${MENU_ITEMS[$i]}"
        fi
        echo ""
    done
}

# Функция обработки нажатий
handle_input() {
    local key
    # Читаем один символ
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        # Если это escape-последовательность, читаем следующие два символа
        read -rsn2 key
        case "$key" in
            '[A') # стрелка вверх
                ((selected--))
                if [[ $selected -lt 0 ]]; then
                    selected=$((${#MENU_ITEMS[@]} - 1))
                fi
                ;;
            '[B') # стрелка вниз
                ((selected++))
                if [[ $selected -ge ${#MENU_ITEMS[@]} ]]; then
                    selected=0
                fi
                ;;
        esac
    elif [[ $key == "" ]]; then
        # Enter (пустая строка)
        return 0
    elif [[ $key == "q" || $key == "Q" ]]; then
        # Выход по q
        selected=$((${#MENU_ITEMS[@]} - 1))
        return 0
    fi
    return 1
}

# Главный цикл
main_loop() {
    while true; do
        draw_menu
        if handle_input; then
            # Enter нажат
            choice=$selected
            if [[ ${MODULES[$choice]} == "exit" ]]; then
                clear
                echo "${GREEN}Спасибо за использование Kafka System Control!${RESET}"
                echo "${YELLOW}«Movement – life!»${RESET}"
                sleep 1
                break
            else
                # Запускаем модуль
                tput cnorm  # включаем курсор для дочерних скриптов
                ${MODULES[$choice]}
                tput civis  # снова выключаем
            fi
        fi
    done
}

# Запуск
main_loop
restore_cursor