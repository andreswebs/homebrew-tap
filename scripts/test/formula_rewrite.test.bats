#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../update-formulae.bash'

readonly OLD_ARM="1111111111111111111111111111111111111111111111111111111111111111"
readonly OLD_INTEL="2222222222222222222222222222222222222222222222222222222222222222"
readonly NEW_ARM="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
readonly NEW_INTEL="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

setup() {
    FORMULA="${BATS_TEST_TMPDIR}/sample.rb"
    DIGESTS="${BATS_TEST_TMPDIR}/digests.tsv"

    printf '%s\n' \
        'class Sample < Formula' \
        '  version "1.0.0"' \
        '  on_arm do' \
        '    url "https://github.com/owner/sample/releases/download/v#{version}/sample-arm64-v#{version}.tar.gz"' \
        "    sha256 \"${OLD_ARM}\"" \
        '  end' \
        '  on_intel do' \
        '    url "https://github.com/owner/sample/releases/download/v#{version}/sample-amd64-v#{version}.tar.gz"' \
        "    sha256 \"${OLD_INTEL}\"" \
        '  end' \
        'end' >"${FORMULA}"

    # deliberately not in file order: checksums are matched by asset name
    printf '%s\t%s\n' \
        "sample-amd64-v1.1.0.tar.gz" "${NEW_INTEL}" \
        "sample-arm64-v1.1.0.tar.gz" "${NEW_ARM}" >"${DIGESTS}"
}

@test "formula_list_assets: names the assets of the new version" {
    run --separate-stderr formula_list_assets "${FORMULA}" "1.0.0" "1.1.0"
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" = "sample-arm64-v1.1.0.tar.gz" ]
    [ "${lines[1]}" = "sample-amd64-v1.1.0.tar.gz" ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "formula_list_assets: rejects a version that is not numeric" {
    # shellcheck disable=SC2016
    run --separate-stderr formula_list_assets "${FORMULA}" "1.0.0" '$(touch pwned)'
    [ "${status}" -ne 0 ]
}

@test "formula_rewrite: bumps the version and pairs each checksum with its url" {
    run --separate-stderr formula_rewrite "${FORMULA}" "1.0.0" "1.1.0" "${DIGESTS}"
    [ "${status}" -eq 0 ]
    [ "${lines[1]}" = '  version "1.1.0"' ]
    [ "${lines[4]}" = "    sha256 \"${NEW_ARM}\"" ]
    [ "${lines[8]}" = "    sha256 \"${NEW_INTEL}\"" ]
    [ "${#lines[@]}" -eq 11 ]
}

@test "formula_rewrite: same version and checksums is a no-op" {
    printf '%s\t%s\n' \
        "sample-arm64-v1.0.0.tar.gz" "${OLD_ARM}" \
        "sample-amd64-v1.0.0.tar.gz" "${OLD_INTEL}" >"${DIGESTS}"

    formula_rewrite "${FORMULA}" "1.0.0" "1.0.0" "${DIGESTS}" >"${BATS_TEST_TMPDIR}/out.rb"
    run cmp -s "${BATS_TEST_TMPDIR}/out.rb" "${FORMULA}"
    [ "${status}" -eq 0 ]
}

@test "formula_rewrite: rewrites a literal version inside the url" {
    printf '%s\n' \
        'class Sample < Formula' \
        '  url "https://github.com/owner/sample/releases/download/0.2.0/sample-0.2.0.tar.gz"' \
        "  sha256 \"${OLD_ARM}\"" \
        'end' >"${FORMULA}"
    printf '%s\t%s\n' "sample-0.3.0.tar.gz" "${NEW_ARM}" >"${DIGESTS}"

    run --separate-stderr formula_rewrite "${FORMULA}" "0.2.0" "0.3.0" "${DIGESTS}"
    [ "${status}" -eq 0 ]
    [ "${lines[1]}" = '  url "https://github.com/owner/sample/releases/download/0.3.0/sample-0.3.0.tar.gz"' ]
    [ "${lines[2]}" = "  sha256 \"${NEW_ARM}\"" ]
}

@test "formula_rewrite: fails when an asset has no checksum" {
    printf '%s\t%s\n' "sample-arm64-v1.1.0.tar.gz" "${NEW_ARM}" >"${DIGESTS}"

    run --separate-stderr formula_rewrite "${FORMULA}" "1.0.0" "1.1.0" "${DIGESTS}"
    [ "${status}" -ne 0 ]
}

@test "formula_rewrite: fails when the checksum list is absent" {
    run --separate-stderr formula_rewrite "${FORMULA}" "1.0.0" "1.1.0" "${BATS_TEST_TMPDIR}/absent.tsv"
    [ "${status}" -ne 0 ]
}
