#!/bin/sh

# Exit immediately if a command returns a non-zero status.
set -e

# Usage of this script
program_name=$0
usage () {
  echo "usage: $program_name [--android-api 35] [--build-tools "35.0.0"] [--cmdtools 11076708] [--dart] [--dart-arch x64] [--dart-version 3.7.3] [--arch amd64] [--build] [--deploy]"
  echo "  --android-api <androidVersion> Use specific Android version from \`sdkmanager --list\`"
  echo "  --build-tools <version>        Use specific build tools version"
  echo "  --cmdtools <version>           Use specific command-line tools version"
  echo "  --dart                         Install Dart SDK"
  echo "  --dart-arch <arch>             Use specific dart architecture (x64, arm64)"
  echo "  --dart-version <version>       Use specific dart version"
  echo "  --arch <arch>                  Use specific architecture (amd64, arm64)"
  echo "  --build                        Build image"
  echo "  --deploy                       Deploy image"
  exit 1
}

# Parameters parsing
dart=false

while true; do
  case "$1" in
    --android-api ) android_api="$2"; shift 2 ;;
    --build-tools ) android_build_tools="$2"; shift 2 ;;
    --cmdtools ) android_cmdtools="$2"; shift 2 ;;
    --dart ) dart=true; shift ;;
    --dart-arch ) dart_arch="$2"; shift 2 ;;
    --dart-version ) dart_version="$2"; shift 2 ;;
    --arch ) arch="$2"; shift 2 ;;
    --build ) build=true; shift ;;
    --deploy ) deploy=true; shift ;;
    * ) break ;;
  esac
done

if [ -z "$android_api" ]; then
  echo "Missing --android-api parameter"
  usage
fi

if [ -z "$android_build_tools" ]; then
  echo "Missing --build-tools parameter"
  usage
fi

if [ -z "$android_cmdtools" ]; then
  echo "Missing --cmdtools parameter"
  usage
fi

if [ -z "$arch" ]; then
  echo "Missing --arch parameter"
  usage
fi

# Compute image tag
org_name="mylittlesuite"
simple_image_name="android-$android_api"
if [ "$dart" = true ]; then
  simple_image_name="$simple_image_name-dart-$dart_version"
fi
branch="${GIT_REF##refs/heads/}"
if [ "$branch" = "develop" ]; then
  simple_image_name="$simple_image_name-snapshot"
fi
if [ -n "$RELEASE_NAME" ]; then
  simple_image_name="$simple_image_name-$RELEASE_NAME"
fi

full_image_name="$org_name/mobile_ci:$simple_image_name-$arch"

# CI business
tasks=0
if [ "$build" = true ]; then
  tasks=$((tasks+1))

  if [ -n "$dart_version" ]; then
    dart_arch_and_version_build_arg="--build-arg dart_arch=$dart_arch --build-arg dart_version=$dart_version"
  fi
  echo $dart_arch_and_version_build_arg

  set -x
  docker build \
    --build-arg android_api=android-$android_api \
    --build-arg android_build_tools="$android_build_tools" \
    --build-arg android_cmdtools=commandlinetools-linux-$android_cmdtools\_latest.zip \
    --build-arg dart="$dart" \
    $dart_arch_and_version_build_arg \
    --build-arg arch=$arch \
    --tag $full_image_name .
  set +x
fi

ci=${CI:-false}
if [ "$ci" = true ]; then
  echo "Running in CI"
  volume_options="--volumes-from runner --workdir $GITHUB_WORKSPACE"
else
  echo "Not running in CI"
  volume_options="-v $PWD:/wd --workdir /wd"
fi

if [ "$deploy" = true ]; then
  tasks=$((tasks+1))
  echo "Deploy image $full_image_name"
  echo "$DOCKER_PASSWORD" | docker login --username $DOCKER_USERNAME --password-stdin
  docker push $full_image_name
fi

if [ "$tasks" = 0 ]; then
  echo "No task was executed"
  usage
fi