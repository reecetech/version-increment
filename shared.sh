#!/bin/bash
# shellcheck disable=SC2034
set -euo pipefail

# Force UTF-8 for all commands, so GIT-Bash on Windows doesn't barf
export LC_ALL=en_GB.UTF-8

##==----------------------------------------------------------------------------
##  SemVer regexes
##  see: https://semver.org/spec/v2.0.0.html#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string

pcre_semver='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
pcre_master_ver='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)$'
pcre_allow_vprefix="^v{0,1}${pcre_master_ver:1}"
pcre_old_calver='^(?P<major>0|[1-9]\d*)-0{0,1}(?P<minor>0|[0-9]\d*)-R(?P<patch>0|[1-9]\d*)$'

##==----------------------------------------------------------------------------
##  Input validation

input_errors='false'
scheme="${scheme:-semver}"
if [[ "${scheme}" != 'semver' && "${scheme}" != 'calver' ]] ; then
    echo "🛑 Value of 'scheme' is not valid, choose from 'semver' or 'calver'" 1>&2
    input_errors='true'
fi

pep440="${pep440:-false}"
if [[ "${pep440}" != 'false' && "${pep440}" != 'true' ]] ; then
    echo "🛑 Value of 'pep440' is not valid, choose from 'false' or 'true'" 1>&2
    input_errors='true'
fi

use_api="${use_api:-false}"
if [[ "${use_api}" != 'false' && "${use_api}" != 'true' ]] ; then
    echo "🛑 Value of 'use_api' is not valid, choose from 'false' or 'true'" 1>&2
    input_errors='true'
fi

if [[ "${use_api}" == 'true' ]] ; then
    if [[ -z "${github_token:-}" ]] ; then
        echo "🛑 'use_api' is true, but environment variable 'github_token' is not set" 1>&2
        input_errors='true'
    fi
fi


##==----------------------------------------------------------------------------
##  MacOS compatibility - for local testing

export grep="grep"
if [[ "$(uname)" == "Darwin" ]] ; then
    export grep="ggrep"
    if ! grep --version 1>/dev/null ; then
        echo "🛑 GNU grep not installed, try brew install coreutils" 1>&2
        exit 9
    fi
fi

##==----------------------------------------------------------------------------
##  Non GitHub compatibility - for testing both locally and in BATS

if [[ -z "${GITHUB_OUTPUT:-}" || -n "${BATS_VERSION:-}" ]] ; then
    export GITHUB_OUTPUT="/dev/stdout"
fi
