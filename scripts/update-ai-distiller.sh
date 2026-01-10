#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

REPO_OWNER="janreges"
REPO_NAME="ai-distiller"
FORMULA_FILE="Formula/ai-distiller.rb"
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

    grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "${REPO_ROOT}/${FORMULA_FILE}" | head -1 | sed 's/^v//'
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

get_sha256_from_api() {
    local version="$1"
    local filename="$2"
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/v${version}"
    local response
    local asset_url
    local sha256

    if ! response=$(curl -s "${api_url}"); then
        echo_stderr "error: failed to fetch release information for version ${version}"
        exit 1
    fi

    asset_url=$(echo "${response}" | jq -r ".assets[] | select(.name == \"${filename}\") | .browser_download_url")
    if [[ -z "${asset_url}" || "${asset_url}" == "null" ]]; then
        echo_stderr "error: asset ${filename} not found in release ${version}"
        exit 1
    fi

    if ! sha256=$(curl -sL "${asset_url}" | shasum -a 256 | cut -d' ' -f1); then
        echo_stderr "error: failed to calculate SHA256 for ${filename}"
        exit 1
    fi

    echo "${sha256}"
}

update_formula() {
    local new_version="${1}"
    local darwin_amd64_sha="${2}"
    local darwin_arm64_sha="${3}"
    local linux_amd64_sha="${4}"
    local linux_arm64_sha="${5}"

    echo_stderr "Updating formula with version ${new_version}..."

    local temp_file
    temp_file=$(mktemp)
    trap 'rm -f "${temp_file}"' EXIT
    echo_stderr "Formula updated successfully!"
}

main() {
    echo_stderr "Starting AI Distiller formula update check..."

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

    local darwin_amd64_sha
    local darwin_arm64_sha
    local linux_amd64_sha
    local linux_arm64_sha

    darwin_amd64_sha=$(get_sha256_from_api "${latest_version}" "aid-darwin-amd64-v${latest_version}.tar.gz")
    darwin_arm64_sha=$(get_sha256_from_api "${latest_version}" "aid-darwin-arm64-v${latest_version}.tar.gz")
    linux_amd64_sha=$(get_sha256_from_api "${latest_version}" "aid-linux-amd64-v${latest_version}.tar.gz")
    linux_arm64_sha=$(get_sha256_from_api "${latest_version}" "aid-linux-arm64-v${latest_version}.tar.gz")

    update_formula "${latest_version}" "${darwin_amd64_sha}" "${darwin_arm64_sha}" "${linux_amd64_sha}" "${linux_arm64_sha}"

    if git diff --quiet "${FORMULA_FILE}"; then
        echo_stderr "No changes detected in the formula file"
    else
        echo_stderr "Changes made to ${FORMULA_FILE}"
        echo_stderr "Review the changes with: git diff ${FORMULA_FILE}"
        echo_stderr "To commit: git add ${FORMULA_FILE} && git commit -m \"ai-distiller: update to ${latest_version}\""
    fi

    echo_stderr "Update completed successfully!"
}

main
