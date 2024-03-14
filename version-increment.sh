#!/bin/bash
set -euo pipefail

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# shellcheck source=shared.sh
source "${script_dir}/shared.sh"

increment="${increment:-patch}"
if [[ "${increment}" != 'patch' && "${increment}" != 'minor' && "${increment}" != 'major' ]] ; then
    echo "🛑 Value of 'increment' is not valid, choose from 'major', 'minor', or 'patch'" 1>&2
    input_errors='true'
fi

echo "ℹ️ INCREMENTER: The current normal version is ${current_version}"

if [[ -z "${current_version:-}" ]] ; then
    echo "🛑 Environment variable 'current_version' is unset or empty" 1>&2
    input_errors='true'
elif [[ -z "$(echo "${current_version}" | ${grep} -P "${pcre_master_ver}")" ]] ; then
    echo "🛑 Environment variable 'current_version' is not a valid normal version (M.m.p)" 1>&2
    input_errors='true'
fi

if [[ "${input_errors}" == 'true' ]] ; then
    exit 8
fi

##==----------------------------------------------------------------------------
##  Git info - branch names, commit short ref

default_branch='main'
# use release_branch if not empty
if [[ -n "${release_branch:-}" ]] ; then
    default_branch="${release_branch}" 
elif [[ -z "${BATS_VERSION:-}" ]] ; then
    # if we're _not_ testing, then _actually_ check the origin
    if [[ "${use_api:-}" == 'true' ]] ; then
        default_branch="$(
            curl -fsSL \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: Bearer ${github_token}" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}" \
            | jq -r '.default_branch'
        )"
    else
        default_branch="$(git remote show origin | ${grep} 'HEAD branch' | cut -d ' ' -f 5)"
    fi
fi

current_ref="${GITHUB_REF:-}"

if [[ "${use_api:-}" == 'true' ]] ; then
    # because we cannot use `rev-parse` with the API, we'll take a punt that 9 characters is enough for uniqueness
    # shellcheck disable=SC2001
    git_commit="$(echo "${GITHUB_SHA:0:9}" | sed 's/0*//')"    # Also, trim leading zeros, because semver doesn't allow that in
else                                                           # the 'pre-release version' part, but we can't use the + char
    git_commit="$(git rev-parse --short HEAD | sed 's/0*//')"  # to make it 'build metadata' as that's not supported in K8s
fi                                                             # labels

##==----------------------------------------------------------------------------
##  Version increment

# increment the month if needed
if [[ "${scheme}" == "calver" ]] ; then
    month="$(date '+%Y.%-m.')"
    release="${current_version//$month/}"
    if [[ "${release}" == "${current_version}" ]] ; then
        current_version="$(date '+%Y.%-m.0')"
    fi
fi

# increment the patch digit
IFS=" " read -r -a version_array <<< "${current_version//./ }"
if [[ "${increment}" == 'patch' || "${scheme}" == 'calver' ]] ; then
    (( ++version_array[2] ))
elif [[ "${increment}" == 'minor' ]] ; then
    (( ++version_array[1] ))
    version_array[2]='0'
elif [[ "${increment}" == 'major' ]] ; then
    (( ++version_array[0] ))
    version_array[1]='0'
    version_array[2]='0'
fi

new_version="${version_array[0]}.${version_array[1]}.${version_array[2]}"

# check we haven't accidentally forgotten to set scheme to calver
# TODO: provide an override "I know my version numbers are > 2020, but it's semver!" option
if [[ "${version_array[0]}" -gt 2020 && "${scheme}" != "calver" ]] ; then
    echo "🛑 The major version number is greater than 2020, but the scheme is not set to 'calver'" 1>&2
    exit 11
fi

# add pre-release info to version if not the default branch
if [[ "${current_ref}" != "refs/heads/${default_branch}" ]] ; then
    pre_release="pre.${git_commit}"
    if [[ "${pep440:-}" == 'true' ]] ; then
        new_version="${new_version}+${pre_release}"
    else
        new_version="${new_version}-${pre_release}"
    fi
    echo "PRE_RELEASE_LABEL=${pre_release}" >> "${GITHUB_OUTPUT}"
fi

if [[ -z "$(echo "${new_version}" | ${grep} -P "${pcre_semver}")" ]] ; then
    echo "🛑 Version incrementing has failed to produce a semver compliant version" 1>&2
    echo "ℹ️ See: https://semver.org/spec/v2.0.0.html" 1>&2
    echo "ℹ️ Failed version string: '${new_version}'" 1>&2
    exit 12
fi

echo "ℹ️ The new version is ${new_version}"

# shellcheck disable=SC2129
echo "VERSION=${new_version}" >> "${GITHUB_OUTPUT}"
echo "V_VERSION=v${new_version}" >> "${GITHUB_OUTPUT}"
echo "MAJOR_VERSION=${version_array[0]}" >> "${GITHUB_OUTPUT}"
echo "MINOR_VERSION=${version_array[1]}" >> "${GITHUB_OUTPUT}"
echo "PATCH_VERSION=${version_array[2]}" >> "${GITHUB_OUTPUT}"
echo "MAJOR_V_VERSION=v${version_array[0]}" >> "${GITHUB_OUTPUT}"
echo "MINOR_V_VERSION=v${version_array[1]}" >> "${GITHUB_OUTPUT}"
echo "PATCH_V_VERSION=v${version_array[2]}" >> "${GITHUB_OUTPUT}"
