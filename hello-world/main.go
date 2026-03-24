package main

import (
	"fmt"
	"math/rand"
	"net"
	"net/http"
	"os"
	"strconv"
	"time"
)

var startTime time.Time
var statusDistribution responseDistribution
var rng = rand.New(rand.NewSource(time.Now().UnixNano()))

type responseDistribution struct {
	return200 int
	return400 int
	return500 int
	total     int
}

func loadResponseDistribution() responseDistribution {
	dist := responseDistribution{
		return200: readEnvInt("RETURN_200", 100),
		return400: readEnvInt("RETURN_400", 0),
		return500: readEnvInt("RETURN_500", 0),
	}

	if dist.return200 < 0 {
		dist.return200 = 0
	}
	if dist.return400 < 0 {
		dist.return400 = 0
	}
	if dist.return500 < 0 {
		dist.return500 = 0
	}

	dist.total = dist.return200 + dist.return400 + dist.return500
	if dist.total == 0 {
		dist.return200 = 100
		dist.total = 100
	}

	return dist
}

func readEnvInt(key string, defaultValue int) int {
	raw := os.Getenv(key)
	if raw == "" {
		return defaultValue
	}

	parsed, err := strconv.Atoi(raw)
	if err != nil {
		return defaultValue
	}

	return parsed
}

func pickStatusCode() int {
	r := rng.Intn(statusDistribution.total)

	if r < statusDistribution.return500 {
		return http.StatusInternalServerError
	}
	r -= statusDistribution.return500

	if r < statusDistribution.return400 {
		return http.StatusBadRequest
	}

	return http.StatusOK
}

func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "unknown"
	}

	return hostname
}

func handler(w http.ResponseWriter, r *http.Request) {
	hostname := getHostname()

	statusCode := pickStatusCode()
	w.WriteHeader(statusCode)
	fmt.Fprintf(
		w,
		"Hello, instance: %s, started at: %s, status: %d",
		hostname,
		startTime.Format(time.RFC3339),
		statusCode,
	)
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

func handleTCPConnection(conn net.Conn, port string) {
	defer conn.Close()

	response := fmt.Sprintf(
		"Hello TCP, instance: %s, port: %s, time: %s\n",
		getHostname(),
		port,
		time.Now().Format(time.RFC3339),
	)

	if _, err := conn.Write([]byte(response)); err != nil {
		fmt.Printf("TCP write error on port %s: %v\n", port, err)
	}
}

func startTCPListener(port string) {
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		fmt.Printf("Failed to start TCP listener on port %s: %v\n", port, err)
		return
	}

	fmt.Printf("TCP listener is running on port %s\n", port)

	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Printf("TCP accept error on port %s: %v\n", port, err)
			continue
		}

		go handleTCPConnection(conn, port)
	}
}

func main() {
	startTime = time.Now()
	statusDistribution = loadResponseDistribution()

	fmt.Printf(
		"Response distribution for '/': 200=%d 400=%d 500=%d (total=%d)\n",
		statusDistribution.return200,
		statusDistribution.return400,
		statusDistribution.return500,
		statusDistribution.total,
	)

	http.HandleFunc("/", handler)
	http.HandleFunc("/health", healthHandler)

	go startTCPListener("5222")
	go startTCPListener("5223")

	port := "8000"
	fmt.Println("Server is running on port", port)
	http.ListenAndServe(":"+port, nil)
}
