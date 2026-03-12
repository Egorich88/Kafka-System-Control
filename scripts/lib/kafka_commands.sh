#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

run_kafka_cmd() {
    local cmd="$1"
    local params="$2"
    local extra_params="${3:-}"
    
    local script_name=""
    case "$cmd" in
        "topics")           script_name="kafka-topics.sh" ;;
        "configs")          script_name="kafka-configs.sh" ;;
        "consumer-groups")  script_name="kafka-consumer-groups.sh" ;;
        "acls")             script_name="kafka-acls.sh" ;;
        "console-consumer") script_name="kafka-console-consumer.sh" ;;
        *)                  show_error "Неизвестная команда: $cmd"; return 1 ;;
    esac
    
    # Пытаемся найти команду: сначала в KAFKA_HOME/bin, затем в PATH
    if [[ -n "$KAFKA_HOME" && -x "${KAFKA_HOME}/bin/${script_name}" ]]; then
        local full_cmd="${KAFKA_HOME}/bin/${script_name}"
    elif command -v "$script_name" &>/dev/null; then
        local full_cmd="$script_name"
    else
        show_error "Не найдены бинарники Kafka. Убедитесь, что KAFKA_HOME задан или команды в PATH."
        return 1
    fi
    
    show_info "Выполняется: $script_name $params"
    echo ""
    
    # Базовые аргументы
    local common_args="--bootstrap-server $BOOTSTRAP_SERVERS"
    [[ -f "$CONFIG_FILE" ]] && common_args="$common_args --command-config $CONFIG_FILE"
    
    # Запуск
    $full_cmd $common_args $params $extra_params
    
    local exit_code=$?
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        show_success "Готово!"
    else
        show_error "Команда завершилась с ошибкой (код $exit_code)"
    fi
    return $exit_code
}

