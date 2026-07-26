## Mobile Continuous Integration

The purpose of this project is to create a set of images that can be used to build and test mobile applications.
Strongly inspired from [docker-android](https://github.com/faberNovel/docker-android) repository.

### Android
The Android image contains the following software:
* Android SDK (platform-tools, build-tools, platforms)
* Bundler
* Java (OpenJDK 8, 11, 17 and 21, default 21)
* jenv
* rbenv

### Flutter
The Flutter image contains the following software:
* Android SDK (platform-tools, build-tools, platforms)
* Bundler
* Dart
* Flutter
* FVM
* Java (OpenJDK 8, 11, 17 and 21, default 21)
* jenv
* rbenv

### Flutter Test
A lean image for `flutter test`/`flutter analyze` CI jobs — no Android SDK, no Java, no Ruby. Contains:
* Dart
* FVM
* lcov
* libsqlite3-dev
* junitreport

### Building locally
```sh
./build.sh --target android|flutter-test [--build] [--deploy] [options...]
./build.sh --help
```
`--target` defaults to `android`. See `--help` for the full list of options.

### Container Registry
The images are available on [Docker Hub](https://hub.docker.com/r/mylittlesuite/mobile_ci).

### License
This project is licensed under the terms of the [GNU GPLv3 license](https://choosealicense.com/licenses/gpl-3.0/).