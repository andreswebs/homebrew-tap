#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

REPO_OWNER="sakajunquality"
REPO_NAME="buildx-telemetry"
FORMULA_FILE="Formula/buildx-telemetry.rb"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo_stderr() {
    echo "${1}" >&2
}

check_dependencies() {
    local missing_deps=()

    for cmd in curl jq git; do
        if ! command -v "${cmd}" &> /dev/null; then
            missing_deps+=("${cmd}")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo_stderr "error: missing required dependencies: ${missing_deps[*]}"
        echo_stderr "Please install them and try again."
        exit 1
    fi
}

get_current_version() {
    if [[ ! -f "${REPO_ROOT}/${FORMULA_FILE}" ]]; then
        echo_stderr "error: formula file not found: ${FORMULA_FILE}"
        exit 1
    fi

    grep -o 'tag:[[:space:]]*"v[0-9]\+\.[0-9]\+\.[0-9]\+"' "${REPO_ROOT}/${FORMULA_FILE}" | head -1 | sed -E 's/.*"v([0-9]+\.[0-9]+\.[0-9]+)".*/\1/'
}

get_latest_release() {
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    local response

    echo_stderr "Checking latest release from GitHub API..."

    if ! response=$(curl -s "${api_url}"); then
        echo_stderr "error: failed to fetch release information from GitHub API"
        exit 1
    fi

    if ! echo "${response}" | jq -e '.tag_name' &> /dev/null; then
        echo_stderr "error: invalid response from GitHub API or no releases found"
        exit 1
    fi

    echo "${response}"
}

update_formula() {
    local new_version="${1}"

    echo_stderr "Updating formula with version ${new_version}..."

    local temp_file
    temp_file=$(mktemp)
    trap 'rm -f "${temp_file}"' EXIT

    # Update the tag version in the formula
    sed "s/tag:[[:space:]]*\"v[0-9]\+\.[0-9]\+\.[0-9]\+\"/tag:      \"v${new_version}\"/" "${REPO_ROOT}/${FORMULA_FILE}" > "${temp_file}"

    # Move the updated content back
    mv "${temp_file}" "${REPO_ROOT}/${FORMULA_FILE}"

    echo_stderr "Formula updated successfully!"
}

main() {
    echo_stderr "Starting Buildx Telemetry formula update check..."

    cd "${REPO_ROOT}"

    check_dependencies

    local current_version
    local latest_release_info
    local latest_version

    current_version=$(get_current_version)
    echo_stderr "Current version: ${current_version}"

    latest_release_info=$(get_latest_release)
    latest_version=$(echo "${latest_release_info}" | jq -r '.tag_name' | sed 's/^v//')
    echo_stderr "Latest version: ${latest_version}"

    if [[ "${current_version}" == "${latest_version}" ]]; then
        echo_stderr "Formula is already up to date!"
        exit 0
    fi

    echo_stderr "New version available: ${latest_version}"

    update_formula "${latest_version}"

    if git diff --quiet "${FORMULA_FILE}"; then
        echo_stderr "No changes detected in the formula file"
    else
        echo_stderr "Changes made to ${FORMULA_FILE}"
        echo_stderr "Review the changes with: git diff ${FORMULA_FILE}"
        echo_stderr "To commit: git add ${FORMULA_FILE} && git commit -m \"buildx-telemetry: update to ${latest_version}\""
    fi

    echo_stderr "Update completed successfully!"
}

main
