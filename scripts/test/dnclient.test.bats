#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../update-dnclient-desktop.bash'

readonly OLD_SHA="1111111111111111111111111111111111111111111111111111111111111111"
readonly NEW_SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

setup() {
    CASK="${BATS_TEST_TMPDIR}/dnclient-desktop.rb"
    printf '%s\n' \
        'cask "dnclient-desktop" do' \
        '  version "0.9.7,56c0d31f"' \
        "  sha256 \"${OLD_SHA}\"" \
        '' \
        '  url "https://dl.defined.net/#{version.csv.second}/v#{version.csv.first}/macos/DNClient-Desktop.dmg"' \
        'end' >"${CASK}"
}

function downloads_with() {
    local -r version="${1}"
    local -r download_url="${2}"
    jq --null-input --compact-output --arg version "${version}" --arg url "${download_url}" \
        '{data: {versionInfo: {latest: {dnclient: $version}}, dnclient: {latest: {"macos-universal-desktop": $url}}}}'
}

@test "cask_read_field: version and sha256" {
    run --separate-stderr cask_read_field "${CASK}" "version"
    [ "${status}" -eq 0 ]
    [ "${output}" = "0.9.7,56c0d31f" ]

    run --separate-stderr cask_read_field "${CASK}" "sha256"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${OLD_SHA}" ]
}

@test "cask_read_field: unsupported field, missing file" {
    run --separate-stderr cask_read_field "${CASK}" "url"
    [ "${status}" -ne 0 ]

    run --separate-stderr cask_read_field "${BATS_TEST_TMPDIR}/absent.rb" "version"
    [ "${status}" -ne 0 ]
}

@test "downloads_read_latest: version, url hash and url" {
    local -r url="https://dl.defined.net/837870e1/v1.0.0/macos/DNClient-Desktop.dmg"
    run --separate-stderr downloads_read_latest "$(downloads_with "1.0.0" "${url}")"
    [ "${status}" -eq 0 ]
    [ "${output}" = "1.0.0,837870e1"$'\t'"${url}" ]
}

@test "downloads_read_latest: missing release, bad JSON, no argument" {
    run --separate-stderr downloads_read_latest '{"data":{}}'
    [ "${status}" -ne 0 ]

    run --separate-stderr downloads_read_latest "not json"
    [ "${status}" -ne 0 ]

    run --separate-stderr downloads_read_latest
    [ "${status}" -ne 0 ]
}

@test "downloads_read_latest: rejects urls off the expected host or shape" {
    # shellcheck disable=SC2016
    local unsafe_urls=(
        'https://evil.example/837870e1/v1.0.0/macos/DNClient-Desktop.dmg'
        'http://dl.defined.net/837870e1/v1.0.0/macos/DNClient-Desktop.dmg'
        'https://dl.defined.net/837870e1/v1.0.0/macos/$(touch pwned).dmg'
        'https://dl.defined.net/837870e1/v1.0.0/macos/a.dmg;echo x'
        'https://dl.defined.net/../v1.0.0/macos/DNClient-Desktop.dmg'
        'file:///etc/passwd'
    )

    local unsafe_url
    for unsafe_url in "${unsafe_urls[@]}"; do
        run --separate-stderr downloads_read_latest "$(downloads_with "1.0.0" "${unsafe_url}")"
        [ "${status}" -ne 0 ]
    done
}

@test "cask_rewrite: replaces version and checksum, nothing else" {
    run --separate-stderr cask_rewrite "${CASK}" "1.0.0,837870e1" "${NEW_SHA}"
    [ "${status}" -eq 0 ]
    [ "${lines[1]}" = '  version "1.0.0,837870e1"' ]
    [ "${lines[2]}" = "  sha256 \"${NEW_SHA}\"" ]
    [ "${lines[3]}" = '  url "https://dl.defined.net/#{version.csv.second}/v#{version.csv.first}/macos/DNClient-Desktop.dmg"' ]
}

@test "cask_rewrite: rejects a malformed version or checksum" {
    run --separate-stderr cask_rewrite "${CASK}" "1.0.0" "${NEW_SHA}"
    [ "${status}" -ne 0 ]

    run --separate-stderr cask_rewrite "${CASK}" "1.0.0,837870e1" "nothex"
    [ "${status}" -ne 0 ]

    # shellcheck disable=SC2016
    run --separate-stderr cask_rewrite "${CASK}" '1.0.0,$(touch pwned)' "${NEW_SHA}"
    [ "${status}" -ne 0 ]
}
