#!/bin/bash
export VERSION="3.0"
export ENV_NAME="WSL-DEV"
# Путь к Kafka внутри WSL (абсолютный!)
export KAFKA_HOME="/home/prorok/kafka"
export BOOTSTRAP_SERVERS="localhost:9092"
export CONFIG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/config/client.properties"
