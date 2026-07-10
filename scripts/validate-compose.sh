#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0
stack_count=0
compose_checks=0

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  failures=$((failures + 1))
}

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  compose_available=true
else
  compose_available=false
  printf 'WARNING: Docker Compose CLI is unavailable; syntax rendering will be skipped locally.\n'
  printf '         GitHub Actions will still perform the full Compose validation.\n\n'
fi

printf 'Checking for forbidden tracked secret files...\n'
while IFS= read -r path; do
  case "$path" in
    */.env.example) ;;
    */.env|.env|*.secret|secrets/*|*/secrets/*)
      fail "Forbidden secret-bearing path is tracked: $path"
      ;;
  esac
done < <(git ls-files)

printf 'Validating stack directory contracts and Compose syntax...\n'
for compose in docker/*/docker-compose.yml; do
  [[ -e "$compose" ]] || continue
  stack_count=$((stack_count + 1))
  stack_dir="$(dirname "$compose")"
  stack_name="$(basename "$stack_dir")"

  printf '  - %s\n' "$stack_name"

  [[ -f "$stack_dir/README.md" ]] || fail "$stack_name is missing README.md"

  if [[ "$compose_available" == true ]]; then
    temp_env="$(mktemp)"
    if [[ -f "$stack_dir/.env.example" ]]; then
      cp "$stack_dir/.env.example" "$temp_env"
    else
      : > "$temp_env"
    fi

    if ! docker compose --env-file "$temp_env" -f "$compose" config --quiet; then
      fail "$stack_name failed docker compose config"
    else
      compose_checks=$((compose_checks + 1))
    fi

    rm -f "$temp_env"
  fi
done

[[ "$stack_count" -gt 0 ]] || fail "No Docker Compose stacks were found"

printf 'Checking environment-variable references...\n'
for compose in docker/*/docker-compose.yml; do
  [[ -e "$compose" ]] || continue
  stack_dir="$(dirname "$compose")"
  example="$stack_dir/.env.example"

  mapfile -t vars < <(grep -oE '\$\{[A-Za-z_][A-Za-z0-9_]*(:-[^}]*)?\}' "$compose" \
    | sed -E 's/^\$\{//; s/\}$//; s/:-.*$//' \
    | sort -u || true)

  for var in "${vars[@]}"; do
    if [[ ! -f "$example" ]]; then
      fail "$(basename "$stack_dir") references $var but has no .env.example"
    elif ! grep -qE "^${var}=" "$example"; then
      fail "$(basename "$stack_dir") references $var but .env.example does not define it"
    fi
  done
done

printf 'Checking for obvious placeholder mistakes...\n'
if grep -RniE --include='docker-compose.yml' '(ChangeThisPassword|REDACTED|Put your .* here)' docker; then
  fail "A Compose file contains an unsafe or unfinished placeholder"
fi

if [[ "$failures" -ne 0 ]]; then
  printf '\nValidation failed with %d error(s).\n' "$failures" >&2
  exit 1
fi

if [[ "$compose_available" == true ]]; then
  printf '\nValidation passed for %d Docker stack(s); %d Compose files rendered successfully.\n' "$stack_count" "$compose_checks"
else
  printf '\nStatic validation passed for %d Docker stack(s). Compose rendering was skipped because Docker is unavailable.\n' "$stack_count"
fi
