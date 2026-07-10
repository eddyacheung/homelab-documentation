#!/usr/bin/env bash
set -u

section() {
  printf '\n===== %s =====\n' "$1"
}

if ! command -v docker >/dev/null 2>&1; then
  printf 'ERROR: docker CLI is not available on this host.\n' >&2
  exit 1
fi

section "DOCKER NETWORKS"
docker network ls

section "NETWORK MEMBERSHIP"
for network in $(docker network ls --format '{{.Name}}' | sort); do
  printf '\n%s\n' "$network"
  members=$(docker network inspect "$network" --format '{{range .Containers}}{{println .Name}}{{end}}' 2>/dev/null | sort)
  if [[ -n "$members" ]]; then
    while IFS= read -r member; do
      printf '  - %s\n' "$member"
    done <<< "$members"
  else
    printf '  - no attached containers\n'
  fi
done

section "CONTAINER NETWORK ATTACHMENTS"
for container in $(docker ps -a --format '{{.Names}}' | sort); do
  printf '%s: ' "$container"
  docker inspect "$container" --format '{{range $name, $value := .NetworkSettings.Networks}}{{printf "%s " $name}}{{end}}' 2>/dev/null || true
  printf '\n'
done

section "KEY NETWORK CHECKS"
for network in media-net ai-net pihole_macvlan; do
  if docker network inspect "$network" >/dev/null 2>&1; then
    printf '%s: present\n' "$network"
  else
    printf '%s: missing\n' "$network"
  fi
done
