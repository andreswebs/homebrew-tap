#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/common.bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/lib/common.bash"

readonly DOWNLOADS_API_URL="https://api.defined.net/v1/downloads"

function usage() {
    echo_stderr "update-dnclient-desktop.bash - bump the dnclient-desktop cask to the latest release"
    echo_stderr
    echo_stderr "Usage:"
    echo_stderr "  update-dnclient-desktop.bash [--apply]"
    echo_stderr "  update-dnclient-desktop.bash --help | -h"
    echo_stderr
    echo_stderr "Options:"
    echo_stderr "  --apply"
    echo_stderr "    Write the change. Without it, only report what would change."
    echo_stderr
    echo_stderr "  --help, -h"
    echo_stderr "    Show this help"
    echo_stderr
    echo_stderr "Environment:"
    echo_stderr "  UPDATE_DNCLIENT_CASK_FILE"
    echo_stderr "    The cask file to update. Default: Casks/dnclient-desktop.rb"
    echo_stderr "    beside this script's directory."
    echo_stderr
    echo_stderr "  TAP_LOG_LEVEL"
    echo_stderr "    trace, debug, info, warn, error or fatal. Default: info."
    echo_stderr
}

function check_dependencies() {
    check_commands "awk" "curl" "date" "grep" "jq" "realpath" "shasum" || return 1
    check_gnu_flags "realpath --canonicalize-existing" || return 1
}

function get_cask_file() {
    local script_dir
    if ! script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"; then
        log_error "could not resolve the script directory"
        return 1
    fi

    local -r wanted="${UPDATE_DNCLIENT_CASK_FILE:-${script_dir}/../Casks/dnclient-desktop.rb}"
    local cask_file
    if ! cask_file=$(realpath --canonicalize-existing --quiet "${wanted}"); then
        log_error "cask file not found: ${wanted}"
        return 1
    fi
    if ! [ -f "${cask_file}" ] || ! [ -r "${cask_file}" ]; then
        log_error "cask file not readable: ${cask_file}"
        return 1
    fi
    echo "${cask_file}"
}

function cask_read_field() {
    local -r cask_file="${1:-}"
    local -r field="${2:-}"

    if ! [ -f "${cask_file}" ] || ! [ -r "${cask_file}" ]; then
        log_error "cask file not readable: ${cask_file}"
        return 1
    fi
    if [ "${field}" != "version" ] && [ "${field}" != "sha256" ]; then
        log_error "unsupported cask field: ${field}"
        return 1
    fi

    local -r pattern="^[[:space:]]*${field}[[:space:]]+\"([^\"]+)\""
    local line
    while IFS= read -r line; do
        if [[ "${line}" =~ ${pattern} ]]; then
            echo "${BASH_REMATCH[1]}"
            return 0
        fi
    done <"${cask_file}"

    log_error "no ${field} stanza in ${cask_file##*/}"
    return 1
}

function downloads_read_latest() {
    local -r downloads="${1:-}"

    if [ -z "${downloads}" ]; then
        log_error "a downloads document is required"
        return 1
    fi

    local fields
    if ! fields=$(jq --raw-output --exit-status \
        '[.data.versionInfo.latest.dnclient, .data.dnclient.latest["macos-universal-desktop"]]
            | select(all(type == "string")) | @tsv' <<<"${downloads}" 2>/dev/null); then
        log_error "the downloads document has no macOS desktop release"
        return 1
    fi

    local -r version="${fields%%$'\t'*}"
    local -r download_url="${fields#*$'\t'}"

    if ! is_version "${version}"; then
        log_error "unexpected dnclient version: ${version}"
        return 1
    fi

    # the url is fetched as-is afterwards, so its host and shape are pinned
    local -r url_pattern='^https://dl\.defined\.net/([0-9a-f]+)/v[0-9.]+/macos/[A-Za-z0-9._-]+\.dmg$'
    if ! [[ "${download_url}" =~ ${url_pattern} ]]; then
        log_error "unexpected download url: ${download_url}"
        return 1
    fi

    printf '%s,%s\t%s\n' "${version}" "${BASH_REMATCH[1]}" "${download_url}"
}

function cask_rewrite() {
    local -r cask_file="${1:-}"
    local -r new_version="${2:-}"
    local -r new_sha256="${3:-}"

    if ! [ -f "${cask_file}" ] || ! [ -r "${cask_file}" ]; then
        log_error "cask file not readable: ${cask_file}"
        return 1
    fi
    if ! [[ "${new_version}" =~ ^[0-9]+(\.[0-9]+)*,[0-9a-f]+$ ]]; then
        log_error "not a dnclient cask version: ${new_version}"
        return 1
    fi
    if ! is_sha256 "${new_sha256}"; then
        log_error "not a sha256 checksum: ${new_sha256}"
        return 1
    fi

    # -v, not --assign: the long form is gawk-only and Ubuntu's awk is mawk
    awk -v version="${new_version}" -v checksum="${new_sha256}" '
        !version_done && /^[ \t]*version "/ {
            sub(/"[^"]*"/, "\"" version "\"")
            version_done = 1
        }
        !checksum_done && /^[ \t]*sha256 "/ {
            sub(/"[^"]*"/, "\"" checksum "\"")
            checksum_done = 1
        }
        { print }
    ' "${cask_file}"
}

