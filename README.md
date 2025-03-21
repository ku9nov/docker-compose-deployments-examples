# Deployment Options with Docker Compose

This repository demonstrates different deployment strategies that can be achieved using Docker Compose.

The purpose of these deployment methods varies, but the most important aspects are stability and zero downtime. Achieving these goals with Docker Compose can be quite challenging.

## 1. Rolling Deployment

To implement this deployment method, we need the following plugin: [docker-ztd](https://github.com/ku9nov/docker-compose-ztd-plugin). You can install it using the following command:

```sh
curl -fsSL https://gist.githubusercontent.com/ku9nov/f76d2b7f65fa266a17c89e0a50880479/raw/9182ae94d16bea270a4228dd17be16f05e156041/install-docker-ztd.sh | bash
```

After a successful installation, you can start the example deployment using:

```sh
docker ztd -f docker-compose.rolling.yaml up -d
```

For the first 10 seconds, traffic will not be routed to the backend due to the configured health check. This is useful for testing purposes.

Once the applications are up and running, you can verify them using the following commands:

```sh
curl -H "Host:backend.example.com" http://127.0.0.1:8000/
Hello, instance: db0fb18accab, started at: 2025-03-19T09:33:32Z
```

```sh
curl -H "Host:frontend.example.com" http://127.0.0.1:8000/
<!doctype html><html lang="en"><head><meta charset="utf-8"/><link rel="icon" href="/favicon.ico"/><meta name="viewport" content="width=device-width,initial-scale=1"/><meta name="theme-color" content="#000000"/><meta name="description" content="Web site created using create-react-app"/><link rel="apple-touch-icon" href="/logo192.png"/><link rel="manifest" href="/manifest.json"/><title>React App</title><script defer="defer" src="/static/js/main.f9dc6ac2.js"></script><link href="/static/css/main.f855e6bc.css" rel="stylesheet"></head><body><noscript>You need to enable JavaScript to run this app.</noscript><div id="root"></div></body></html>
```

To trigger an update, use the following command:

```sh
docker ztd -f docker-compose.rolling.yaml helloworld
```

Curl request for checking zero-time-deployment:

```bash
while true; do curl -H "Host:backend.example.com" http://127.0.0.1:8000; echo -e "\n" ; done
```


