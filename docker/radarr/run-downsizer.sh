#!/bin/bash

set -euo pipefail

export RADARR_API_KEY="$(awk '/api_key:/ {print $2; exit}' /volume1/docker/recyclarr/config/configs/uhd-bluray-web.yml)"

exec /usr/bin/python3 /volume1/docker/radarr-downsizer/radarr_downsizer_v8.py \
  --existing-min-gib 25 \
  --minimum-savings-percent 30 \
  --min-seeders 2 \
  --apply
