fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios auth_check

```sh
[bundle exec] fastlane ios auth_check
```

Validate App Store Connect credentials with a read-only API call

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit and UI tests. Device overridable via FASTLANE_TEST_DEVICE env var.

### ios build

```sh
[bundle exec] fastlane ios build
```

Build a Release .app without code signing (CI sanity check)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Bump the build number, archive, and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build a Release IPA and upload it to App Store Connect.

By default this only uploads — it does not submit for review.

Set SUBMIT_FOR_REVIEW=1 to submit immediately after upload.

Set TAG_RELEASE=1 to commit the build-number bump, tag, and push.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
