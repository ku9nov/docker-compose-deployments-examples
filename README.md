# Deployment Options with Docker Compose

This repository demonstrates different deployment strategies that can be achieved using Docker Compose.

The purpose of these deployment methods varies, but the most important aspects are stability and zero downtime. Achieving these goals with Docker Compose can be quite challenging.

## 1. Rolling Deployment

To implement this deployment method, we need the following plugin: [docker-rollout](https://github.com/wowu/docker-rollout). You can install it using the following command:

```sh
curl -fsSL https://gist.githubusercontent.com/ku9nov/b2d5df6ebcc70921946ee76885e41f2f/raw/98dfbffe7af40d2da130f0c39e989cfca8b4f44e/install-docker-rollout.sh | bash
```

After a successful installation, you can start the example deployment using:

```sh
docker compose -f docker-compose.rolling.yaml up -d
```

For the first 10 seconds, traffic will not be routed to the backend due to the configured health check. This is useful for testing purposes.

Once the applications are up and running, you can verify them using the following commands:

```sh
curl -H "Host:backend.docker.localhost" http://127.0.0.1:8000/
Hello, instance: db0fb18accab, started at: 2025-03-19T09:33:32Z
```

```sh
curl -H "Host:frontend.docker.localhost" http://127.0.0.1:8000/
<!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" href="/favicon.ico"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/logo192.png"/><link rel="manifest" href="/manifest.json"/><title>React App</title><script defer="defer" src="/static/js/main.f9dc6ac2.js"></script><link href="/static/css/main.f855e6bc.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
```

To trigger an update, use the following command:

```sh
docker rollout -f docker-compose.rolling.yaml helloworld
```

Please note that at least one request may experience a timeout due to [Traefik](https://github.com/traefik/traefik) not disconnecting from the previous container in time. As a result, there may still be a few seconds of downtime. This behavior has also been observed with [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy).

