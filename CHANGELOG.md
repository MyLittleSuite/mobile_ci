## 1.5.0
* Added `Java (OpenJDK)` 21, set as default via `jenv global 21`
* Added `Android API` 37
* Added `Android build-tools` 37.0.0
* Added `Android cmdtools` 15859902 (cmdline-tools 22.0) for `Android API` 37. cmdline-tools 23.0 (16111833) is not used: its `sdkmanager` delegates to the new x86-64 only `android` binary, so arm64 builds fail with `Exec format error`
* Added `Dart version` 3.14.1 for `Android API` 37 and for the `flutter-test` image
* Added `very_good_cli` to the `flutter-test` image
* `build.sh` maps `--android-api 37` to the `android-37.0` SDK package (API 37+ platforms are published with a `.0` suffix); the image tag keeps `android-37`
* Updated `Dockerfile` defaults to API 37, build-tools 37.0.0, cmdtools 15859902, Dart 3.14.1
* Rewrote `build.sh` and `manifest.sh` (same flags, same image tags): shared `common.sh` is now the single place that computes image names/tags and the SDK platform name, `set -eu`, unknown flags are rejected instead of ignored, `--arch`/`--dart-arch` default to the host architecture, `--help`, new `--print-image`
* `build.sh` smoke tests the image (SDK platform/build-tools, Java, Dart, FVM, very_good_cli) after building and before pushing; skip with `--skip-test`
* `build.sh` uses the GitHub Actions cache only on GitHub runners, so it also works locally
* The release name is derived from `GIT_REF` (`refs/tags/*`) by the scripts: dropped the `olegtarasov/get-tag` action and the `chmod +x` steps from the workflow
* Added `fail-fast: false` to the image matrices in `publish_images.yml`, so a failing image no longer cancels the other ones
* Fixed `PATH` containing a literal `~/.pub-cache/bin` (`ENV` does not expand `~`): now `/root/.pub-cache/bin`

## 1.4.0
* Added `flutter-test` build target/image: lean Dart+FVM image with `lcov`, `libsqlite3-dev`, `junitreport` baked in, no Android SDK/Java/Ruby — for `flutter test`/`flutter analyze` CI jobs
* `build.sh`/`manifest.sh` now accept `--target android|flutter-test` (defaults to `android`, unchanged behavior)
* Fixed `Dockerfile` `~/.gemrc` write using smart quotes instead of straight quotes, which silently broke the `--no-document` gem install option
* `build.sh` now builds via `docker buildx build` with GitHub Actions cache (`type=gha`, scoped per image/arch) instead of `docker build`, cutting rebuild time on unchanged layers
* `manifest.sh` now prints the `docker manifest` commands it runs (`set -x`), matching `build.sh`
* Replaced legacy `docker manifest create`/`push` with `docker buildx imagetools create` (single create+push step)
* Extracted `_publish-image.yml` reusable workflow, called by per-image jobs instead of duplicating build/manifest steps
* Consolidated `android_release.yml`, `flutter_release.yml`, `flutter_test_release.yml` into a single `publish_images.yml` workflow (one run per push/release with `publish-android`, `publish-flutter`, `publish-flutter-test` jobs, instead of three separate runs)
* Added a `concurrency` group to `publish_images.yml` to cancel superseded runs on the same branch
* Added explicit `docker/setup-buildx-action` step where needed (required for buildx cache)
* Fixed `wget: cannot verify storage.googleapis.com's certificate` failures during Dart SDK download — added missing `ca-certificates` package (+ `update-ca-certificates`) to the base stage

## 1.3.0
* Added `Android API` 36
* Added `Android build-tools` 36.0.0
* Added `Dart version` 3.8.1
* Moved cmdline-tools path to fix `Release app bundle failed to strip debug symbols from native libraries`

## 1.2.0
* Updated `Android cmdtools` 13114758 for `Android API` 35
* Updated `Dart version` 3.7.3 for `Android API` 35
* Added multi-arch support [arm64, amd64]

## 1.1.0

* Added `Android API` 35
* Added `Android build-tools` 35.0.0
* Added `Android cmdtools` 11076708
* Added `Dart version` 3.4.4

## 1.0.0

* First release!
