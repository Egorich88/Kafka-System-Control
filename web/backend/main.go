package main

import (
	"encoding/json"
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

func getTopicsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	bootstrapServer := "localhost:9092"
	if env := os.Getenv("KAFKA_BOOTSTRAP_SERVERS"); env != "" {
		bootstrapServer = env
	}

	cmdPath, err := exec.LookPath("kafka-topics.sh")
	if err != nil {
		log.Printf("Команда kafka-topics.sh не найдена в PATH: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TopicsResponse{Error: "kafka-topics.sh not found in PATH"})
		return
	}
	log.Printf("Используем kafka-topics.sh: %s", cmdPath)

	cmd := exec.Command(cmdPath, "--bootstrap-server", bootstrapServer, "--list")
	output, err := cmd.CombinedOutput() // <-- используем CombinedOutput
	if err != nil {
		log.Printf("Ошибка выполнения команды: %v, вывод: %s", err, string(output))
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TopicsResponse{Error: string(output)})
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

func main() {
	http.HandleFunc("/api/topics", getTopicsHandler)
	port := ":8080"
	log.Printf("Сервер запущен на порту %s", port)
	log.Fatal(http.ListenAndServe(port, nil))
}