# Этап сборки Go-приложения
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o kafka-control-backend main.go

# Финальный образ
FROM alpine:latest

# Устанавливаем bash (и, на будущее, openjdk11 для Java-утилиты)
RUN apk add --no-cache bash openjdk11

# Копируем скомпилированный Go-бинарник
COPY --from=builder /app/kafka-control-backend /usr/local/bin/

# Папка для монтирования бинарников Kafka (путь должен совпадать с тем, что вы монтируете)
# Здесь не копируем Kafka, оставляем монтирование с хоста.

EXPOSE 8080
CMD ["kafka-control-backend"]