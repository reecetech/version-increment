#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# shellcheck source=shared.sh
source "${script_dir}/shared.sh"

if [[ "${input_errors}" == 'true' ]] ; then
    exit 8
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
##  Get tags from GitHub repo

# Skip if testing, otherwise pull tags
if [[ -z "${BATS_VERSION:-}" ]] ; then
    git fetch --quiet --force origin 'refs/tags/*:refs/tags/*'
fi

##==----------------------------------------------------------------------------
##  Version parsing

# detect current version - removing "v" from start of tag if it exists
current_version="$(git tag -l | { ${grep} -P "${pcre_allow_vprefix}" || true; } | sed 's/^v//g' | sort -V | tail -n 1)"

# support transition from an old reecetech calver style (yyyy-mm-Rr, where R is the literal `R`, and r is the nth release for the month)
if [[ -z "${current_version:-}" ]] ; then
    current_version="$(git tag -l | { ${grep} -P "${pcre_old_calver}" || true; } | sort -V | tail -n 1)"
    if [[ -n "${current_version:-}" ]] ; then
        # convert - to . and drop leading zeros & the R
        current_version="$(echo "${current_version}" | sed -r 's/^([0-9]+)-0{0,1}([0-9]+)-R0{0,1}([0-9]+)$/\1.\2.\3/')"
    fi
fi

# handle no version detected - start versioning!
if [[ -z "${current_version:-}" ]] ; then
    echo "⚠️ No previous release version identified in git tags"
    # brand new repo! (probably)
    case "${scheme}" in
        semver)
            current_version="0.0.0"
        ;;
        calver)
            current_version="$(date '+%Y.%-m.0')"
        ;;
    esac
fi

echo "ℹ️ The current normal version is ${current_version}"

echo "CURRENT_VERSION=${current_version}" >> "${GITHUB_OUTPUT}"
echo "CURRENT_V_VERSION=v${current_version}" >> "${GITHUB_OUTPUT}"
