#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function echo_stderr() {
    echo "${*}" >&2
}

function step() {
    echo_stderr ""
    echo_stderr "==> ${1}"
}

function main() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    local scripts_dir
    scripts_dir="$(cd "${script_dir}/.." >/dev/null 2>&1 && pwd)"

    local missing=()
    local cmd
    for cmd in shfmt shellcheck bats; do
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${cmd}")
        fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        echo_stderr "missing required commands: ${missing[*]}"
        return 1
    fi

    local -r sources=(
        "${scripts_dir}"/*.bash
        "${scripts_dir}"/lib/*.bash
        "${script_dir}"/*.bash
    )

    step "shfmt (format check)"
    if [ "${WRITE:-false}" = "true" ]; then
        shfmt --indent 4 --write "${sources[@]}" "${script_dir}"/*.bats
    else
        shfmt --indent 4 --diff "${sources[@]}" "${script_dir}"/*.bats
    fi

    step "shellcheck (lint)"
    shellcheck --external-sources "${sources[@]}" "${script_dir}"/*.bats

    step "bats (tests)"
    bats "${script_dir}"

    echo_stderr ""
    echo_stderr "All checks passed."
}

if [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]]; then
    main "${@}"
fi
