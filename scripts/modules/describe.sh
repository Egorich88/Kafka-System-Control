#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

describe_topics() {
    run_kafka_cmd "topics" "--list"
    pause
}

describe_topic() {
    local topic
    topic=$(read_input "Введите название топика")
    [[ -z "$topic" ]] && { show_error "Название не может быть пустым"; pause; return; }
    run_kafka_cmd "topics" "--describe --topic $topic"
    pause
}

describe_topic_config() {
    local topic
    topic=$(read_input "Введите название топика")
    [[ -z "$topic" ]] && { show_error "Название не может быть пустым"; pause; return; }
    run_kafka_cmd "configs" "--entity-type topics --entity-name $topic --describe --all" "| column -t"
    pause
}

list_consumer_groups() {
    run_kafka_cmd "consumer-groups" "--list"
    pause
}

describe_group() {
    local group
    group=$(read_input "Введите имя группы")
    [[ -z "$group" ]] && { show_error "Имя группы не может быть пустым"; pause; return; }
    run_kafka_cmd "consumer-groups" "--describe --group $group"
    pause
}

describe_all_groups() {
    run_kafka_cmd "consumer-groups" "--describe --all-groups"
    pause
}

list_acls() {
    run_kafka_cmd "acls" "--list"
    pause
}

list_acls_for_topic() {
    local topic
    topic=$(read_input "Введите название топика")
    [[ -z "$topic" ]] && { show_error "Название не может быть пустым"; pause; return; }
    run_kafka_cmd "acls" "--list --topic $topic"
    pause
}

topic_menu() {
    while true; do
        draw_header "ТОПИКИ" "Т О П И К И" 15
        echo "1) 🔍 Поиск топика"
        echo "2) ⚙️ Конфигурация топика"
        echo "3) 📋 Список топиков"
        echo "4) 🔙 Назад"
        echo ""
        read -p "$(print_prompt 'Выберите действие [1-4]') " choice
        case $choice in
            1) describe_topic ;;
            2) describe_topic_config ;;
            3) describe_topics ;;
            4) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

consumer_menu() {
    while true; do
        draw_header "ГРУППЫ" "Г Р У П П Ы" 15
        echo "1) 🔍 Поиск группы"
        echo "2) 📋 Список всех групп"
        echo "3) 📊 Состояние всех групп"
        echo "4) 🔙 Назад"
        echo ""
        read -p "$(print_prompt 'Выберите действие [1-4]') " choice
        case $choice in
            1) describe_group ;;
            2) list_consumer_groups ;;
            3) describe_all_groups ;;
            4) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

acl_menu() {
    while true; do
        draw_header "ACL" "С П И С К И  Д О С Т У П А" 12
        echo "1) 🔍 Права на топик"
        echo "2) 📋 Полный список ACL"
        echo "3) 🔙 Назад"
        echo ""
        read -p "$(print_prompt 'Выберите действие [1-3]') " choice
        case $choice in
            1) list_acls_for_topic ;;
            2) list_acls ;;
            3) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

main_describe() {
    while true; do
        draw_header "ОПИСАНИЕ" "О П И С А Н И Е" 15
        echo "1) 📋 Топики"
        echo "2) 👥 Группы потребителей"
        echo "3) 🔐 ACL"
        echo "4) 🔙 Назад в главное меню"
        echo ""
        read -p "$(print_prompt 'Выберите раздел [1-4]') " choice
        case $choice in
            1) topic_menu ;;
            2) consumer_menu ;;
            3) acl_menu ;;
            4) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

main_describe

