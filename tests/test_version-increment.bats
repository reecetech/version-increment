#!/usr/bin/env bats
# vim: set ft=sh sw=4 :

setup() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../:$PATH"
}

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

    run version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Environment variable 'current_version' is unset or empty"* ]]
}

@test "fails if invalid current_version given" {
    init_repo

    export current_version=1.3.5-prerelease

    run version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Environment variable 'current_version' is not a valid normal version"* ]]
}

@test "fails if invalid scheme given" {
    init_repo

    export scheme="foover"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'scheme' is not valid"* ]]
}

@test "fails if invalid value for pep440 given" {
    init_repo

    export pep440="yes"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'pep440' is not valid"* ]]
}

@test "fails if invalid increment given" {
    init_repo

    export increment="critical"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 8 ] &&
    [[ "$output" = *"Value of 'increment' is not valid, choose from 'major', 'minor', or 'patch'"* ]]
}

@test "no deprecated set-output calls made" {
    run grep -q "::set-output" ../version-increment.sh

    print_run_info
    [ "$status" -eq 1 ]
}

@test "increments the patch digit correctly (semver)" {
    init_repo

    export current_version=1.2.3
    export increment="patch"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"MAJOR_VERSION=1"* ]] &&
    [[ "$output" = *"MINOR_VERSION=2"* ]] &&
    [[ "$output" = *"PATCH_VERSION=4"* ]] &&
    [[ "$output" = *"VERSION=1.2.4"* ]]
}

@test "increments the minor digit correctly (semver)" {
    init_repo

    export current_version=1.2.3
    export increment="minor"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"MAJOR_VERSION=1"* ]] &&
    [[ "$output" = *"MINOR_VERSION=3"* ]] &&
    [[ "$output" = *"PATCH_VERSION=0"* ]] &&
    [[ "$output" = *"VERSION=1.3.0"* ]]
}

@test "increments the minor digit correctly (explicitly not pep440)" {
    init_repo

    export current_version=1.2.3
    export pep404="false"
    export increment="minor"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"MAJOR_VERSION=1"* ]] &&
    [[ "$output" = *"MINOR_VERSION=3"* ]] &&
    [[ "$output" = *"PATCH_VERSION=0"* ]] &&
    [[ "$output" = *"VERSION=1.3.0"* ]]
}

@test "increments the major digit correctly (semver)" {
    init_repo

    export current_version=1.2.3
    export increment="major"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"MAJOR_VERSION=2"* ]] &&
    [[ "$output" = *"MINOR_VERSION=0"* ]] &&
    [[ "$output" = *"PATCH_VERSION=0"* ]] &&
    [[ "$output" = *"VERSION=2.0.0"* ]]
}

@test "increments the major digit correctly (pep440 mode)" {
    init_repo

    export current_version=1.2.3
    export pep404="true"
    export increment="major"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"MAJOR_VERSION=2"* ]] &&
    [[ "$output" = *"MINOR_VERSION=0"* ]] &&
    [[ "$output" = *"PATCH_VERSION=0"* ]] &&
    [[ "$output" = *"VERSION=2.0.0"* ]]
}

@test "prefixes with v" {
    init_repo

    export current_version=1.2.3
    export increment="major"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=2.0.0"* ]] &&
    [[ "$output" = *"MAJOR_V_VERSION=v2"* ]] &&
    [[ "$output" = *"MINOR_V_VERSION=v0"* ]] &&
    [[ "$output" = *"PATCH_V_VERSION=v0"* ]] &&
    [[ "$output" = *"V_VERSION=v2.0.0"* ]]
}

@test "increments to a new month (calver)" {
    init_repo

    export current_version=2020.6.4
    export scheme="calver"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=$(date +%Y.%-m.1)"* ]]
}

@test "increments the patch digit within a month (calver)" {
    init_repo

    export current_version="$(date +%Y.%-m.123)"
    export scheme="calver"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=$(date +%Y.%-m.124)"* ]]
}

