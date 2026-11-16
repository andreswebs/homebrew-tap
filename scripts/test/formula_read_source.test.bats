#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load '../update-formulae.bash'

function write_formula() {
    printf '%s\n' "${@}" >"${BATS_TEST_TMPDIR}/sample.rb"
}

@test "formula_read_source: version line and templated url" {
    write_formula \
        'class Sample < Formula' \
        '  version "1.2.3"' \
        '  on_macos do' \
        '    url "https://github.com/owner/sample/releases/download/v#{version}/sample-darwin-arm64-v#{version}.tar.gz"' \
        '  end' \
        'end'

    run --separate-stderr formula_read_source "${BATS_TEST_TMPDIR}/sample.rb"
    [ "${status}" -eq 0 ]
    [ "${output}" = "owner/sample"$'\t'"1.2.3" ]
}

@test "formula_read_source: version taken from a literal url" {
    write_formula \
        'class Sample < Formula' \
        '  url "https://github.com/owner/sample/releases/download/0.2.0/sample-0.2.0.tar.gz"' \
        'end'

    run --separate-stderr formula_read_source "${BATS_TEST_TMPDIR}/sample.rb"
    [ "${status}" -eq 0 ]
    [ "${output}" = "owner/sample"$'\t'"0.2.0" ]
}

@test "formula_read_source: missing file" {
    run --separate-stderr formula_read_source "${BATS_TEST_TMPDIR}/absent.rb"
    [ "${status}" -ne 0 ]
    [ -z "${output}" ]
}

@test "formula_read_source: no argument" {
    run --separate-stderr formula_read_source
    [ "${status}" -ne 0 ]
}

@test "formula_read_source: url that is not a GitHub release" {
    write_formula 'class Sample < Formula' '  url "https://example.com/sample-1.0.tar.gz"' 'end'

    run --separate-stderr formula_read_source "${BATS_TEST_TMPDIR}/sample.rb"
    [ "${status}" -ne 0 ]
}

@test "formula_read_source: version that is not numeric" {
    write_formula \
        'class Sample < Formula' \
        '  version "latest"' \
        '  url "https://github.com/owner/sample/releases/download/v#{version}/sample.tar.gz"' \
        'end'

    run --separate-stderr formula_read_source "${BATS_TEST_TMPDIR}/sample.rb"
    [ "${status}" -ne 0 ]
}

@test "formula_read_source: rejects repository names with unsafe characters" {
    # shellcheck disable=SC2016
    local unsafe_owners=(
        '$(touch pwned)'
        '`touch pwned`'
        'a;b'
        'a|b'
        'a b'
        'a?b'
    )

    local unsafe_owner
    for unsafe_owner in "${unsafe_owners[@]}"; do
        write_formula "  url \"https://github.com/${unsafe_owner}/sample/releases/download/v1.0.0/sample.tar.gz\""
        run --separate-stderr formula_read_source "${BATS_TEST_TMPDIR}/sample.rb"
        [ "${status}" -ne 0 ]
    done
}
