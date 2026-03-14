#!/bin/bash

# Цвета и функции интерфейса
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export MAGENTA=$(tput setaf 5)
export CYAN=$(tput setaf 6)
export WHITE=$(tput setaf 7)
export RESET=$(tput sgr0)
export BOLD=$(tput bold)
export REV=$(tput rev)

draw_header() {
    local title="$1"
    local subtitle="$2"
    local offset="${3:-12}"               # отступ для "СИСТЕМА УПРАВЛЕНИЯ КАФКА" и "КОНТУР"
    local sub_offset="${4:-$((offset + 3))}"  # отступ для подзаголовка
    local ver_offset="${5:-$((offset + 6))}"  # отступ для версии
    
    tput clear
    echo "${RED}${BOLD}"
    tput cup 2 $((offset - 2))
    echo "СИСТЕМА УПРАВЛЕНИЯ КАФКА"
    
    echo "${GREEN}${REV}"
    tput cup 1 $offset
    echo " КОНТУР ${ENV_NAME} "
    
    echo "${MAGENTA}${REV}"
    tput cup 4 $sub_offset
    echo " ${subtitle} "
    
    echo "${YELLOW}"
    tput cup 5 $ver_offset
    echo "версия ${VERSION}"
    
    echo "${RESET}"
    tput cup 7 0
}

draw_section_header() {
    draw_header "$1" "$2" "$3"
}

print_prompt() {
    echo "${YELLOW}${1}${RESET}"
}

print_error() {
    echo "${RED}❌ Ошибка: ${1}${RESET}"
}

show_success() {
    echo "${GREEN}✅ ${1}${RESET}"
}

show_error() {
    echo "${RED}❌ Ошибка: ${1}${RESET}"
}

show_warning() {
    echo "${YELLOW}⚠️  ${1}${RESET}"
}

show_info() {
    echo "${CYAN}ℹ️  ${1}${RESET}"
}

pause() {
    echo ""
    echo "${GREEN}Нажмите Enter для продолжения...${RESET}"
    read -r
}

read_input() {
    local prompt="$1"
    local default="$2"
    local value
    
    if [[ -n "$default" ]]; then
        # Выводим приглашение в stderr, чтобы не захватывать его
        echo -n "${YELLOW}${prompt} [${default}]: ${RESET}" >&2
    else
        echo -n "${YELLOW}${prompt}: ${RESET}" >&2
    fi
    
    read -r value
    if [[ -z "$value" && -n "$default" ]]; then
        value="$default"
    fi
    # Возвращаем только значение
    echo "$value"
}

confirm_action() {
    local prompt="${1:-Вы уверены?}"
    echo -n "${YELLOW}$prompt (y/n): ${RESET}"
    read -r response
    [[ "$response" =~ ^[YyДд] ]]
}
# Отрисовка логотипа с названием модуля
draw_module_logo() {
    local title="$1"
    tput clear
    echo "${CYAN}${BOLD}"
    echo "   ╔═════════════════════════════════════════════════════════╗"
    echo "   ║         ██╗  ██╗ █████╗ ███████╗██╗  ██╗ █████║         ║"
    echo "   ║         ██║ ██╔╝██╔══██╗██╔════╝██║ ██╔╝██╔══██╗        ║"
    echo "   ║         █████╔╝ ███████║█████╗  █████╔╝ ███████║        ║"
    echo "   ║         ██╔═██╗ ██╔══██║██╔══╝  ██╔═██╗ ██╔══██║        ║"
    echo "   ║         ██║  ██╗██║  ██║██║     ██║  ██╗██║  ██║        ║"
    echo "   ║         ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝        ║"
    echo "   ║  ╔═══════════════════════════════════════════════════╗  ║"
    # Центрируем название модуля (ширина внутренней части 45 символов)
    local inner_width=45
    local text=" $title "
    local text_len=${#text}
    local pad=$(( (inner_width - text_len) / 2 ))
    printf "   ║  ║%*s%*s%*s║  ║\n" $pad "" $text_len "$text" $((inner_width - pad - text_len)) ""
    echo "   ║  ╚═══════════════════════════════════════════════════╝  ║"
    echo "   ║            версия ${VERSION}       ::Egorich88::               ║"
    echo "   ╚═════════════════════════════════════════════════════════╝"
    echo "${RESET}"
}