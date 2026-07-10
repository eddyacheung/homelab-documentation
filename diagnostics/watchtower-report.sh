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

if docker info >/dev/null 2>&1; then
  docker_cmd=(docker)
elif command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
  docker_cmd=(sudo docker)
else
  printf 'ERROR: Docker is installed, but this user cannot access it. Run the script with sudo or grant Docker socket access.\n' >&2
  exit 1
fi

if ! "${docker_cmd[@]}" inspect "$container" >/dev/null 2>&1; then
  printf 'ERROR: %s container was not found.\n' "$container" >&2
  exit 1
fi

section "STATUS"
"${docker_cmd[@]}" ps -a --filter "name=^/${container}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

section "HEALTH"
"${docker_cmd[@]}" inspect "$container" --format 'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}} restarts={{.RestartCount}}'

section "WATCHTOWER SETTINGS"
"${docker_cmd[@]}" inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
  | grep -E '^(DOCKER_API_VERSION|TZ|WATCHTOWER_[A-Z0-9_]+)=' \
  | sort

section "WATCHTOWER LABEL"
"${docker_cmd[@]}" inspect "$container" --format '{{index .Config.Labels "com.centurylinklabs.watchtower.enable"}}' 2>/dev/null \
  | sed 's/^/watchtower enable label: /'

section "OPTED-IN CONTAINERS"
found=0
while IFS= read -r candidate; do
  enabled=$("${docker_cmd[@]}" inspect "$candidate" --format '{{index .Config.Labels "com.centurylinklabs.watchtower.enable"}}' 2>/dev/null)
  if [[ "$enabled" == "true" ]]; then
    printf '%s\n' "$candidate"
    found=1
  fi
done < <("${docker_cmd[@]}" ps -a --format '{{.Names}}' | sort)
[[ "$found" -eq 1 ]] || printf 'No containers have the enable label.\n'

section "RECENT LOGS"
"${docker_cmd[@]}" logs --tail 80 "$container" 2>&1
