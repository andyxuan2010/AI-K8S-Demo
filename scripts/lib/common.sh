#!/usr/bin/env bash
# Shared logging, error handling, and dependency checks for repository scripts.
SCRIPT_COMMON_VERSION="1.0.0"

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
