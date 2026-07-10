#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

container="watchtower"

if ! command -v docker >/dev/null 2>&1; then
  printf 'ERROR: docker CLI is not available on this host.\n' >&2
  exit 1
fi

if ! docker inspect "$container" >/dev/null 2>&1; then
  printf 'ERROR: %s container was not found.\n' "$container" >&2
  exit 1
fi

section "STATUS"
docker ps -a --filter "name=^/${container}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

section "HEALTH"
docker inspect "$container" --format 'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}} restarts={{.RestartCount}}'

section "WATCHTOWER SETTINGS"
docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
  | grep -E '^(DOCKER_API_VERSION|TZ|WATCHTOWER_)=' \
  | sort

section "WATCHTOWER LABEL"
docker inspect "$container" --format '{{index .Config.Labels "com.centurylinklabs.watchtower.enable"}}' 2>/dev/null \
  | sed 's/^/watchtower enable label: /'

section "OPTED-IN CONTAINERS"
found=0
for candidate in $(docker ps -a --format '{{.Names}}' | sort); do
  enabled=$(docker inspect "$candidate" --format '{{index .Config.Labels "com.centurylinklabs.watchtower.enable"}}' 2>/dev/null)
  if [[ "$enabled" == "true" ]]; then
    printf '%s\n' "$candidate"
    found=1
  fi
done
[[ "$found" -eq 1 ]] || printf 'No containers have the enable label.\n'

section "RECENT LOGS"
docker logs --tail 80 "$container" 2>&1
