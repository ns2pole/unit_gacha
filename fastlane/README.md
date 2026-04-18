fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### release_all_platforms

```sh
[bundle exec] fastlane release_all_platforms
```

iOS と Android の両方を一撃でリリース

options: skip_build:true, skip_ios:true, skip_android:true, notes:'...', notes_en:'...'

----


## iOS

### ios release_all

```sh
[bundle exec] fastlane ios release_all
```

iOS リリースを自動化

----


## Android

### android release_all

```sh
[bundle exec] fastlane android release_all
```

Android リリースを自動化

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
