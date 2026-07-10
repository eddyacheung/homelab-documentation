#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=0
stack_count=0

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  failures=$((failures + 1))
}

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

  temp_env=""
  if [[ -f "$stack_dir/.env.example" ]]; then
    temp_env="$(mktemp)"
    cp "$stack_dir/.env.example" "$temp_env"
  else
    temp_env="$(mktemp)"
    : > "$temp_env"
  fi

  if ! docker compose --env-file "$temp_env" -f "$compose" config --quiet; then
    fail "$stack_name failed docker compose config"
  fi

  rm -f "$temp_env"
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

printf '\nValidation passed for %d Docker stack(s).\n' "$stack_count"
