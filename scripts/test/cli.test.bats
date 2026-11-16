#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
    FORMULAE="${BATS_TEST_DIRNAME}/../update-formulae.bash"
    DNCLIENT="${BATS_TEST_DIRNAME}/../update-dnclient-desktop.bash"
    mkdir -p "${BATS_TEST_TMPDIR}/Formula"
    export UPDATE_FORMULAE_FORMULA_DIR="${BATS_TEST_TMPDIR}/Formula"
}

@test "cli: update-formulae --help" {
    run "${FORMULAE}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"--apply"* ]]
}

@test "cli: update-formulae rejects an unknown option" {
    run "${FORMULAE}" --aply
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"invalid option: --aply"* ]]
}

@test "cli: update-formulae reports an unknown formula as failed" {
    run "${FORMULAE}" nosuch
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"checked 0 of 1"* ]]
    [[ "${output}" == *"- nosuch.rb"* ]]
}

@test "cli: update-formulae with an empty formula directory" {
    run "${FORMULAE}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"no formulae found"* ]]
}

@test "cli: update-formulae with a formula directory that does not exist" {
    UPDATE_FORMULAE_FORMULA_DIR="${BATS_TEST_TMPDIR}/absent" run "${FORMULAE}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"formula directory not found"* ]]
}

@test "cli: update-dnclient-desktop --help" {
    run "${DNCLIENT}" --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"--apply"* ]]
}

@test "cli: update-dnclient-desktop rejects unknown options and arguments" {
    run "${DNCLIENT}" --aply
    [ "${status}" -eq 1 ]

    run "${DNCLIENT}" extra
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"invalid argument: extra"* ]]
}

@test "cli: update-dnclient-desktop with a cask file that does not exist" {
    UPDATE_DNCLIENT_CASK_FILE="${BATS_TEST_TMPDIR}/absent.rb" run "${DNCLIENT}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"cask file not found"* ]]
}
