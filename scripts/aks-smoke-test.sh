#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-smoke-test'

API_URL="${API_URL:-https://basf.argentiacapital.com/}"
CURL_ARGS=(--fail --silent --show-error --location --max-time "${CURL_TIMEOUT:-20}")

require_command curl
echo "Checking API endpoint: $API_URL"
curl "${CURL_ARGS[@]}" "$API_URL"
printf '\nAPI endpoint responded successfully.\n'
