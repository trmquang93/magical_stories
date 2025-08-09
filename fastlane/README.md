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

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata to App Store Connect

### ios upload_release

```sh
[bundle exec] fastlane ios upload_release
```

Upload a new build to App Store Connect

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate and upload screenshots

### ios submit_for_review

```sh
[bundle exec] fastlane ios submit_for_review
```

Submit existing build for App Store review

### ios release

```sh
[bundle exec] fastlane ios release
```

Complete App Store submission

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Sync code signing certificates and provisioning profiles

### ios test_auth

```sh
[bundle exec] fastlane ios test_auth
```

Test App Store Connect API authentication

### ios setup_app_store

```sh
[bundle exec] fastlane ios setup_app_store
```

Setup App Store Connect for new app

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
