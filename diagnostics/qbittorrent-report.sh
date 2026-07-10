#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

if ! command -v docker >/dev/null 2>&1; then
  printf 'ERROR: docker CLI is not available on this host.\n' >&2
  exit 1
fi

for required in gluetun qbittorrent; do
  if ! docker inspect "$required" >/dev/null 2>&1; then
    printf 'ERROR: %s container was not found.\n' "$required" >&2
    exit 1
  fi
done

section "CONTAINER STATUS"
docker ps -a --filter name=gluetun --filter name=qbittorrent --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

section "HEALTH AND RESTART COUNTS"
for container in gluetun qbittorrent; do
  docker inspect "$container" --format '{{.Name}}|status={{.State.Status}}|health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}|restarts={{.RestartCount}}' \
    | sed 's#^/##'
done

section "DEPENDENCY AND NETWORK MODE"
printf 'qBittorrent network mode: '
docker inspect qbittorrent --format '{{.HostConfig.NetworkMode}}'
printf 'Gluetun Compose project: '
docker inspect gluetun --format '{{index .Config.Labels "com.docker.compose.project"}}'
printf 'qBittorrent Compose project: '
docker inspect qbittorrent --format '{{index .Config.Labels "com.docker.compose.project"}}'

section "PUBLISHED PORTS"
docker port gluetun 2>/dev/null || printf 'No published ports reported.\n'

section "VPN EXTERNAL IP"
if docker exec qbittorrent sh -c 'command -v wget >/dev/null 2>&1' >/dev/null 2>&1; then
  docker exec qbittorrent sh -c 'timeout 15 wget -qO- https://ipinfo.io/ip || echo "IP check failed"'
  printf '\n'
else
  printf 'wget is unavailable inside qBittorrent; IP check skipped.\n'
fi

section "GLUETUN RECENT LOGS"
docker logs --tail 80 gluetun 2>&1

section "QBITTORRENT RECENT LOGS"
docker logs --tail 80 qbittorrent 2>&1

section "RECOVERY LOG"
recovery_log='/volume1/docker/qbittorrent-recovery/recovery.log'
if [[ -f "$recovery_log" ]]; then
  tail -40 "$recovery_log"
else
  printf 'Recovery log not found at %s\n' "$recovery_log"
fi
