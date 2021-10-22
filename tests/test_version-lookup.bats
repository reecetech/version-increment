#!/usr/bin/env bats
# vim: set ft=sh sw=4 :

load helper_print-info

export repo=".tmp_testing/repo"

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

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'scheme' is not valid"* ]]
}

@test "finds the current normal version" {
    init_repo

    git tag 0.0.1
    git tag 0.1.1
    git tag 0.1.2

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::0.1.2"* ]]
}

@test "finds the current normal version even if there's a newer pre-release version" {
    init_repo

    git tag 1.2.300
    git tag 1.2.301-dev.234

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::1.2.300"* ]]
}

@test "returns 0.0.0 if no normal version detected" {
    init_repo

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::0.0.0"* ]]
}

@test "returns 0.0.0 if no normal version detected even if there's a pre-release version" {
    init_repo

    git tag 0.0.1-dev.999

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::0.0.0"* ]]
}

@test "returns a calver if no normal version detected and calver scheme specified" {
    init_repo

    export scheme="calver"

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::$(date '+%Y.%-m.0')"* ]]
}

@test "converts from older calver scheme automatically" {
    init_repo

    git tag 2020-09-R2

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::2020.9.2"* ]]
}

@test "strips v from the version" {
    init_repo

    git tag v3.4.5

    run ../../version-lookup.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=current-version::3.4.5"* ]]
}
