# Deployment Options with Docker Compose

This repository demonstrates different deployment strategies that can be achieved using Docker Compose.

The purpose of these deployment methods varies, but the most important aspects are stability and zero downtime. Achieving these goals with Docker Compose can be quite challenging.

## 1. Rolling Deployment

To implement this deployment method, we need the following plugin: [docker-ztd](https://github.com/ku9nov/docker-compose-ztd-plugin). You can install it using the following command:

```sh
curl -fsSL https://raw.githubusercontent.com/ku9nov/docker-compose-ztd-plugin/main/scripts/install-docker-ztd-go.sh | bash
```

After a successful installation, you can start the example deployment using:

```sh
docker ztd -f docker-compose.yaml up -d
```

For the first 10 seconds, traffic will not be routed to the backend due to the configured health check. This is useful for testing purposes.

Once the applications are up and running, you can verify them using the following commands:

```sh
curl -H "Host:backend.example.com" http://127.0.0.1:8000/
Hello, instance: db0fb18accab, started at: 2025-03-19T09:33:32Z
```

```sh
curl -H "Host:frontend.example.com" http://127.0.0.1:8000/
```

To trigger an update, use the following command:

```sh
docker ztd -f docker-compose.yaml helloworld
```

Curl request for checking zero-time-deployment:

```bash
while true; do curl -H "Host:backend.example.com" http://127.0.0.1:8000; echo -e "\n" ; done
```

Curl request for checking blue-green deployment:

```bash
curl -i -H "Host:backend.example.com" -H "X-Env:green" http://127.0.0.1:8000
```

Curl request for checking canary deployment:

```bash
for i in {1..200}; do
  curl -s -H "Host:backend.example.com" http://127.0.0.1:8000
done | grep -o 'instance: [^,]*' | sort | uniq -c
```