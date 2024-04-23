# Version Increment ➕

## Use 📄

### Example ⌨️

```yaml
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Get next version
        uses: reecetech/version-increment@2023.9.3
        id: version
        with:
          scheme: semver
          increment: patch

      - name: Build image
        uses: docker/build-push-action@v2
        with:
          push: false
          tags: "example/application:${{ steps.version.outputs.version }}"
          context: .
```

#### API mode 🔗

Maybe you don't want to checkout your code in the job that calculates the version number.  That's okay, you can
use the API mode:

```yaml
      - name: Get next version
        uses: reecetech/version-increment@2023.10.1
        id: version
        with:
          use_api: true
```

### semver 🔖

This action will detect the current latest _normal_ semantic version (semver) from the tags in
a git repository.  It will increment the version as directed (by default: +1 to
the patch digit).  Both the current latest and the incremented version are
reported back as outputs.

Normal semantic versions are made up of a major, minor and patch digit.  Normal
versions do not include pre-release versions, or versions with build meta-data.

e.g. `1.2.7`

See: https://semver.org/spec/v2.0.0.html

### calver (semver compliant) 📅

Optionally, this action can provide semver compliant calendar versions (calver).
In this calver scheme, the semver  major, minor and patch digits map to year,
month and release digits.

Note: to be semver compliant, digits must not have leading zeros.

e.g. `2021.6.2`

| semver | calver  | example | note |
| :---   | :---    | :---    | :--- |
| major  | year    | `2021`  |
| minor  | month   | `6`     |
| patch  | release | `2`     | The *n*th release for the month |

If the current latest normal version is not the current year and month, then the
year and month digits will be
set to the current year and month, and the release digit will be reset to 1.

### Conventional Commits (semver with smarts) 💡

If you choose the conventional commits scheme, the action will parse the last commit message _(usually the merge commit)_ to determine
the increment type for a `semver` version.

The following increment types by keyword are supported:
 - patch: build, chore, ci, docs, fix, perf, refactor, revert, style, test
 - minor: feat
 - major: any of the above keywords followed by a '!' character, or 'BREAKING CHANGE:' in commit body

If none of the keywords are detected, then the increment specified by the `increment` input will be used (defaults to patch).

> [!TIP]
> You might like to _enforce_ conventional commits in the title of your pull requests to ensure that the merge commit has the correct
> information.  Something like this action might be handy: https://github.com/marketplace/actions/conventional-commit-in-pull-requests

### Default branch vs. any other branch 🎋

**Default branch**

The action will return a _normal_ version if it is detected that the current commit
is on the default branch (usually `main`).

Examples:
* `1.2.7`
* `2021.6.2`

You may override the branch to consider the release branch if it is not the default branch, by providing a specific
release branch name as an input.  For example:

```yaml
      - name: Get next version
        uses: reecetech/version-increment@2023.10.1
        id: version
        with:
          release_branch: publish
```

**Any other branch**

The action will return a _pre-release_ version if any other branch is detected
(e.g. `new-feature`, `bugfix/foo`, etc).  The _pre-release_ portion of the version number
will be the literal string `pre.` followed by the git commit ID short reference SHA
(trimmed of any leading zeros).

Examples:
* `1.2.7-pre.41218aa78`
* `2021.6.2-pre.32fd19841`

### Inputs 📥

| name           | description                                                                                 | required | default  |
| :---           | :---                                                                                        | :---     | :---     |
| scheme         | The versioning scheme in-use, either `semver`, `calver` or `conventional_commits`           | No       | `semver` |
| pep440         | Set to `true` for PEP440 compatibility of _pre-release_ versions by making use of the build metadata segment of semver, which maps to local version identifier in PEP440 | No       | `false`  |
| increment      | The digit to increment, either `major`, `minor` or `patch`, ignored if `scheme` == `calver` | No       | `patch`  |
| release_branch | Specify a non-default branch to use for the release tag (the one without -pre)              | No       |          |
| use_api        | Use the GitHub API to discover current tags, which avoids the need for a git checkout, but requires `curl` and `jq` | No       | `false`  |

### Outputs 📤

| name              | description                                                                                       |
| :---              | :---                                                                                              |
| current-version   | The current latest version detected from the git repositories tags                                |
| current-v-version | The current latest version detected from the git repositories tags, prefixed with a `v` character |
| version           | The incremented version number (e.g. the next version)                                            |
| v-version         | The incremented version number (e.g. the next version), prefixed with a `v` character             |
| major-version     | Major number of the incremented version                                                           |
| minor-version     | Minor number of the incremented version                                                           |
| patch-version     | Patch number of the incremented version                                                           |
| pre-release-label | Pre-release label of the incremented version                                                      |
| major-v-version   | Major number of the incremented version, prefixed with a `v` character                            |
| minor-v-version   | Minor number of the incremented version, prefixed with a `v` character                            |
| patch-v-version   | Patch number of the incremented version, prefixed with a `v` character                            |

## Contributing 💕

Please raise a pull request, but note the testing tools below

### bats

BATS is used to test the logic of the shell scripts.

See: https://github.com/bats-core/bats-core

### shellcheck

Shellcheck is used to lint our shell scripts.

Please use [local ignores](https://stackoverflow.com/a/52659039) if you'd like to skip any particular checks.

See: https://github.com/koalaman/shellcheck
