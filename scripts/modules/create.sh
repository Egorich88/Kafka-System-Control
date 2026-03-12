#!/bin/bash

# Модуль создания ресурсов Kafka (топики, группы, ACL)
# Версия 3.0 | Егор Хоменко

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/config.sh"
source "${SCRIPT_DIR}/../lib/ui.sh"
source "${SCRIPT_DIR}/../lib/kafka_commands.sh"
source "${SCRIPT_DIR}/../lib/utils.sh"

# --- Создание топика ---
create_topic() {
    draw_header "СОЗДАНИЕ ТОПИКА" "➕ Н О В Ы Й  Т О П И К" 10
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
    draw_header "СОЗДАНИЕ ГРУППЫ" "➕ Н О В А Я  Г Р У П П А" 10
    echo ""
    show_warning "Группы потребителей обычно создаются автоматически при первом подключении."
    show_info "Если вам нужно создать группу с определёнными параметрами, используйте:"
    show_info "kafka-consumer-groups.sh --bootstrap-server ... --group ... --reset-offsets ..."
    echo ""
    show_info "Данная функция пока не реализована."
    pause
}

# --- Создание ACL ---
create_acl() {
    draw_header "СОЗДАНИЕ ACL" "➕ Н О В О Е  П Р А В И Л О" 10
    echo ""
    
    # Тип разрешения
    local perm_type
    echo "1) Allow"
    echo "2) Deny"
    read -p "$(print_prompt 'Выберите тип разрешения [1]: ')" perm_choice
    case "$perm_choice" in
        2) perm_type="deny" ;;
        *) perm_type="allow" ;;
    esac
    
    # Principal
    local principal
    principal=$(read_input "Principal (формат: User:имя, например User:alice)")
    [[ -z "$principal" ]] && { show_error "Principal не может быть пустым"; pause; return; }
    # Если нет двоеточия, добавляем "User:"
    if [[ "$principal" != *:* ]]; then
        principal="User:$principal"
        show_info "Добавлен префикс User: -> $principal"
    fi
    
    # Хост
    local host
    host=$(read_input "Хост (по умолчанию *, можно указать IP)" "*")
    
    # Тип ресурса
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
    
    # Имя ресурса (если не cluster)
    local resource_name=""
    if [[ "$resource_type" != "cluster" ]]; then
        resource_name=$(read_input "Имя ресурса")
        [[ -z "$resource_name" ]] && { show_error "Имя ресурса не может быть пустым"; pause; return; }
    fi
    
    # Операции
    echo ""
    show_info "Доступные операции: Read, Write, Create, Delete, Alter, Describe, ClusterAction, All"
    local operations
    operations=$(read_input "Операции (через запятую)" "All")
    
    # Собираем команду
    local cmd_params="--add"
    if [[ "$perm_type" == "allow" ]]; then
        cmd_params="$cmd_params --allow-principal $principal"
        [[ -n "$host" && "$host" != "*" ]] && cmd_params="$cmd_params --allow-host $host"
    else
        cmd_params="$cmd_params --deny-principal $principal"
        [[ -n "$host" && "$host" != "*" ]] && cmd_params="$cmd_params --deny-host $host"
    fi
    
    # Добавляем операции
    IFS=',' read -ra ops_array <<< "$operations"
    for op in "${ops_array[@]}"; do
        # Убираем пробелы
        op=$(echo "$op" | xargs)
        cmd_params="$cmd_params --operation $op"
    done
    
    # Добавляем ресурс
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
    while true; do
        draw_header "СОЗДАНИЕ" "➕ С О З Д А Н И Е" 14
        echo "1) 📁 Топик"
        echo "2) 👥 Группа потребителей"
        echo "3) 🔒 ACL (правила доступа)"
        echo "4) 🔙 Назад в главное меню"
        echo ""
        read -p "$(print_prompt 'Выберите тип ресурса [1-4]') " choice
        
        case $choice in
            1) create_topic ;;
            2) create_consumer_group ;;
            3) create_acl ;;
            4) return ;;
            *) echo "$(print_error 'Неверный выбор')"; sleep 1 ;;
        esac
    done
}

# Запуск, если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_create
fi
