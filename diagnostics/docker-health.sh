#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

if ! command -v docker >/dev/null 2>&1; then
  printf 'ERROR: docker CLI is not available on this host.\n' >&2
  exit 1
fi

section "HOST"
printf 'Hostname: %s\n' "$(hostname)"
printf 'Time: %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
printf 'Docker: %s\n' "$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo unavailable)"

section "CONTAINERS"
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

section "HEALTH AND RESTART COUNTS"
for container in $(docker ps -a --format '{{.Names}}' | sort); do
  docker inspect "$container" --format '{{.Name}}|status={{.State.Status}}|health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}|restarts={{.RestartCount}}' 2>/dev/null \
    | sed 's#^/##'
done

section "UNHEALTHY OR RESTARTING"
problem_count=0
for container in $(docker ps -a --format '{{.Names}}' | sort); do
  status=$(docker inspect "$container" --format '{{.State.Status}}' 2>/dev/null || echo unknown)
  health=$(docker inspect "$container" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}' 2>/dev/null || echo unknown)
  if [[ "$status" != "running" || "$health" == "unhealthy" || "$health" == "starting" ]]; then
    printf '%s: status=%s health=%s\n' "$container" "$status" "$health"
    problem_count=$((problem_count + 1))
  fi
done

if [[ "$problem_count" -eq 0 ]]; then
  printf 'No stopped, unhealthy, or starting containers detected.\n'
fi

section "DOCKER DISK USAGE"
docker system df 2>/dev/null || printf 'Docker disk usage unavailable.\n'
