#!/bin/sh

# Exit immediately if a command returns a non-zero status.
set -e

# Usage of this script
program_name=$0
usage () {
  echo "usage: $program_name [--android-api 35] [--dart] [--dart-version 3.7.3]"
  echo "  --android-api <androidVersion> Use specific Android version from \`sdkmanager --list\`"
  echo "  --dart                         Install Dart SDK"
  echo "  --dart-version <version>       Use specific dart version"
  exit 1
}

# Parameters parsing
dart=false

while true; do
  case "$1" in
    --android-api ) android_api="$2"; shift 2 ;;
    --dart ) dart=true; shift ;;
    --dart-version ) dart_version="$2"; shift 2 ;;
    --arch ) arch="$2"; shift 2 ;;
    * ) break ;;
  esac
done

if [ -z "$android_api" ]; then
  echo "Missing --android-api parameter"
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

full_image_name="$org_name/mobile_ci:$simple_image_name"
full_image_name_amd64="$full_image_name-amd64"
full_image_name_arm64="$full_image_name-arm64"

echo "Updating manifests"
echo "$DOCKER_PASSWORD" | docker login --username $DOCKER_USERNAME --password-stdin

docker manifest create $full_image_name \
  --amend $full_image_name_amd64 \
  --amend $full_image_name_arm64

docker manifest push $full_image_name