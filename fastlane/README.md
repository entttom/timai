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

### ios test

```sh
[bundle exec] fastlane ios test
```

Führt alle Tests aus

### ios ui_test

```sh
[bundle exec] fastlane ios ui_test
```

Führt UI-Tests aus

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Erstellt Screenshots für den App Store

### ios debug

```sh
[bundle exec] fastlane ios debug
```

Erstellt einen Debug-Build

### ios adhoc

```sh
[bundle exec] fastlane ios adhoc
```

Erstellt einen Ad-Hoc Build für interne Tests

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Lädt einen neuen Build zu TestFlight hoch

### ios release

```sh
[bundle exec] fastlane ios release
```

Erstellt einen Release-Build und lädt ihn zum App Store hoch

### ios sync_certificates

```sh
[bundle exec] fastlane ios sync_certificates
```

Synchronisiert Certificates und Provisioning Profiles mit match

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Erhöht die Version Number (patch, minor oder major)

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

Erhöht die Build Number

### ios update_dependencies

```sh
[bundle exec] fastlane ios update_dependencies
```

Aktualisiert Carthage Dependencies

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Führt SwiftLint aus (falls installiert)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
