#!/usr/bin/env bats
# vim: set ft=sh sw=4 :

load helper_print-info

export repo=".tmp_testing/repo"

setup() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../:$PATH"
}

function init_repo {
    rm -rf "${repo}" &&
    mkdir -p "${repo}" &&
    cd "${repo}" &&
    git init &&
    touch README.md &&
    git add README.md &&
    git config user.email test@example.com &&
    git config user.name Tester &&
    git commit -m "README"
}

@test "fails if invalid scheme given" {
    init_repo

    export scheme="foover"

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'scheme' is not valid"* ]]
}

@test "no deprecated set-output calls made" {
    run grep -q "::set-output" ../version-lookup.sh

    print_run_info
    [ "$status" -eq 1 ]
}

@test "finds the current normal version" {
    init_repo

    git tag 0.0.1
    git tag 0.1.1
    git tag 0.1.2

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=0.1.2"* ]]
}

@test "prefixes with a v" {
    init_repo

    git tag 0.1.2

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=0.1.2"* ]] &&
    [[ "$output" = *"CURRENT_V_VERSION=v0.1.2"* ]]
}

@test "finds the current normal version even if there's a newer pre-release version" {
    init_repo

    git tag 1.2.300
    git tag 1.2.301-dev.234

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=1.2.300"* ]]
}

@test "returns 0.0.0 if no normal version detected" {
    init_repo

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=0.0.0"* ]]
}

@test "returns 0.0.0 if no normal version detected even if there's a pre-release version" {
    init_repo

    git tag 0.0.1-dev.999

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=0.0.0"* ]]
}

@test "returns a calver if no normal version detected and calver scheme specified" {
    init_repo

    export scheme="calver"

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=$(date '+%Y.%-m.0')"* ]]
}

@test "strips v from the version" {
    init_repo

    git tag v3.4.5

    run version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"CURRENT_VERSION=3.4.5"* ]]
}
