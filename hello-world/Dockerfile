FROM golang:1.20-alpine AS builder

WORKDIR /app

COPY . .

RUN go build -o hello-world .

FROM alpine:latest

RUN apk add --no-cache curl
COPY --from=builder /app/hello-world /usr/local/bin/hello-world

EXPOSE 8000

CMD ["hello-world"]
