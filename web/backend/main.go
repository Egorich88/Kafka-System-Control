package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

type TopicsResponse struct {
	Topics []string `json:"topics"`
	Error  string   `json:"error,omitempty"`
}

type CreateTopicRequest struct {
	Topic       string `json:"topic"`
	Partitions  string `json:"partitions"`
	Replication string `json:"replication"`
	Configs     string `json:"configs,omitempty"` // например, "retention.ms=604800000,cleanup.policy=compact"
}

type CreateTopicResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error,omitempty"`
}

// Получение списка топиков
func getTopicsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	bootstrapServer := getBootstrapServer()

	cmdPath, err := exec.LookPath("kafka-topics.sh")
	if err != nil {
		sendError(w, "kafka-topics.sh not found in PATH")
		return
	}
	log.Printf("Используем kafka-topics.sh: %s", cmdPath)

	cmd := exec.Command(cmdPath, "--bootstrap-server", bootstrapServer, "--list")
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Ошибка выполнения команды: %v, вывод: %s", err, string(output))
		sendError(w, string(output))
		return
	}

	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	var topics []string
	for _, line := range lines {
		if line != "" {
			topics = append(topics, line)
		}
	}
	if topics == nil {
		topics = make([]string, 0)
	}
	json.NewEncoder(w).Encode(TopicsResponse{Topics: topics})
}

// Создание топика
func createTopicHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		// Preflight CORS
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		sendError(w, "Invalid request body")
		return
	}

	var req CreateTopicRequest
	if err := json.Unmarshal(body, &req); err != nil {
		sendError(w, "Invalid JSON")
		return
	}

	if req.Topic == "" {
		sendError(w, "Topic name is required")
		return
	}

	// Параметры по умолчанию
	partitions := "1"
	replication := "1"
	if req.Partitions != "" {
		partitions = req.Partitions
	}
	if req.Replication != "" {
		replication = req.Replication
	}

	bootstrapServer := getBootstrapServer()

	cmdPath, err := exec.LookPath("kafka-topics.sh")
	if err != nil {
		sendError(w, "kafka-topics.sh not found in PATH")
		return
	}

	// Базовые аргументы
	args := []string{
		"--bootstrap-server", bootstrapServer,
		"--create",
		"--topic", req.Topic,
		"--partitions", partitions,
		"--replication-factor", replication,
	}

	// Добавляем дополнительные конфигурации, если есть
	if req.Configs != "" {
		// Разделяем по запятой и добавляем каждый как --config
		configs := strings.Split(req.Configs, ",")
		for _, cfg := range configs {
			cfg = strings.TrimSpace(cfg)
			if cfg != "" {
				args = append(args, "--config", cfg)
			}
		}
	}

	log.Printf("Выполняется: %s %v", cmdPath, args)
	cmd := exec.Command(cmdPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Ошибка создания топика: %v, вывод: %s", err, string(output))
		sendError(w, string(output))
		return
	}

	json.NewEncoder(w).Encode(CreateTopicResponse{Success: true})
}

// Вспомогательная функция для получения bootstrap сервера
func getBootstrapServer() string {
	if env := os.Getenv("KAFKA_BOOTSTRAP_SERVERS"); env != "" {
		return env
	}
	return "localhost:9092"
}

// Отправка ошибки в JSON
func sendError(w http.ResponseWriter, msg string) {
	w.WriteHeader(http.StatusInternalServerError)
	json.NewEncoder(w).Encode(CreateTopicResponse{Success: false, Error: msg})
}

func main() {
	http.HandleFunc("/api/topics", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			getTopicsHandler(w, r)
		} else if r.Method == http.MethodPost {
			createTopicHandler(w, r)
		} else {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	port := ":8080"
	log.Printf("Сервер запущен на порту %s", port)
	log.Fatal(http.ListenAndServe(port, nil))
}