#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR
# shellcheck source=lib/common.bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/lib/common.bash"

TOTAL_COUNT=0
CHECKED_COUNT=0
CHANGED_COUNT=0
WORK_DIR=""

function check_dependencies() {
    check_commands "awk" "cmp" "curl" "date" "grep" "jq" "mktemp" "realpath" "rm" "shasum" || return 1
    check_gnu_flags "mktemp --directory" "realpath --quiet" "rm --recursive" || return 1
}

function usage() {
    echo_stderr "update-formulae.bash - bump formulae to their latest GitHub release"
    echo_stderr
    echo_stderr "Usage:"
    echo_stderr "  update-formulae.bash [--apply] [<formula> ...]"
    echo_stderr "  update-formulae.bash --help | -h"
    echo_stderr
    echo_stderr "With no formula named, every formula in the formula directory is"
    echo_stderr "checked. The repository, version and release assets are read from"
    echo_stderr "each formula's own url lines, so a new formula needs no change here."
    echo_stderr
    echo_stderr "Options:"
    echo_stderr "  --apply"
    echo_stderr "    Write the changes. Without it, only report what would change."
    echo_stderr
    echo_stderr "  --help, -h"
    echo_stderr "    Show this help"
    echo_stderr
    echo_stderr "Environment:"
    echo_stderr "  GITHUB_TOKEN"
    echo_stderr "    Optional. Sent to the GitHub API to raise the rate limit."
    echo_stderr
    echo_stderr "  UPDATE_FORMULAE_FORMULA_DIR"
    echo_stderr "    Directory holding the formula files. Default: Formula/ beside"
    echo_stderr "    this script's directory."
    echo_stderr
    echo_stderr "  TAP_LOG_LEVEL"
    echo_stderr "    trace, debug, info, warn, error or fatal. Default: info."
    echo_stderr
}

function get_formula_dir() {
    local script_dir
    if ! script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"; then
        log_error "could not resolve the script directory"
        return 1
    fi

    local -r wanted="${UPDATE_FORMULAE_FORMULA_DIR:-${script_dir}/../Formula}"
    # tested here, not left to realpath: implementations disagree on whether
    # a path that does not exist is an error
    if ! [ -e "${wanted}" ]; then
        log_error "formula directory not found: ${wanted}"
        return 1
    fi
    local formula_dir
    if ! formula_dir=$(realpath --quiet "${wanted}"); then
        log_error "could not resolve: ${wanted}"
        return 1
    fi
    if ! [ -d "${formula_dir}" ]; then
        log_error "not a directory: ${formula_dir}"
        return 1
    fi
    echo "${formula_dir}"
}

function rewrite_program() {
    # Plain string replacement throughout: mawk and gawk disagree on brace
    # escapes in regexes, and "#{version}" is full of them.
    cat <<'AWK'
function replace_all(text, from, to,    out, at) {
    out = ""
    while ((at = index(text, from)) > 0) {
        out = out substr(text, 1, at - 1) to
        text = substr(text, at + length(from))
    }
    return out text
}

function quoted(line,    rest) {
    rest = substr(line, index(line, "\"") + 1)
    return substr(rest, 1, index(rest, "\"") - 1)
}

BEGIN {
    placeholder = "#{version}"
    failed = 0
    pending = ""
    if (mode == "rewrite") {
        while ((getline row < digests) > 0) {
            split(row, cell, "\t")
            digest[cell[1]] = cell[2]
        }
    }
}

mode == "rewrite" && /^[ \t]*version "/ {
    sub(/"[^"]*"/, "\"" latest "\"")
}

/^[ \t]*url "/ {
    if (index($0, placeholder) == 0) {
        $0 = replace_all($0, current, latest)
    }
    count = split(replace_all(quoted($0), placeholder, latest), part, "/")
    asset = part[count]
    if (mode == "list") {
        print asset
        next
    }
    if (!(asset in digest)) {
        print "no checksum resolved for " asset > "/dev/stderr"
        failed = 1
        exit
    }
    pending = digest[asset]
}

mode == "rewrite" && pending != "" && /^[ \t]*sha256 "/ {
    sub(/"[^"]*"/, "\"" pending "\"")
    pending = ""
}

mode == "rewrite" {
    print
}

END {
    exit failed
}
AWK
}

