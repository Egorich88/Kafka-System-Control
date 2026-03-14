#!/bin/bash

# Модуль удаления ресурсов Kafka (топики, группы, ACL)
# Версия 3.1 | Егор Хоменко (Egorich88)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

tput civis
trap 'tput cnorm' EXIT INT TERM

# --- Удаление топика ---
delete_topic() {
    draw_module_logo "УДАЛЕНИЕ ТОПИКА"   # <-- используем единый логотип
    echo ""
    local topic
    topic=$(read_input "Введите имя топика для удаления")
    [[ -z "$topic" ]] && { show_error "Имя топика не может быть пустым"; pause; return; }

    echo ""
    show_warning "Удаление топика приведёт к потере всех данных в нём!"
    if confirm_action "Удалить топик '$topic'?"; then
        run_kafka_cmd "topics" "--delete --topic $topic"
        if [ $? -eq 0 ]; then
            log_action "INFO" "Удалён топик: $topic"
        else
            log_action "ERROR" "Ошибка при удалении топика: $topic"
        fi
    else
        show_info "Операция отменена"
    fi
    pause
}

# --- Удаление группы потребителей ---
delete_consumer_group() {
    draw_module_logo "УДАЛЕНИЕ ГРУППЫ"
    echo ""
    local group
    group=$(read_input "Введите имя группы потребителей для удаления")
    [[ -z "$group" ]] && { show_error "Имя группы не может быть пустым"; pause; return; }

    echo ""
    show_warning "Удаление группы может повлиять на работу потребителей."
    if confirm_action "Удалить группу '$group'?"; then
        run_kafka_cmd "consumer-groups" "--delete --group $group"
        if [ $? -eq 0 ]; then
            log_action "INFO" "Удалена группа: $group"
        else
            log_action "ERROR" "Ошибка при удалении группы: $group"
        fi
    else
        show_info "Операция отменена"
    fi
    pause
}

# --- Удаление ACL для топика ---
delete_acls_for_topic() {
    draw_module_logo "УДАЛЕНИЕ ACL ДЛЯ ТОПИКА" "❌ У Д А Л Е Н И Е  ACL" 10
    echo ""
    local topic
    topic=$(read_input "Введите имя топика, для которого удалить все ACL")
    [[ -z "$topic" ]] && { show_error "Имя топика не может быть пустым"; pause; return; }

    echo ""
    show_warning "Будут удалены все правила ACL для топика '$topic'."
    if confirm_action "Удалить ACL для топика '$topic'?"; then
        run_kafka_cmd "acls" "--remove --topic $topic"
        if [ $? -eq 0 ]; then
            log_action "INFO" "Удалены ACL для топика: $topic"
        else
            log_action "ERROR" "Ошибка при удалении ACL для топика: $topic"
        fi
    else
        show_info "Операция отменена"
    fi
    pause
}

# --- Удаление ACL для группы ---
delete_acls_for_group() {
    draw_module_logo "УДАЛЕНИЕ ACL ДЛЯ ГРУППЫ" "❌ У Д А Л Е Н И Е  ACL" 10
    echo ""
    local group
    group=$(read_input "Введите имя группы, для которой удалить все ACL")
    [[ -z "$group" ]] && { show_error "Имя группы не может быть пустым"; pause; return; }

    echo ""
    show_warning "Будут удалены все правила ACL для группы '$group'."
    if confirm_action "Удалить ACL для группы '$group'?"; then
        run_kafka_cmd "acls" "--remove --group $group"
        if [ $? -eq 0 ]; then
            log_action "INFO" "Удалены ACL для группы: $group"
        else
            log_action "ERROR" "Ошибка при удалении ACL для группы: $group"
        fi
    else
        show_info "Операция отменена"
    fi
    pause
}

# --- Главное меню удаления ---
main_delete() {
    local options=(
        "📁 Топик"
        "👥 Группа потребителей"
        "🔒 ACL для топика"
        "🔒 ACL для группы"
        "🔙 Назад в главное меню"
    )
    local selected=0

    while true; do
        draw_module_logo "УДАЛЕНИЕ"
        echo ""
        echo "   ${YELLOW}Используйте стрелки ↑ ↓ для навигации, Enter для выбора${RESET}"
        echo ""

        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -n "   ${REV}${GREEN} ▶ ${options[$i]} ${RESET}"
            else
                echo -n "     ${options[$i]}"
            fi
            echo ""
        done

        local key
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case "$key" in
                '[A') ((selected--)); [[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1)) ;;
                '[B') ((selected++)); [[ $selected -ge ${#options[@]} ]] && selected=0 ;;
            esac
        elif [[ $key == "" ]]; then
            case $selected in
                0) delete_topic ;;
                1) delete_consumer_group ;;
                2) delete_acls_for_topic ;;
                3) delete_acls_for_group ;;
                4) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_delete
fi