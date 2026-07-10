#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

if ! command -v docker >/dev/null 2>&1; then
  printf 'ERROR: docker CLI is not available on this host.\n' >&2
  exit 1
fi

section "COMPOSE PROJECTS"
printf '%-24s %-22s %s\n' "PROJECT" "CONTAINER" "CONFIG SOURCE"
printf '%-24s %-22s %s\n' "-------" "---------" "-------------"

for container in $(docker ps -a --format '{{.Names}}' | sort); do
  project=$(docker inspect "$container" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null)
  config=$(docker inspect "$container" --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}' 2>/dev/null)
  [[ -n "$project" ]] || project="not-compose"
  [[ -n "$config" ]] || config="unknown"
  printf '%-24s %-22s %s\n' "$project" "$container" "$config"
done

section "PROJECT MEMBERSHIP"
projects=$(for container in $(docker ps -a --format '{{.Names}}'); do
  docker inspect "$container" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null
done | sed '/^$/d' | sort -u)

if [[ -z "$projects" ]]; then
  printf 'No Compose-managed containers detected.\n'
else
  while IFS= read -r project; do
    printf '\n%s\n' "$project"
    for container in $(docker ps -a --format '{{.Names}}' | sort); do
      current=$(docker inspect "$container" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null)
      if [[ "$current" == "$project" ]]; then
        image=$(docker inspect "$container" --format '{{.Config.Image}}' 2>/dev/null)
        status=$(docker inspect "$container" --format '{{.State.Status}}' 2>/dev/null)
        printf '  - %s | %s | %s\n' "$container" "$status" "$image"
      fi
    done
  done <<< "$projects"
fi

section "NON-COMPOSE CONTAINERS"
found=0
for container in $(docker ps -a --format '{{.Names}}' | sort); do
  project=$(docker inspect "$container" --format '{{index .Config.Labels "com.docker.compose.project"}}' 2>/dev/null)
  if [[ -z "$project" ]]; then
    printf '%s\n' "$container"
    found=1
  fi
done

[[ "$found" -eq 1 ]] || printf 'None detected.\n'
