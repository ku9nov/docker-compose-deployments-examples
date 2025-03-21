#!/bin/bash

DOCKER_COMPOSE_FILE="docker-compose.rolling.yaml"

# Getting list of services, ignoring services which contains "proxy" in name
services=$(yq eval '.services | keys | map(select(test("proxy") | not)) | .[]' "$DOCKER_COMPOSE_FILE")

service_ips=""

# Getting containers IP-addresses
for service in $services; do
  container_ids=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps -q "$service")

  for container_id in $container_ids; do
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    if [ -n "$container_ip" ]; then
      service_ips="${service_ips}${service}:${container_ip} "
    fi
  done
done

if [ -z "$service_ips" ]; then
  echo "Error: The list of IP addresses is empty!"
  exit 1
fi

# Get Traefik-labels and generate YAML
docker ps -q | xargs -I {} docker inspect --format '{{json .Config.Labels}}' {} | jq -s --arg service_ips "$service_ips" '
  def split_ips:
    reduce ($service_ips | split(" "))[] as $item ({}; 
      if ($item | contains(":")) then
        . + { ($item | split(":")[0]): (.[$item | split(":")[0]] + [ $item | split(":")[1] ] // []) }
      else . end
    );

  def extract_health_check(item):
    if (
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.path"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.interval"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.timeout"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.scheme"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.mode"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.hostname"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.port"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.followRedirects"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.method"] // "") == "" and
      (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.status"] // "") == ""
    ) then
      empty
    else
      {
        path: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.path"] // ""),
        interval: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.interval"] // ""),
        timeout: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.timeout"] // ""),
        scheme: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.scheme"] // ""),
        mode: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.mode"] // ""),
        hostname: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.hostname"] // ""),
        port: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.port"] // ""),
        followRedirects: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.followRedirects"] // ""),
        method: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.method"] // ""),
        status: (item["traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.status"] // ""),
        headers: (
          item | to_entries | 
          map(select(.key | startswith("traefik.http.services." + item["com.docker.compose.service"] + ".loadbalancer.healthCheck.headers."))) |
          map({
            key: (.key | split(".") | .[-1]), 
            value: .value
          }) |
          from_entries
        ), 
      } | with_entries(select(.value != "" and .value != {}))
      
    end;



  reduce .[] as $item ({}; 
    if ($item["com.docker.compose.service"] | in(split_ips)) then
      # Debug: Print all labels
      debug("Service: \($item["com.docker.compose.service"])", ""),
      debug("Labels: \($item | tostring)", ""),
      debug("Rule: \($item["traefik.http.routers.\($item["com.docker.compose.service"]).rule"] | tostring)", ""),

      .http.routers[$item["com.docker.compose.service"]].rule = $item["traefik.http.routers.\($item["com.docker.compose.service"]).rule"] // null |
      .http.routers[$item["com.docker.compose.service"]].service = $item["com.docker.compose.service"] |
      .http.services[$item["com.docker.compose.service"]].loadBalancer.servers = 
        (split_ips[$item["com.docker.compose.service"]] | map({url: ("http://" + . + ":" + ($item["traefik.http.services.\($item["com.docker.compose.service"]).loadbalancer.server.port"] // "80"))})) |
      
      # Debug: Print values for HealthCheck Path, Interval and Timeout
      debug("HealthCheck Path: \($item["traefik.http.services." + $item["com.docker.compose.service"] + ".loadbalancer.healthCheck.path"] // "none")", ""),
      debug("HealthCheck Interval: \($item["traefik.http.services." + $item["com.docker.compose.service"] + ".loadbalancer.healthCheck.interval"] // "none")", ""),
      debug("HealthCheck Timeout: \($item["traefik.http.services." + $item["com.docker.compose.service"] + ".loadbalancer.healthCheck.timeout"] // "none")", ""),
      debug("Extracting headers for service: \($item["com.docker.compose.service"])", ""),
      debug("Headers: \($item | to_entries | map(select(.key | startswith("traefik.http.services." + $item["com.docker.compose.service"] + ".loadbalancer.healthCheck.headers."))) | .[] | "\(.key) = \(.value)")", ""),

      debug("Calling extract_health_check for service: \($item["com.docker.compose.service"])", ""),
      (extract_health_check($item) as $hc |
        if $hc then
          .http.services[$item["com.docker.compose.service"]].loadBalancer += { healthCheck: $hc }
        else
          .
        end
      )


    else . end
  )' | yq -P 

