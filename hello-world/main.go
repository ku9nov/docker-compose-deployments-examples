package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

var startTime time.Time

func handler(w http.ResponseWriter, r *http.Request) {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	fmt.Fprintf(w, "Hello, instance: %s, started at: %s", hostname, startTime.Format(time.RFC3339))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	uptime := time.Since(startTime)

	if uptime < 10*time.Second {
		http.Error(w, "Unhealthy: uptime exceeded threshold", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "OK")
}

func main() {
	startTime = time.Now()
	http.HandleFunc("/", handler)
	http.HandleFunc("/health", healthHandler)

	port := "8000"
	fmt.Println("Server is running on port", port)
	http.ListenAndServe(":"+port, nil)
}
