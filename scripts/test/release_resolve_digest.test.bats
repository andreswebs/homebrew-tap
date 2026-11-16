#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../update-formulae.bash'

readonly DIGEST="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

function release_with() {
    local -r digest_json="${1}"
    jq --null-input --compact-output --argjson digest "${digest_json}" \
        '{tag_name: "v1.0.0", assets: [{name: "sample.tar.gz", digest: $digest, browser_download_url: "https://example.invalid/sample.tar.gz"}]}'
}

@test "release_resolve_digest: published digest" {
    run --separate-stderr release_resolve_digest "$(release_with "\"sha256:${DIGEST}\"")" "sample.tar.gz"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${DIGEST}" ]
}

@test "release_resolve_digest: asset not in the release" {
    run --separate-stderr release_resolve_digest "$(release_with "\"sha256:${DIGEST}\"")" "other.tar.gz"
    [ "${status}" -ne 0 ]
    [ -z "${output}" ]
}

@test "release_resolve_digest: digest that is not sha256" {
    run --separate-stderr release_resolve_digest "$(release_with '"sha512:abcdef"')" "sample.tar.gz"
    [ "${status}" -ne 0 ]
}

@test "release_resolve_digest: document that is not JSON" {
    run --separate-stderr release_resolve_digest "not json" "sample.tar.gz"
    [ "${status}" -ne 0 ]
}

@test "release_resolve_digest: missing arguments" {
    run --separate-stderr release_resolve_digest
    [ "${status}" -ne 0 ]
}

@test "release_resolve_digest: asset names are data, not jq source" {
    # shellcheck disable=SC2016
    local unsafe_names=(
        '") | halt_error'
        '$name'
        '$(touch pwned)'
        '`touch pwned`'
        '*'
    )

    local unsafe_name
    for unsafe_name in "${unsafe_names[@]}"; do
        run --separate-stderr release_resolve_digest "$(release_with "\"sha256:${DIGEST}\"")" "${unsafe_name}"
        [ "${status}" -ne 0 ]
    done
}