function update_cask() {
    local -r apply="${1}"

    check_dependencies || return 1

    local cask_file
    cask_file=$(get_cask_file) || return 1

    local current_version
    current_version=$(cask_read_field "${cask_file}" "version") || return 1
    local current_sha256
    current_sha256=$(cask_read_field "${cask_file}" "sha256") || return 1

    local downloads
    if ! downloads=$(curl --fail --silent --show-error --location "${DOWNLOADS_API_URL}"); then
        log_error "could not fetch ${DOWNLOADS_API_URL}"
        return 1
    fi

    local latest
    latest=$(downloads_read_latest "${downloads}") || return 1
    local -r latest_version="${latest%%$'\t'*}"
    local -r download_url="${latest#*$'\t'}"

    if [ "${current_version}" = "${latest_version}" ] && is_sha256 "${current_sha256}"; then
        log_info "dnclient-desktop: up to date (${current_version})"
        return 0
    fi

    log_info "downloading ${download_url} to hash it"
    local latest_sha256
    if ! latest_sha256=$(download_sha256 "${download_url}"); then
        log_error "could not download and hash ${download_url}"
        return 1
    fi

    local candidate
    if ! candidate=$(cask_rewrite "${cask_file}" "${latest_version}" "${latest_sha256}"); then
        log_error "could not rewrite ${cask_file##*/}"
        return 1
    fi

    if [ "${apply}" != "true" ]; then
        log_info "dnclient-desktop: would update ${current_version} -> ${latest_version}"
        log_info "run again with --apply to write the change"
        return 0
    fi

    # written in place rather than moved over, so the file keeps its mode
    if ! printf '%s\n' "${candidate}" >"${cask_file}"; then
        log_error "could not write ${cask_file}"
        return 1
    fi
    log_info "dnclient-desktop: updated ${current_version} -> ${latest_version}"
}

function shutdown() {
    local -r signal="${1}"

    log_warn "received ${signal}; the cask file is written last and in one step, so it is unchanged unless an update was already reported"

    case "${signal}" in
    SIGINT) exit 130 ;;
    SIGTERM) exit 143 ;;
    *) exit 1 ;;
    esac
}

function parse_arguments() {
    action="dry-run"

    local key
    while [ "${#}" -gt 0 ]; do
        key="${1}"
        case "${key}" in
        --help | -h)
            usage
            exit 0
            ;;
        --apply)
            action="apply"
            ;;
        -?*)
            echo_stderr "${0##*/}: invalid option: ${key}"
            exit 1
            ;;
        *)
            echo_stderr "${0##*/}: invalid argument: ${key}"
            exit 1
            ;;
        esac
        shift
    done
}

function main() {
    # set here, not at file scope, so a test that sources this file keeps
    # its own shell options
    set -o errexit
    set -o nounset
    set -o pipefail

    local action
    parse_arguments "${@}"

    trap 'shutdown SIGINT' SIGINT
    trap 'shutdown SIGTERM' SIGTERM

    case "${action}" in
    "apply") update_cask "true" ;;
    "dry-run") update_cask "false" ;;
    esac
}

if [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]]; then
    main "${@}"
fi
