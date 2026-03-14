#!/bin/bash

# Модуль создания ресурсов Kafka (топики, группы, ACL)
# Версия 3.1 | Егор Хоменко (Egorich88)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

tput civis
trap 'tput cnorm' EXIT INT TERM

# --- Создание топика ---
create_topic() {
    draw_module_logo "СОЗДАНИЕ ТОПИКА"   # <-- используем единый логотип
    echo ""

    local topic partitions replication configs

    topic=$(read_input "Введите имя топика")
    [[ -z "$topic" ]] && { show_error "Имя топика не может быть пустым"; pause; return; }

    partitions=$(read_input "Количество партиций" "1")
    replication=$(read_input "Фактор репликации" "1")

    # Проверка, что фактор репликации не больше числа брокеров
    if [[ "$replication" -gt 1 ]]; then
        show_warning "У вас только один брокер, фактор репликации будет принудительно установлен в 1"
        replication=1
    fi

    # Дополнительные конфигурации (опционально)
    echo ""
    show_info "Вы можете указать дополнительные конфигурации в формате key=value (например, retention.ms=604800000)"
    show_info "Для пропуска оставьте пустым"
    extra_configs=$(read_input "Дополнительные конфигурации (через запятую)")

    # Формируем команду
    local cmd_params="--create --topic $topic --partitions $partitions --replication-factor $replication"
    if [[ -n "$extra_configs" ]]; then
        IFS=',' read -ra configs_array <<< "$extra_configs"
        for config in "${configs_array[@]}"; do
            cmd_params="$cmd_params --config $config"
        done
    fi

    echo ""
    if confirm_action "Создать топик '$topic' с параметрами: партиций=$partitions, репликация=$replication?"; then
        run_kafka_cmd "topics" "$cmd_params"
        log_action "INFO" "Создан топик: $topic (партиций=$partitions, репликация=$replication, конфиги=$extra_configs)"
    else
        show_info "Операция отменена"
    fi
    pause
}

# --- Создание группы потребителей (информация) ---
create_consumer_group() {
    draw_module_logo "СОЗДАНИЕ ГРУППЫ"
    echo ""
    show_warning "Группы потребителей обычно создаются автоматически..."
    show_info "Если вам нужно создать группу с определёнными параметрами, используйте:"
    show_info "kafka-consumer-groups.sh --bootstrap-server ... --group ... --reset-offsets ..."
    echo ""
    show_info "Данная функция пока не реализована."
    pause
}

# --- Создание ACL ---
create_acl() {
    draw_module_logo "СОЗДАНИЕ ACL"
    echo ""

    local perm_type
    echo "1) Allow"
    echo "2) Deny"
    read -p "$(print_prompt 'Выберите тип разрешения [1]: ')" perm_choice
    case "$perm_choice" in
        2) perm_type="deny" ;;
        *) perm_type="allow" ;;
    esac

    local principal
    principal=$(read_input "Principal (формат: User:имя, например User:alice)")
    [[ -z "$principal" ]] && { show_error "Principal не может быть пустым"; pause; return; }
    if [[ "$principal" != *:* ]]; then
        principal="User:$principal"
        show_info "Добавлен префикс User: -> $principal"
    fi

    local host
    host=$(read_input "Хост (по умолчанию *, можно указать IP)" "*")

    local resource_type
    echo ""
    echo "Типы ресурсов:"
    echo "1) Topic"
    echo "2) Group"
    echo "3) Cluster"
    echo "4) TransactionalId"
    echo "5) DelegationToken"
    read -p "$(print_prompt 'Выберите тип ресурса [1]: ')" res_choice
    case "$res_choice" in
        2) resource_type="group" ;;
        3) resource_type="cluster" ;;
        4) resource_type="transactional-id" ;;
        5) resource_type="delegation-token" ;;
        *) resource_type="topic" ;;
    esac

    local resource_name=""
    if [[ "$resource_type" != "cluster" ]]; then
        resource_name=$(read_input "Имя ресурса")
        [[ -z "$resource_name" ]] && { show_error "Имя ресурса не может быть пустым"; pause; return; }
    fi

    echo ""
    show_info "Доступные операции: Read, Write, Create, Delete, Alter, Describe, ClusterAction, All"
    local operations
    operations=$(read_input "Операции (через запятую)" "All")

    local cmd_params="--add"
    if [[ "$perm_type" == "allow" ]]; then
        cmd_params="$cmd_params --allow-principal $principal"
        [[ -n "$host" && "$host" != "*" ]] && cmd_params="$cmd_params --allow-host $host"
    else
        cmd_params="$cmd_params --deny-principal $principal"
        [[ -n "$host" && "$host" != "*" ]] && cmd_params="$cmd_params --deny-host $host"
    fi

    IFS=',' read -ra ops_array <<< "$operations"
    for op in "${ops_array[@]}"; do
        op=$(echo "$op" | xargs)
        cmd_params="$cmd_params --operation $op"
    done

    case "$resource_type" in
        "topic")           cmd_params="$cmd_params --topic $resource_name" ;;
        "group")           cmd_params="$cmd_params --group $resource_name" ;;
        "cluster")         cmd_params="$cmd_params --cluster" ;;
        "transactional-id") cmd_params="$cmd_params --transactional-id $resource_name" ;;
        "delegation-token") cmd_params="$cmd_params --delegation-token $resource_name" ;;
    esac

    echo ""
    if confirm_action "Создать ACL: $perm_type для $principal на $resource_type ${resource_name:+=$resource_name}?"; then
        run_kafka_cmd "acls" "$cmd_params"
        log_action "INFO" "Создан ACL: $perm_type $principal на $resource_type $resource_name, операции: $operations"
    else
        show_info "Операция отменена"
    fi
    pause
}

# --- Главное меню создания ---
main_create() {
    local options=(
        "📁 Топик"
        "👥 Группа потребителей"
        "🔒 ACL (правила доступа)"
        "🔙 Назад в главное меню"
    )
    local selected=0

    while true; do
        draw_module_logo "СОЗДАНИЕ"
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
                0) create_topic ;;
                1) create_consumer_group ;;
                2) create_acl ;;
                3) return ;;
            esac
        elif [[ $key == "q" || $key == "Q" ]]; then
            exit 0
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_create
fi