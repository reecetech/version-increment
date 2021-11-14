# ➕ Version Increment

## 📄 Use

### ⌨️ Example

```yaml
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Get next version
        uses: reecetech/version-increment@2021.11.2
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

### 🔖 semver
This action will detect the current latest _normal_ semantic version (semver) from the tags in
a git repository.  It will increment the version as directed (by default: +1 to
the patch digit).  Both the current latest and the incremented version are
reported back as outputs.

Normal semantic versions are made up of a major, minor and patch digit.  Normal
versions do not include pre-release versions, or versions with build meta-data.

e.g. `1.2.7`

See: https://semver.org/spec/v2.0.0.html

### 📅 calver (semver compliant)

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

If the current latest normal version is not the current year and month, then the year and month digits will be
set to the current year and month, and the release digit will be reset to 1.

### 🎋 Default branch vs. any other branch

**Default branch**

The action will return a _normal_ version if it is detected that the current commit is on the default branch (usually `main`).

Examples:
* `1.2.7`
* `2021.6.2`

**Any other branch**

The action will return a _pre-release_ version if any other branch is detected (e.g. `new-feature`, `bugfix/foo`, etc).  The _pre-release_ portion of the version number will be the literal string `pre.` followed by the git commit ID short reference SHA (trimmed of any leading zeros).

Examples:
* `1.2.7-pre.41218aa78`
* `2021.6.2-pre.32fd19841`

### 📥 Inputs

| name      | description                                               | required | default  |
| :---      | :---                                                      | :---     | :---     |
| scheme    | The versioning scheme in-use, either `semver` or `calver` | No       | `semver` |
| increment | The digit to increment, either `major`, `minor` or `patch`, ignored if `scheme` == `calver` | No | `patch` |

### 📤 Outputs

| name              | description                                                                                       |
| :---              | :---                                                                                              |
| current-version   | The current latest version detected from the git repositories tags                                |
| current-v-version | The current latest version detected from the git repositories tags, prefixed with a `v` character |
| version           | The incremented version number (e.g. the next version)                                            |
| v-version         | The incremented version number (e.g. the next version), prefixed with a `v` character             |

## 💕 Contributing

Please raise a pull request, but note the testing tools below

### bats

BATS is used to test the logic of the shell scripts.

See: https://github.com/bats-core/bats-core

### shellcheck

Shellcheck is used to lint our shell scripts.

Please use [local ignores](https://stackoverflow.com/a/52659039) if you'd like to skip any particular checks.

See: https://github.com/koalaman/shellcheck