function formula_read_source() {
    local -r formula_file="${1:-}"

    if [ -z "${formula_file}" ] || ! [ -f "${formula_file}" ] || ! [ -r "${formula_file}" ]; then
        log_error "formula file not readable: ${formula_file}"
        return 1
    fi

    local -r url_pattern='^[[:space:]]*url[[:space:]]+"([^"]+)"'
    local -r version_pattern='^[[:space:]]*version[[:space:]]+"([^"]+)"'
    local first_url=""
    local declared_version=""
    local line
    while IFS= read -r line; do
        if [ -z "${first_url}" ] && [[ "${line}" =~ ${url_pattern} ]]; then
            first_url="${BASH_REMATCH[1]}"
        fi
        if [ -z "${declared_version}" ] && [[ "${line}" =~ ${version_pattern} ]]; then
            declared_version="${BASH_REMATCH[1]}"
        fi
    done <"${formula_file}"

    # the owner and repository go into an API url, which has no binding
    # mechanism, so the character set is pinned here
    local -r source_pattern='^https://github\.com/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)/releases/download/v?([^/]+)/'
    if ! [[ "${first_url}" =~ ${source_pattern} ]]; then
        log_error "no GitHub release url in ${formula_file##*/}"
        return 1
    fi
    local -r repository="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    local -r current="${declared_version:-${BASH_REMATCH[3]}}"

    if ! is_version "${current}"; then
        log_error "could not read the current version of ${formula_file##*/} (got '${current}')"
        return 1
    fi

    printf '%s\t%s\n' "${repository}" "${current}"
}

function formula_list_assets() {
    local -r formula_file="${1:-}"
    local -r current="${2:-}"
    local -r latest="${3:-}"

    if ! is_version "${current}" || ! is_version "${latest}"; then
        log_error "not a version: '${current}' or '${latest}'"
        return 1
    fi

    local program
    program=$(rewrite_program) || return 1
    # -v, not --assign: the long form is gawk-only and Ubuntu's awk is mawk
    awk -v mode="list" -v current="${current}" -v latest="${latest}" \
        "${program}" "${formula_file}"
}

function formula_rewrite() {
    local -r formula_file="${1:-}"
    local -r current="${2:-}"
    local -r latest="${3:-}"
    local -r digests_file="${4:-}"

    if ! is_version "${current}" || ! is_version "${latest}"; then
        log_error "not a version: '${current}' or '${latest}'"
        return 1
    fi
    if ! [ -f "${digests_file}" ]; then
        log_error "checksum list not found: ${digests_file}"
        return 1
    fi

    local program
    program=$(rewrite_program) || return 1
    awk -v mode="rewrite" -v current="${current}" -v latest="${latest}" \
        -v digests="${digests_file}" "${program}" "${formula_file}"
}

function github_api() {
    local -r endpoint="${1}"
    local headers=(--header "Accept: application/vnd.github+json")
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        headers+=(--header "Authorization: Bearer ${GITHUB_TOKEN}")
    fi
    curl --fail --silent --show-error --location "${headers[@]}" \
        "https://api.github.com/${endpoint}"
}

function release_resolve_digest() {
    local -r release="${1:-}"
    local -r asset="${2:-}"

    if [ -z "${release}" ] || [ -z "${asset}" ]; then
        log_error "a release document and an asset name are required"
        return 1
    fi

    local entry
    if ! entry=$(jq --raw-output --arg name "${asset}" \
        '.assets[] | select(.name == $name) | [.digest // "", .browser_download_url] | @tsv' \
        <<<"${release}" 2>/dev/null); then
        log_error "could not read the asset list of the release"
        return 1
    fi
    if [ -z "${entry}" ]; then
        log_error "asset not found in the release: ${asset}"
        return 1
    fi

    local digest="${entry%%$'\t'*}"
    local -r download_url="${entry#*$'\t'}"
    digest="${digest#sha256:}"

    # releases published before GitHub recorded asset digests have none
    if [ -z "${digest}" ]; then
        log_debug "no published digest for ${asset}, downloading it to hash"
        if ! digest=$(download_sha256 "${download_url}"); then
            log_error "could not download ${asset} to hash it"
            return 1
        fi
    fi

    if ! is_sha256 "${digest}"; then
        log_error "not a sha256 checksum for ${asset}: ${digest}"
        return 1
    fi
    echo "${digest}"
}

