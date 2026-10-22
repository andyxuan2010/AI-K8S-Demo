#!/usr/bin/env bash
# Script: aks-smoke-test.sh
# Version: 1.1.0
# Summary: Sends an HTTP request to the configured API endpoint.
# Usage: aks-smoke-test.sh
# Inputs: Optional API_URL and CURL_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-smoke-test'

SCRIPT_USAGE='Usage: aks-smoke-test.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

API_URL="${API_URL:-https://basf.argentiacapital.com/}"
CURL_TIMEOUT="${CURL_TIMEOUT:-20}"
validate_non_empty API_URL "$API_URL"
validate_positive_integer CURL_TIMEOUT "$CURL_TIMEOUT"
CURL_ARGS=(--fail --silent --show-error --location --max-time "$CURL_TIMEOUT")

require_command curl
log_info "Checking API endpoint: $API_URL"
curl "${CURL_ARGS[@]}" "$API_URL"
log_info "API endpoint responded successfully"
