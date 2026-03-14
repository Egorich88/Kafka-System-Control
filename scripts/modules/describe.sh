#!/bin/bash

# Модуль описания Kafka (топики, группы, ACL, поиск)
# Версия 3.1 | Егор Хоменко (Egorich88)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

# ==================== Топики ====================

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

# ==================== Группы потребителей ====================

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

# ==================== ACL ====================

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

# ==================== Поиск сообщений ====================

search_by_offset() {
    draw_section_header "ПОИСК ПО ОФФСЕТУ" "📌 П О  О Ф Ф С Е Т У" 12
    echo ""

    topic=$(read_input "Введите название топика")
    [[ -z "$topic" ]] && { show_error "Название топика обязательно"; pause; return; }

    partition=$(read_input "Введите номер партиции (по умолчанию 0)" "0")
    offset=$(read_input "Введите оффсет")
    [[ -z "$offset" ]] && { show_error "Оффсет обязателен"; pause; return; }

    run_kafka_cmd "console-consumer" \
        "--topic $topic --partition $partition --offset $offset --max-messages 1 --property print.key=true"
    pause
}

search_by_key() {
    draw_section_header "ПОИСК ПО КЛЮЧУ" "🔑 П О  К Л Ю Ч У" 13
    echo ""

    topic=$(read_input "Введите название топика")
    [[ -z "$topic" ]] && { show_error "Название топика обязательно"; pause; return; }

    key=$(read_input "Введите ключ для поиска")
    [[ -z "$key" ]] && { show_error "Ключ обязателен"; pause; return; }

    # Путь к JAR-файлу (относительно корня проекта)
    JAR_PATH="${SCRIPT_DIR}/../../java/lib/kafka-search.jar"
    if [[ ! -f "$JAR_PATH" ]]; then
        show_error "Java-утилита не найдена. Сначала выполните сборку: cd java && mvn package"
        pause
        return
    fi

    show_info "Поиск сообщений с ключом '$key' в топике '$topic' (это может занять некоторое время)..."
    echo ""

    # Запускаем Java-программу
    java -jar "$JAR_PATH" "$BOOTSTRAP_SERVERS" "$topic" "$key"

    pause
}

search_message_menu() {
    while true; do
        draw_section_header "ПОИСК СООБЩЕНИЯ" "🔎 П О И С К  С О О Б Щ Е Н И Я" 11
        echo ""
        echo "1) 📌 По оффсету"
        echo "2) 🔑 По ключу"
        echo "3) 🔙 Назад в меню топиков"
        echo "4) 🔙 Назад в главное меню"
        echo "5) 🚪 Выход"
        echo ""
        read -p "$(print_prompt 'Выберите действие [1-5]') " choice

        case $choice in
            1) search_by_offset ;;
            2) search_by_key ;;
            3) return ;;
            4) describe_main_menu; break ;;
            5) clear; exit 0 ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

# ==================== Меню топиков ====================

topic_menu() {
    while true; do
        draw_header "ТОПИКИ" "Т О П И К И" 15
        echo ""
        echo "1) 🔍 Поиск топика"
        echo "2) ⚙️ Конфигурация топика"
        echo "3) 📋 Список топиков"
        echo "4) 🔎 Поиск сообщения"
        echo "5) 🔙 Назад"
        echo ""
        read -p "$(print_prompt 'Выберите действие [1-5]') " choice

        case $choice in
            1) describe_topic ;;
            2) describe_topic_config ;;
            3) describe_topics ;;
            4) search_message_menu ;;
            5) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

# ==================== Меню групп потребителей ====================

consumer_menu() {
    while true; do
        draw_header "ГРУППЫ" "Г Р У П П Ы" 15
        echo ""
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

# ==================== Меню ACL ====================

acl_menu() {
    while true; do
        draw_header "ACL" "С П И С К И  Д О С Т У П А" 12
        echo ""
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

# ==================== Главное меню описания ====================

describe_main_menu() {
    while true; do
        draw_header "ОПИСАНИЕ" "О П И С А Н И Е" 15
        echo ""
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

# Запуск, если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    describe_main_menu
fi