function update_formula() {
    local -r formula_file="${1}"
    local -r apply="${2}"
    local -r work_dir="${3}"
    local -r name="${formula_file##*/}"

    local formula_source
    if ! formula_source=$(formula_read_source "${formula_file}"); then
        return 1
    fi
    local -r repository="${formula_source%%$'\t'*}"
    local -r current="${formula_source#*$'\t'}"

    local release
    if ! release=$(github_api "repos/${repository}/releases/latest"); then
        log_error "${name}: could not fetch the latest release of ${repository}"
        return 1
    fi

    local tag
    if ! tag=$(jq --raw-output --exit-status '.tag_name' <<<"${release}"); then
        log_error "${name}: the latest release of ${repository} has no tag"
        return 1
    fi
    local -r latest="${tag#v}"
    if ! is_version "${latest}"; then
        log_error "${name}: unexpected release tag '${tag}'"
        return 1
    fi

    local assets
    if ! assets=$(formula_list_assets "${formula_file}" "${current}" "${latest}"); then
        log_error "${name}: could not list the release assets it uses"
        return 1
    fi

    local -r digests_file="${work_dir}/digests.tsv"
    local -r candidate_file="${work_dir}/candidate.rb"
    : >"${digests_file}"

    local asset
    local digest
    while IFS= read -r asset; do
        [ -z "${asset}" ] && continue
        if ! digest=$(release_resolve_digest "${release}" "${asset}"); then
            log_error "${name}: no checksum for ${asset}"
            return 1
        fi
        printf '%s\t%s\n' "${asset}" "${digest}" >>"${digests_file}"
    done <<<"${assets}"

    if ! formula_rewrite "${formula_file}" "${current}" "${latest}" "${digests_file}" >"${candidate_file}"; then
        log_error "${name}: could not rewrite the formula"
        return 1
    fi

    # -s, not --silent: the long form is GNU-only and macOS ships BSD cmp
    if cmp -s "${candidate_file}" "${formula_file}"; then
        log_info "${name}: up to date (${current})"
        echo "unchanged"
        return 0
    fi

    if [ "${apply}" != "true" ]; then
        log_info "${name}: would update ${current} -> ${latest}"
        echo "changed"
        return 0
    fi

    # written in place rather than moved over, so the file keeps its mode
    if ! cat "${candidate_file}" >"${formula_file}"; then
        log_error "${name}: could not write ${formula_file}"
        return 1
    fi
    log_info "${name}: updated ${current} -> ${latest}"
    echo "changed"
}

function update_formulae() {
    local -r apply="${1}"
    shift
    local -r names=("${@}")

    check_dependencies || return 1

    local formula_dir
    formula_dir=$(get_formula_dir) || return 1

    local formula_files=()
    if [ "${#names[@]}" -gt 0 ]; then
        local name
        for name in "${names[@]}"; do
            formula_files+=("${formula_dir}/${name%.rb}.rb")
        done
    else
        local found_file
        for found_file in "${formula_dir}"/*.rb; do
            [ -f "${found_file}" ] || continue
            formula_files+=("${found_file}")
        done
    fi
    if [ "${#formula_files[@]}" -eq 0 ]; then
        log_error "no formulae found in ${formula_dir}"
        return 1
    fi

    WORK_DIR=$(mktemp --directory) || return 1
    trap 'rm --recursive --force "${WORK_DIR}"' EXIT

    TOTAL_COUNT="${#formula_files[@]}"
    local failed_formulae=()
    local formula_file
    local outcome
    for formula_file in "${formula_files[@]}"; do
        if ! outcome=$(update_formula "${formula_file}" "${apply}" "${WORK_DIR}"); then
            failed_formulae+=("${formula_file##*/}")
            continue
        fi
        CHECKED_COUNT=$((CHECKED_COUNT + 1))
        if [ "${outcome}" = "changed" ]; then
            CHANGED_COUNT=$((CHANGED_COUNT + 1))
        fi
    done

    local verb="would change"
    if [ "${apply}" = "true" ]; then
        verb="changed"
    fi
    log_info "checked ${CHECKED_COUNT} of ${TOTAL_COUNT}, ${verb} ${CHANGED_COUNT}"
    if [ "${apply}" != "true" ] && [ "${CHANGED_COUNT}" -gt 0 ]; then
        log_info "run again with --apply to write the changes"
    fi

    if [ "${#failed_formulae[@]}" -gt 0 ]; then
        log_error "failed:"
        local failed_name
        for failed_name in "${failed_formulae[@]}"; do
            log_error "  - ${failed_name}"
        done
        return 1
    fi
}

function shutdown() {
    local -r signal="${1}"

    log_warn "received ${signal} after ${CHECKED_COUNT} of ${TOTAL_COUNT} formulae checked, ${CHANGED_COUNT} changed"

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
            formulae+=("${key}")
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
    local formulae=()
    parse_arguments "${@}"

    trap 'shutdown SIGINT' SIGINT
    trap 'shutdown SIGTERM' SIGTERM

    case "${action}" in
    "apply") update_formulae "true" "${formulae[@]}" ;;
    "dry-run") update_formulae "false" "${formulae[@]}" ;;
    esac
}

if [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]]; then
    main "${@}"
fi
