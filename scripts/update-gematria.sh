#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

REPO_OWNER="andreswebs"
REPO_NAME="gematria"
FORMULA_FILE="Formula/gematria.rb"
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

    grep 'version "' "${REPO_ROOT}/${FORMULA_FILE}" | head -1 | sed -E 's/.*version "([0-9]+\.[0-9]+\.[0-9]+)".*/\1/'
}

has_valid_shas() {
    local formula_path="${REPO_ROOT}/${FORMULA_FILE}"
    local sha_count
    sha_count=$(grep -cE 'sha256 "[0-9a-f]{64}"' "${formula_path}" || true)
    [[ "${sha_count}" -ge 4 ]]
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

    local formula_path="${REPO_ROOT}/${FORMULA_FILE}"
    local temp_file

    # Update version
    temp_file=$(mktemp)
    sed "s/version \"[0-9]\+\.[0-9]\+\.[0-9]\+\"/version \"${new_version}\"/" "${formula_path}" > "${temp_file}"
    mv "${temp_file}" "${formula_path}"

    # Update SHA256 values in order: darwin-arm64, darwin-amd64, linux-arm64, linux-amd64
    temp_file=$(mktemp)
    awk -v sha1="${darwin_arm64_sha}" \
        -v sha2="${darwin_amd64_sha}" \
        -v sha3="${linux_arm64_sha}" \
        -v sha4="${linux_amd64_sha}" \
    'BEGIN { n=0 }
    /sha256/ {
        n++
        if (n==1) sub(/sha256 ".*"/, "sha256 \"" sha1 "\"")
        else if (n==2) sub(/sha256 ".*"/, "sha256 \"" sha2 "\"")
        else if (n==3) sub(/sha256 ".*"/, "sha256 \"" sha3 "\"")
        else if (n==4) sub(/sha256 ".*"/, "sha256 \"" sha4 "\"")
    }
    { print }' "${formula_path}" > "${temp_file}"
    mv "${temp_file}" "${formula_path}"

    echo_stderr "Formula updated successfully!"
}

main() {
    echo_stderr "Starting Gematria formula update check..."

    cd "${REPO_ROOT}"

    check_dependencies

    local current_version
    local latest_release_info
    local latest_version

    if ! current_version=$(get_current_version); then
        echo_stderr "failed"
        exit 1
    fi
    echo_stderr "Current version: ${current_version}"

    latest_release_info=$(get_latest_release)
    latest_version=$(echo "${latest_release_info}" | jq -r '.tag_name' | sed 's/^v//')
    echo_stderr "Latest version: ${latest_version}"

    if [[ "${current_version}" == "${latest_version}" ]] && has_valid_shas; then
        echo_stderr "Formula is already up to date!"
        exit 0
    fi

    if [[ "${current_version}" == "${latest_version}" ]]; then
        echo_stderr "Version is current but SHA256 values need updating..."
    else
        echo_stderr "New version available: ${latest_version}"
    fi

    local darwin_amd64_sha
    local darwin_arm64_sha
    local linux_amd64_sha
    local linux_arm64_sha

    darwin_amd64_sha=$(get_sha256_from_api "${latest_version}" "gematria-darwin-amd64-v${latest_version}.tar.gz")
    darwin_arm64_sha=$(get_sha256_from_api "${latest_version}" "gematria-darwin-arm64-v${latest_version}.tar.gz")
    linux_amd64_sha=$(get_sha256_from_api "${latest_version}" "gematria-linux-amd64-v${latest_version}.tar.gz")
    linux_arm64_sha=$(get_sha256_from_api "${latest_version}" "gematria-linux-arm64-v${latest_version}.tar.gz")

    update_formula "${latest_version}" "${darwin_amd64_sha}" "${darwin_arm64_sha}" "${linux_amd64_sha}" "${linux_arm64_sha}"

    if git diff --quiet "${FORMULA_FILE}"; then
        echo_stderr "No changes detected in the formula file"
    else
        echo_stderr "Changes made to ${FORMULA_FILE}"
        echo_stderr "Review the changes with: git diff ${FORMULA_FILE}"
        echo_stderr "To commit: git add ${FORMULA_FILE} && git commit -m \"gematria: update to ${latest_version}\""
    fi

    echo_stderr "Update completed successfully!"
}

main
