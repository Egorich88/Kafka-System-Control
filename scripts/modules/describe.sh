#!/bin/bash

# Модуль описания Kafka (топики, группы, ACL, поиск)
# Версия 3.1 | Егор Хоменко (Egorich88)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

# Отключаем курсор (будет включён при выходе)
tput civis
trap 'tput cnorm' EXIT INT TERM

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

# ==================== Управление оффсетами ====================

# Сброс оффсетов для группы (основная функция)
reset_offsets() {
    draw_module_logo "СБРОС ОФФСЕТОВ"
    echo ""

    local group
    group=$(read_input "Введите имя группы потребителей")
    [[ -z "$group" ]] && { show_error "Имя группы не может быть пустым"; pause; return; }

    # Получаем список топиков, на которые подписана группа
    show_info "Получение списка топиков для группы $group..."
    local topics_output
    topics_output=$(run_kafka_cmd "consumer-groups" "--describe --group $group" 2>&1)
    if [[ $? -ne 0 ]]; then
        show_error "Не удалось получить информацию о группе. Возможно, группа не существует."
        pause
        return
    fi

    # Парсим вывод, чтобы получить уникальные топики (упрощённо)
    local topics=($(echo "$topics_output" | awk 'NR>2 {print $2}' | sort -u))
    if [[ ${#topics[@]} -eq 0 ]]; then
        show_error "Группа $group не имеет активных топиков или не найдена."
        pause
        return
    fi

    # Предлагаем выбрать топик
    echo ""
    echo "Доступные топики для группы $group:"
    for i in "${!topics[@]}"; do
        echo "$((i+1))) ${topics[$i]}"
    done
    echo "$((${#topics[@]}+1))) Все топики группы"
    echo ""
    local topic_choice
    read -p "$(print_prompt 'Выберите топик [1-'${#topics[@]}'] или Enter для всех: ')" topic_choice

    local selected_topics=()
    if [[ -z "$topic_choice" || "$topic_choice" -eq $((${#topics[@]}+1)) ]]; then
        selected_topics=("${topics[@]}")
    else
        local idx=$((topic_choice-1))
        if [[ $idx -ge 0 && $idx -lt ${#topics[@]} ]]; then
            selected_topics=("${topics[$idx]}")
        else
            show_error "Неверный выбор"
            pause
            return
        fi
    fi

    # Выбор типа сброса
    echo ""
    echo "Типы сброса:"
    echo "1) На самое начало (--to-earliest)"
    echo "2) В самый конец (--to-latest)"
    echo "3) Сдвиг на N сообщений (--shift-by)"
    echo "4) На конкретную дату/время (--to-datetime)"
    echo "5) На конкретный оффсет (--to-offset) [требуется партиция]"
    echo ""
    local reset_type
    read -p "$(print_prompt 'Выберите тип сброса [1-5]') " reset_type

    local reset_option=""
    local extra_params=""

    case $reset_type in
        1) reset_option="--to-earliest" ;;
        2) reset_option="--to-latest" ;;
        3)
            local shift
            shift=$(read_input "Введите сдвиг (положительное или отрицательное число)")
            [[ -z "$shift" ]] && { show_error "Сдвиг не может быть пустым"; pause; return; }
            reset_option="--shift-by $shift"
            ;;
        4)
            local datetime
            datetime=$(read_input "Введите дату/время в формате YYYY-MM-DDTHH:MM:SS.sss (например, 2026-01-01T12:00:00.000)")
            [[ -z "$datetime" ]] && { show_error "Дата не может быть пустой"; pause; return; }
            reset_option="--to-datetime $datetime"
            ;;
        5)
            local partition offset
            partition=$(read_input "Введите номер партиции")
            offset=$(read_input "Введите оффсет")
            [[ -z "$partition" || -z "$offset" ]] && { show_error "Партиция и оффсет обязательны"; pause; return; }
            reset_option="--to-offset $offset"
            extra_params="--topic ${selected_topics[0]} --partition $partition"  # для одного топика и партиции
            ;;
        *)
            show_error "Неверный выбор"
            pause
            return
            ;;
    esac

    # Формируем общие параметры для команд
    local common_params="--group $group"
    for topic in "${selected_topics[@]}"; do
        common_params="$common_params --topic $topic"
    done

    echo ""
    show_warning "Перед выполнением сброса будет показан результат пробного запуска (--dry-run)."
    if ! confirm_action "Показать предварительный результат?"; then
        show_info "Операция отменена"
        pause
        return
    fi

    # Пробный запуск
    show_info "Пробный запуск (--dry-run):"
    run_kafka_cmd "consumer-groups" "--reset-offsets $reset_option $common_params $extra_params --dry-run"

    echo ""
    if confirm_action "Выполнить сброс оффсетов для выбранных топиков?"; then
        run_kafka_cmd "consumer-groups" "--reset-offsets $reset_option $common_params $extra_params --execute"
        log_action "INFO" "Выполнен сброс оффсетов для группы $group, тип $reset_option"
    else
        show_info "Операция отменена"
    fi
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

    JAR_PATH="${SCRIPT_DIR}/../../java/lib/kafka-search.jar"
    if [[ ! -f "$JAR_PATH" ]]; then
        show_error "Java-утилита не найдена. Сначала выполните сборку: cd java && mvn package"
        pause
        return
    fi

    show_info "Поиск сообщений с ключом '$key' в топике '$topic' (это может занять некоторое время)..."
    echo ""
    java -jar "$JAR_PATH" "$BOOTSTRAP_SERVERS" "$topic" "$key"
    pause
}

# ==================== Меню поиска ====================
search_message_menu() {
    local options=(
        "📌 По оффсету"
        "🔑 По ключу"
        "🔙 Назад в меню топиков"
    )
    local selected=0

    while true; do
        draw_module_logo "ПОИСК СООБЩЕНИЙ"   # ← заменили draw_section_header
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
                0) search_by_offset ;;
                1) search_by_key ;;
                2) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

# ==================== Меню топиков ====================
topic_menu() {
    local options=(
        "🔍 Поиск топика"
        "⚙️ Конфигурация топика"
        "📋 Список топиков"
        "🔎 Поиск сообщения"
        "🔙 Назад"
    )
    local selected=0

    while true; do
        draw_module_logo "ТОПИКИ"           # ← заменили draw_header
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
                0) describe_topic ;;
                1) describe_topic_config ;;
                2) describe_topics ;;
                3) search_message_menu ;;
                4) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

