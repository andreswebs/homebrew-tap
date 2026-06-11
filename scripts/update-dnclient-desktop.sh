#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

API_URL="https://api.defined.net/v1/downloads"
CASK_FILE="Casks/dnclient-desktop.rb"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo_stderr() {
    echo "${1}" >&2
}

check_dependencies() {
    local missing_deps=()

    for cmd in curl jq shasum git; do
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
    if [[ ! -f "${REPO_ROOT}/${CASK_FILE}" ]]; then
        echo_stderr "error: cask file not found: ${CASK_FILE}"
        exit 1
    fi

    grep 'version "' "${REPO_ROOT}/${CASK_FILE}" | head -1 | sed -E 's/.*version "([^"]+)".*/\1/'
}

has_valid_sha() {
    grep -qE 'sha256 "[0-9a-f]{64}"' "${REPO_ROOT}/${CASK_FILE}"
}

get_downloads_info() {
    local response

    echo_stderr "Checking latest release from Defined Networking API..."

    if ! response=$(curl -fsS "${API_URL}"); then
        echo_stderr "error: failed to fetch release information from ${API_URL}"
        exit 1
    fi

    if ! echo "${response}" | jq -e '.data.versionInfo.latest.dnclient' &> /dev/null; then
        echo_stderr "error: invalid response from API or no version information found"
        exit 1
    fi

    echo "${response}"
}

update_cask() {
    local new_version="${1}"
    local sha256="${2}"

    echo_stderr "Updating cask with version ${new_version}..."

    local cask_path="${REPO_ROOT}/${CASK_FILE}"
    local temp_file

    temp_file=$(mktemp)
    sed -E "s/version \"[^\"]+\"/version \"${new_version}\"/" "${cask_path}" > "${temp_file}"
    mv "${temp_file}" "${cask_path}"

    temp_file=$(mktemp)
    sed -E "s/sha256 \"[0-9a-f]{64}\"/sha256 \"${sha256}\"/" "${cask_path}" > "${temp_file}"
    mv "${temp_file}" "${cask_path}"

    echo_stderr "Cask updated successfully!"
}

main() {
    echo_stderr "Starting dnclient-desktop cask update check..."

    cd "${REPO_ROOT}"

    check_dependencies

    local current_version
    local downloads_info
    local latest_version
    local download_url
    local url_hash
    local new_version

    if ! current_version=$(get_current_version); then
        echo_stderr "failed"
        exit 1
    fi
    echo_stderr "Current version: ${current_version}"

    downloads_info=$(get_downloads_info)
    latest_version=$(echo "${downloads_info}" | jq -r '.data.versionInfo.latest.dnclient')
    download_url=$(echo "${downloads_info}" | jq -r '.data.dnclient.latest["macos-universal-desktop"]')

    if [[ -z "${download_url}" || "${download_url}" == "null" ]]; then
        echo_stderr "error: macOS desktop download URL not found in API response"
        exit 1
    fi

    url_hash=$(echo "${download_url}" | sed -E 's|https://dl\.defined\.net/([0-9a-f]+)/v.*|\1|')
    if [[ ! "${url_hash}" =~ ^[0-9a-f]+$ ]]; then
        echo_stderr "error: failed to extract URL hash from ${download_url}"
        exit 1
    fi

    new_version="${latest_version},${url_hash}"
    echo_stderr "Latest version: ${new_version}"

    if [[ "${current_version}" == "${new_version}" ]] && has_valid_sha; then
        echo_stderr "Cask is already up to date!"
        exit 0
    fi

    if [[ "${current_version}" == "${new_version}" ]]; then
        echo_stderr "Version is current but SHA256 value needs updating..."
    else
        echo_stderr "New version available: ${new_version}"
    fi

    local sha256

    echo_stderr "Downloading DMG to calculate SHA256..."
    if ! sha256=$(curl -fsSL "${download_url}" | shasum -a 256 | cut -d' ' -f1); then
        echo_stderr "error: failed to calculate SHA256 for ${download_url}"
        exit 1
    fi

    update_cask "${new_version}" "${sha256}"

    if git diff --quiet "${CASK_FILE}"; then
        echo_stderr "No changes detected in the cask file"
    else
        echo_stderr "Changes made to ${CASK_FILE}"
        echo_stderr "Review the changes with: git diff ${CASK_FILE}"
        echo_stderr "To commit: git add ${CASK_FILE} && git commit -m \"dnclient-desktop: update to ${latest_version}\""
    fi

    echo_stderr "Update completed successfully!"
}

main
