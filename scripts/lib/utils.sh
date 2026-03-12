#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

log_action() {
    local level="$1"
    local message="$2"
    local log_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/logs/kafka_operations.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] - $message" >> "$log_file"
}

