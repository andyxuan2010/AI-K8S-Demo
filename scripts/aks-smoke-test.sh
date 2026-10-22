#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-https://basf.argentiacapital.com/}"
CURL_ARGS=(--fail --silent --show-error --location --max-time "${CURL_TIMEOUT:-20}")

command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
echo "Checking API endpoint: $API_URL"
curl "${CURL_ARGS[@]}" "$API_URL"
printf '\nAPI endpoint responded successfully.\n'
