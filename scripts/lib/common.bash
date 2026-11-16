#!/usr/bin/env bash

[[ "${BASH_SOURCE[0]:-${0}}" != "${0}" ]] || return 0

function echo_stderr() {
    echo "${*}" >&2
}

function log_level_to_num() {
    local -r level="${1}"
    # See: https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-severitynumber
    case "${level}" in
    "trace") echo 1 ;;
    "debug") echo 5 ;;
    "info") echo 9 ;;
    "warn") echo 13 ;;
    "error") echo 17 ;;
    "fatal") echo 21 ;;
    *) echo 9 ;;
    esac
}

function log() {
    local -r level="${1}"
    local -r message="${2}"
    local -r script_loc="${0##*/}"
    local -r function="${FUNCNAME[2]:-main}"

    local threshold="${TAP_LOG_LEVEL:-${OTEL_LOG_LEVEL:-info}}"
    threshold="${threshold,,}"
    local threshold_num
    threshold_num=$(log_level_to_num "${threshold}")

    local -r lowered="${level,,}"
    local level_num
    level_num=$(log_level_to_num "${lowered}")

    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if ((level_num >= threshold_num)); then
        echo_stderr "[${timestamp}] [${lowered}] [${script_loc}] [${function}] ${message}"
    fi
}

function log_trace() {
    local -r message="${1:-}"
    log "TRACE" "${message}"
}

function log_debug() {
    local -r message="${1:-}"
    log "DEBUG" "${message}"
}

function log_info() {
    local -r message="${1:-}"
    log "INFO" "${message}"
}

function log_warn() {
    local -r message="${1:-}"
    log "WARN" "${message}"
}

function log_error() {
    local -r message="${1:-}"
    log "ERROR" "${message}"
}

function log_fatal() {
    local -r message="${1:-}"
    log "FATAL" "${message}"
}

function is_cmd_available() {
    local -r cmd="${1:-}"
    command -v "${cmd}" &>/dev/null
}

function is_version() {
    [[ "${1:-}" =~ ^[0-9]+(\.[0-9]+)*$ ]]
}

function is_sha256() {
    [[ "${1:-}" =~ ^[0-9a-f]{64}$ ]]
}

function check_commands() {
    local missing_commands=()
    local cmd
    for cmd in "${@}"; do
        if ! is_cmd_available "${cmd}"; then
            missing_commands+=("${cmd}")
        fi
    done

    if [ "${#missing_commands[@]}" -gt 0 ]; then
        log_fatal "the following required commands are missing:"
        local missing_cmd
        for missing_cmd in "${missing_commands[@]}"; do
            log_fatal "  - ${missing_cmd}"
        done
        return 1
    fi
}

function check_gnu_flags() {
    local unsupported=()
    local probe
    local help_text
    for probe in "${@}"; do
        if ! help_text=$("${probe%% *}" --help 2>&1); then
            unsupported+=("${probe}")
            continue
        fi
        if ! grep --quiet -- "${probe##* }" <<<"${help_text}"; then
            unsupported+=("${probe}")
        fi
    done

    if [ "${#unsupported[@]}" -gt 0 ]; then
        log_fatal "GNU coreutils is required; unsupported here:"
        local unsupported_probe
        for unsupported_probe in "${unsupported[@]}"; do
            log_fatal "  - ${unsupported_probe}"
        done
        return 1
    fi
}

function download_sha256() {
    local -r download_url="${1:-}"

    if [ -z "${download_url}" ]; then
        log_error "a download url is required"
        return 1
    fi

    local hashed
    if ! hashed=$(curl --fail --silent --show-error --location "${download_url}" | shasum --algorithm 256); then
        return 1
    fi

    local -r digest="${hashed%% *}"
    # with pipefail unset in a sourcing caller, a failed curl still yields
    # the hash of empty input, so the result is checked rather than trusted
    if ! is_sha256 "${digest}" || [ "${digest}" = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]; then
        return 1
    fi
    echo "${digest}"
}
