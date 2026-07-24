#!/bin/sh

# Exit immediately if a command returns a non-zero status.
set -e

# Usage of this script
program_name=$0
usage () {
  echo "usage: $program_name [--target android|flutter-test] [--android-api 35] [--dart] [--dart-version 3.7.3]"
  echo "  --target <stage>               Dockerfile stage: android (default) or flutter-test"
  echo "  --android-api <androidVersion> Use specific Android version from \`sdkmanager --list\` (android target only)"
  echo "  --dart                         Install Dart SDK"
  echo "  --dart-version <version>       Use specific dart version"
  exit 1
}

# Parameters parsing
dart=false
target=android

while true; do
  case "$1" in
    --target ) target="$2"; shift 2 ;;
    --android-api ) android_api="$2"; shift 2 ;;
    --dart ) dart=true; shift ;;
    --dart-version ) dart_version="$2"; shift 2 ;;
    --arch ) arch="$2"; shift 2 ;;
    * ) break ;;
  esac
done

if [ "$target" != "android" ] && [ "$target" != "flutter-test" ]; then
  echo "Invalid --target: $target (expected android or flutter-test)"
  usage
fi

if [ "$target" = "android" ] && [ -z "$android_api" ]; then
  echo "Missing --android-api parameter"
  usage
fi

# Compute image tag
org_name="mylittlesuite"
if [ "$target" = "flutter-test" ]; then
  simple_image_name="flutter-test"
else
  simple_image_name="android-$android_api"
fi
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

full_image_name="$org_name/mobile_ci:$simple_image_name"
full_image_name_amd64="$full_image_name-amd64"
full_image_name_arm64="$full_image_name-arm64"

echo "Updating manifests"
echo "$DOCKER_PASSWORD" | docker login --username $DOCKER_USERNAME --password-stdin

set -x
docker buildx imagetools create \
  --tag $full_image_name \
  $full_image_name_amd64 \
  $full_image_name_arm64
set +x