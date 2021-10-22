#!/usr/bin/env bats
# vim: set ft=sh sw=4 :

load helper_print-info

export repo=".tmp_testing/repo"

function init_repo {
    rm -rf "${repo}" &&
    mkdir -p "${repo}" &&
    cd "${repo}" &&
    git init &&
    git checkout -b main &&
    touch README.md &&
    git add README.md &&
    git config user.email test@example.com &&
    git config user.name Tester &&
    git commit -m "README" &&
    export GITHUB_REF="refs/heads/main"
}

@test "fails if no current_version given" {
    init_repo

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Environment variable 'current_version' is unset or empty"* ]]
}

@test "fails if invalid current_version given" {
    init_repo

    export current_version=1.3.5-prerelease

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Environment variable 'current_version' is not a valid normal version"* ]]
}

@test "fails if invalid scheme given" {
    init_repo

    export scheme="foover"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'scheme' is not valid"* ]]
}

@test "fails if invalid increment given" {
    init_repo

    export increment="critical"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'increment' is not valid, choose from 'major', 'minor', or 'patch'"* ]]
}

@test "increments the patch digit correctly (semver)" {
    init_repo

    export current_version=1.2.3
    export increment="patch"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=version::1.2.4"* ]]
}

@test "increments the minor digit correctly (semver)" {
    init_repo

    export current_version=1.2.3
    export increment="minor"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=version::1.3.0"* ]]
}

@test "increments the major digit correctly (semver)" {
    init_repo

    export current_version=1.2.3
    export increment="major"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=version::2.0.0"* ]]
}

@test "increments to a new month (calver)" {
    init_repo

    export current_version=2020.6.4
    export scheme="calver"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=version::$(date +%Y.%-m.1)"* ]]
}

@test "increments the patch digit within a month (calver)" {
    init_repo

    export current_version="$(date +%Y.%-m.123)"
    export scheme="calver"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=version::$(date +%Y.%-m.124)"* ]]
}

@test "appends prerelease information if on a branch" {
    init_repo

    export current_version=1.2.3
    export GITHUB_REF="refs/heads/super-awesome-feature"
    export short_ref="$(git rev-parse --short HEAD | sed 's/0*//')"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"::set-output name=version::1.2.4-pre.${short_ref}"* ]]
}