# ==================== Меню групп ====================
consumer_menu() {
    local options=(
        "🔍 Поиск группы"
        "📋 Список всех групп"
        "📊 Состояние всех групп"
        "🔄 Управление оффсетами (сброс)"   # новый пункт
        "🔙 Назад"
    )
    local selected=0

    while true; do
        draw_module_logo "ГРУППЫ"
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
                0) describe_group ;;
                1) list_consumer_groups ;;
                2) describe_all_groups ;;
                3) reset_offsets ;;          # вызов новой функции
                4) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

# ==================== Меню ACL ====================
acl_menu() {
    local options=(
        "🔍 Права на топик"
        "📋 Полный список ACL"
        "🔙 Назад"
    )
    local selected=0

    while true; do
        draw_module_logo "ACL"               # ← заменили draw_header
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
                0) list_acls_for_topic ;;
                1) list_acls ;;
                2) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

# ==================== Главное меню описания ====================
describe_main_menu() {
    local options=(
        "📋 Топики"
        "👥 Группы потребителей"
        "🔐 ACL"
        "🔙 Назад в главное меню"
    )
    local selected=0

    while true; do
        draw_module_logo "ОПИСАНИЕ"   # <-- здесь используем новый логотип
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
                0) topic_menu ;;
                1) consumer_menu ;;
                2) acl_menu ;;
                3) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

# Запуск, если скрипт вызван напрямую (не из main_menu)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    describe_main_menu
fi