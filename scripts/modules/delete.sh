#!/bin/bash

# Модуль удаления ресурсов Kafka (топики, группы, ACL)
# Версия 3.0 | Егор Хоменко (Egorich88)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

# --- Удаление топика ---
delete_topic() {
    draw_header "УДАЛЕНИЕ ТОПИКА" "❌ У Д А Л Е Н И Е  Т О П И К А" 10
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
    draw_header "УДАЛЕНИЕ ГРУППЫ" "❌ У Д А Л Е Н И Е  Г Р У П П Ы" 10
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
    draw_header "УДАЛЕНИЕ ACL ДЛЯ ТОПИКА" "❌ У Д А Л Е Н И Е  ACL" 10
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
    draw_header "УДАЛЕНИЕ ACL ДЛЯ ГРУППЫ" "❌ У Д А Л Е Н И Е  ACL" 10
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
    while true; do
        draw_header "УДАЛЕНИЕ" "❌ У Д А Л Е Н И Е" 14
        echo "1) 📁 Топик"
        echo "2) 👥 Группа потребителей"
        echo "3) 🔒 ACL для топика"
        echo "4) 🔒 ACL для группы"
        echo "5) 🔙 Назад в главное меню"
        echo ""
        read -p "$(print_prompt 'Выберите тип ресурса [1-5]') " choice

        case $choice in
            1) delete_topic ;;
            2) delete_consumer_group ;;
            3) delete_acls_for_topic ;;
            4) delete_acls_for_group ;;
            5) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

# Запуск, если скрипт вызван напрямую (не из main_menu)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_delete
fi