#!/bin/sh

# Exit on errors and on use of unset variables.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

program_name=$0
usage() {
  cat <<EOF
usage: $program_name [--target android|flutter-test] [--android-api 37] [--build-tools 37.0.0] [--cmdtools 15859902]
                     [--dart] [--dart-arch x64] [--dart-version 3.14.1] [--arch amd64]
                     [--build] [--deploy] [--skip-test] [--print-image]
  --target <stage>               Dockerfile stage to build: android (default) or flutter-test
  --android-api <androidVersion> Android API level, e.g. 36 or 37 (android target only).
                                 API 37+ is mapped to the android-<api>.0 SDK package automatically
  --build-tools <version>        Use specific build tools version (android target only)
  --cmdtools <version>           Use specific command-line tools version (android target only)
  --dart                         Install Dart SDK (requires --dart-version)
  --dart-arch <arch>             Use specific dart architecture (x64, arm64). Default: derived from --arch
  --dart-version <version>       Use specific dart version
  --arch <arch>                  Use specific architecture (amd64, arm64). Default: host architecture
  --build                        Build image (and smoke test it, unless --skip-test)
  --deploy                       Deploy image
  --skip-test                    Do not smoke test the image after building it
  --print-image                  Print the full image name and exit
EOF
  exit "${1:-1}"
}

build=false
deploy=false
skip_test=false
print_image=false

while [ $# -gt 0 ]; do
  if parse_image_flag "$@"; then
    shift "$consumed"
    continue
  fi
  case "$1" in
    --build) build=true ;;
    --deploy) deploy=true ;;
    --skip-test) skip_test=true ;;
    --print-image) print_image=true ;;
    -h | --help) usage 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
  shift
done

validate_image_flags

if [ "$build" = true ] && [ "$target" = "android" ]; then
  [ -n "$android_build_tools" ] || die "missing --build-tools parameter"
  [ -n "$android_cmdtools" ] || die "missing --cmdtools parameter"
fi

full_image_name="$(image_base_name)-$arch"

if [ "$print_image" = true ]; then
  echo "$full_image_name"
  exit 0
fi

if [ "$build" != true ] && [ "$deploy" != true ]; then
  echo "No task was executed" >&2
  usage 1
fi

build_image() {
  set -- buildx build \
    --load \
    --network=host \
    --target "$target" \
    --build-arg "dart=$dart" \
    --build-arg "arch=$arch" \
    --tag "$full_image_name"

  if [ "$target" = "android" ]; then
    set -- "$@" \
      --build-arg "android_api=$(sdk_platform)" \
      --build-arg "android_build_tools=$android_build_tools" \
      --build-arg "android_cmdtools=commandlinetools-linux-${android_cmdtools}_latest.zip"
  fi

  if [ "$dart" = true ]; then
    set -- "$@" \
      --build-arg "dart_arch=$dart_arch" \
      --build-arg "dart_version=$dart_version"
  fi

  # The GitHub Actions cache only exists on GitHub runners
  if [ "${GITHUB_ACTIONS:-}" = true ]; then
    cache_scope="${full_image_name#*:}"
    set -- "$@" \
      --cache-from "type=gha,scope=$cache_scope" \
      --cache-to "type=gha,mode=max,scope=$cache_scope"
  fi

  echo "Building image $full_image_name"
  set -x
  docker "$@" .
  set +x
}

# Fail before pushing if the image does not contain what it promises.
smoke_test() {
  echo "Smoke testing image $full_image_name"

  checks="set -e"
  if [ "$target" = "android" ]; then
    checks="$checks
test -d \"\$ANDROID_HOME/platforms/$(sdk_platform)\"
test -d \"\$ANDROID_HOME/build-tools/$android_build_tools\"
test -d \"\$ANDROID_HOME/platform-tools\"
sdkmanager --version >/dev/null 2>&1
java -version"
  fi
  if [ "$dart" = true ]; then
    checks="$checks
dart --version
fvm --version"
  fi
  # junitreport and very_good_cli are only installed when Dart is enabled
  if [ "$target" = "flutter-test" ] && [ "$dart" = true ]; then
    checks="$checks
test -x /root/.pub-cache/bin/tojunit
very_good --version"
  fi

  docker run --rm --entrypoint sh "$full_image_name" -c "$checks"
}

if [ "$build" = true ]; then
  build_image
  if [ "$skip_test" != true ]; then
    smoke_test
  fi
fi

if [ "$deploy" = true ]; then
  echo "Deploy image $full_image_name"
  docker_login
  docker push "$full_image_name"
fi