@test "appends prerelease information if on a branch" {
    init_repo

    export current_version=1.2.3
    export GITHUB_REF="refs/heads/super-awesome-feature"
    export short_ref="$(git rev-parse --short HEAD | sed 's/0*//')"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"PRE_RELEASE_LABEL=pre.${short_ref}"* ]] &&
    [[ "$output" = *"VERSION=1.2.4-pre.${short_ref}"* ]]
}

@test "does not append prerelease information if on a specified release_branch" {
    init_repo

    export current_version=1.2.3
    export GITHUB_REF="refs/heads/releases"
    export release_branch="releases"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" != *"PRE_RELEASE_LABEL=pre."* ]] &&
    [[ "$output" != *"VERSION=1.2.4-pre."* ]] &&
    [[ "$output" = *"VERSION=1.2.4"* ]]
}

@test "appends prerelease information in pep440 compatible way when pep440 is true" {
    init_repo

    export current_version=10.20.30
    export pep440="true"
    export GITHUB_REF="refs/heads/super-awesome-python"
    export short_ref="$(git rev-parse --short HEAD | sed 's/0*//')"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"PRE_RELEASE_LABEL=pre.${short_ref}"* ]] &&
    [[ "$output" = *"VERSION=10.20.31+pre.${short_ref}"* ]]
}

@test "appends prerelease information in pep440 compatible way when pep440 is true, and using calver scheme" {
    init_repo

    export current_version=2020.6.4
    export scheme="calver"
    export pep440="true"
    export GITHUB_REF="refs/heads/super-awesome-python"
    export short_ref="$(git rev-parse --short HEAD | sed 's/0*//')"

    run version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"PRE_RELEASE_LABEL=pre.${short_ref}"* ]] &&
    [[ "$output" = *"VERSION=$(date +%Y.%-m.1)+pre.${short_ref}"* ]]
}

@test "increments the patch version after a fix commit (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "fix: something" > fix.txt
    git add fix.txt
    git commit -m "fix: something"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=1.2.4"* ]]
    [[ "$output" != *"No conventional commit found"* ]]
}


@test "increments the patch version after a scoped fix commit (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "fix: something" > fix.txt
    git add fix.txt
    git commit -m "fix(api): something"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=1.2.4"* ]]
    [[ "$output" != *"No conventional commit found"* ]]
}

@test "increments the major version after a breaking fix commit (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "fix: breaking something" > fix.txt
    git add fix.txt
    git commit -m "fix!: something"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=2.0.0"* ]]
    [[ "$output" != *"No conventional commit found"* ]]
}

@test "increments the minor version after a feat commit (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "new feature" > feat.txt
    git add feat.txt
    git commit -m "feat: something"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=1.3.0"* ]]
    [[ "$output" != *"No conventional commit found"* ]]
}

@test "increments the major version after a breaking feat commit (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "breaking new feature" > feat.txt
    git add feat.txt
    git commit -m "feat!: something"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=2.0.0"* ]]
    [[ "$output" != *"No conventional commit found"* ]]
}

@test "increments the major version after a breaking change in the commit body (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "breaking new fix" > feat.txt
    git add feat.txt
    git commit -m "Fix: something
    BREAKING CHANGE: really important"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=2.0.0"* ]]
    [[ "$output" != *"No conventional commit found"* ]]
}

@test "increments the patch version by default if no conventional commits found and enabled (conventional commits)" {
    init_repo

    export current_version=1.2.3
    export scheme="conventional_commits"

    echo "some new change" > feat.txt
    git add feat.txt
    git commit -m "new change"

    run ../../version-increment.sh

    print_run_info
    [ "$status" -eq 0 ] &&
    [[ "$output" = *"VERSION=1.2.4"* ]]
    [[ "$output" = *"No conventional commit found"* ]]
}
