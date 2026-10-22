#!/usr/bin/env bash
# Script: common.sh
# Version: 1.1.0
# Summary: Shared Bash logging, input validation, Linux checks, and error handling.
# Usage: Source this file from a repository script, then call script_init.
SCRIPT_COMMON_VERSION="1.1.0"

script_init() {
  local version="$1"
  local script_name="${2:-$(basename -- "${BASH_SOURCE[1]:-${0}}")}"
  local state_dir="${XDG_STATE_HOME:-${HOME:-/tmp}/.local/state}"
  local log_dir="${SCRIPT_LOG_DIR:-$state_dir/ai-k8s-demo/logs}"

  mkdir -p -- "$log_dir"
  SCRIPT_NAME="$script_name"
  SCRIPT_VERSION="$version"
  SCRIPT_LOG_FILE="$log_dir/${script_name}.log"
  export SCRIPT_NAME SCRIPT_VERSION SCRIPT_LOG_FILE

  exec > >(tee -a "$SCRIPT_LOG_FILE") 2>&1
  trap 'script_error_handler "$?" "$LINENO"' ERR
  trap 'script_exit_handler "$?"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION (pid $$)"
  log_info "Log file: $SCRIPT_LOG_FILE"
  if ! SCRIPT_OS_FAMILY="$(detect_linux_family)"; then
    log_error "Supported Linux distributions are Ubuntu and Red Hat family (RHEL-compatible)."
    return 1
  fi
  export SCRIPT_OS_FAMILY
  log_info "Validated Linux distribution family: $SCRIPT_OS_FAMILY"
}

detect_linux_family() {
  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  local id id_like

  if [[ ! -r "$os_release_file" ]]; then
    log_error "Cannot read Linux distribution metadata at $os_release_file"
    return 1
  fi

  # os-release is a shell-compatible file supplied by the operating system.
  # shellcheck disable=SC1090
  . "$os_release_file"
  id="${ID:-}"
  id_like="${ID_LIKE:-}"
  id="${id,,}"
  id_like="${id_like,,}"

  case " $id $id_like " in
    *" ubuntu "*) printf 'ubuntu\n' ;;
    *" rhel "*|*" redhat "*|*" centos "*|*" rocky "*|*" almalinux "*|*" ol "*|*" fedora "*) printf 'redhat\n' ;;
    *)
      log_error "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}"
      return 1
      ;;
  esac
}

log_info() {
  printf '[%s] [INFO] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

log_warn() {
  printf '[%s] [WARN] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}

log_error() {
  printf '[%s] [ERROR] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}

script_error_handler() {
  local status="$1"
  local line="$2"
  trap - ERR
  log_error "${SCRIPT_NAME:-script} failed at line $line (exit $status)"
  exit "$status"
}

script_exit_handler() {
  local status="$1"
  if [[ "$status" -eq 0 ]]; then
    log_info "Completed $SCRIPT_NAME v$SCRIPT_VERSION successfully"
  else
    log_error "$SCRIPT_NAME v$SCRIPT_VERSION exited with status $status"
  fi
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log_error "Required command not found: $command_name"
    return 127
  fi
}

script_usage() {
  printf '%s\n' "${SCRIPT_USAGE:-Usage: $(basename -- "${0}") [options]}"
}

handle_help() {
  if [[ "$#" -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
    script_usage
    exit 0
  fi
}

validate_arg_count() {
  local minimum="$1"
  local maximum="$2"
  shift 2
  local count="$#"

  if (( count < minimum || count > maximum )); then
    log_error "Invalid number of arguments."
    script_usage >&2
    exit 2
  fi
}

validate_non_empty() {
  local input_name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    log_error "$input_name must not be empty."
    exit 2
  fi
}

validate_positive_integer() {
  local input_name="$1"
  local value="$2"
  local allow_zero="${3:-false}"
  local upper_bound="${4:-}"
  local pattern='^[1-9][0-9]*$'

  if [[ "$allow_zero" == "true" ]]; then
    pattern='^(0|[1-9][0-9]*)$'
  fi
  if [[ ! "$value" =~ $pattern ]]; then
    log_error "$input_name must be a $([[ "$allow_zero" == "true" ]] && printf 'non-negative' || printf 'positive') integer."
    exit 2
  fi
  if [[ -n "$upper_bound" ]] && (( value > upper_bound )); then
    log_error "$input_name must not exceed $upper_bound."
    exit 2
  fi
}

validate_boolean() {
  local input_name="$1"
  local value="$2"
  if [[ "$value" != "true" && "$value" != "false" ]]; then
    log_error "$input_name must be 'true' or 'false'."
    exit 2
  fi
}

validate_duration() {
  local input_name="$1"
  local value="$2"
  # Accept Go-style durations such as 30s, 5m, and 1m30s.
  if [[ ! "$value" =~ ^([0-9]+([.][0-9]+)?(ns|us|µs|ms|s|m|h))+$ ]]; then
    log_error "$input_name must be a duration such as 30s, 5m, or 1m30s."
    exit 2
  fi
}
