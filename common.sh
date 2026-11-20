#!/bin/sh
# shellcheck shell=sh
#
# Shared helpers for build.sh and manifest.sh. Source it, do not execute it.
# It is the single place that knows how an image is identified (flags -> tag),
# so build.sh and manifest.sh can never drift apart.

org_name="mylittlesuite"
repo_name="mobile_ci"

# Image identity (set by parse_image_flag)
target=android
android_api=""
android_build_tools=""
android_cmdtools=""
dart=false
dart_arch=""
dart_version=""
arch=""

# Number of arguments consumed by the last parse_image_flag call
consumed=0

die() {
  echo "error: $*" >&2
  exit 1
}

# parse_image_flag "$@": consume one image-identity flag.
# Returns 0 and sets $consumed when $1 is one of them, 1 otherwise.
parse_image_flag() {
  consumed=0
  case "$1" in
    --target | --android-api | --build-tools | --cmdtools | --dart-arch | --dart-version | --arch)
      [ $# -ge 2 ] || die "missing value for $1"
      ;;
  esac
  case "$1" in
    --target) target="$2"; consumed=2 ;;
    --android-api) android_api="$2"; consumed=2 ;;
    --build-tools) android_build_tools="$2"; consumed=2 ;;
    --cmdtools) android_cmdtools="$2"; consumed=2 ;;
    --dart) dart=true; consumed=1 ;;
    --dart-arch) dart_arch="$2"; consumed=2 ;;
    --dart-version) dart_version="$2"; consumed=2 ;;
    --arch) arch="$2"; consumed=2 ;;
    *) return 1 ;;
  esac
}

# Normalize and validate the image-identity flags. Fills in defaults:
#  - arch      : host architecture
#  - dart_arch : derived from arch
validate_image_flags() {
  case "$target" in
    android | flutter-test) ;;
    *) die "invalid --target: $target (expected android or flutter-test)" ;;
  esac

  if [ "$target" = "android" ] && [ -z "$android_api" ]; then
    die "missing --android-api parameter"
  fi

  if [ "$dart" = true ] && [ -z "$dart_version" ]; then
    die "--dart requires --dart-version"
  fi

  if [ -z "$arch" ]; then
    arch=$(uname -m)
  fi
  case "$arch" in
    amd64 | x64 | x86_64) arch=amd64 ;;
    arm64 | aarch64) arch=arm64 ;;
    *) die "unsupported --arch: $arch (expected amd64 or arm64)" ;;
  esac

  if [ -z "$dart_arch" ]; then
    case "$arch" in
      amd64) dart_arch=x64 ;;
      arm64) dart_arch=arm64 ;;
    esac
  fi
}

# Android SDK package name for an API level.
# API 37+ platforms are published as "android-<api>.0" (e.g. android-37.0),
# older ones as "android-<api>". An explicit "37.0"/"37.1" is used verbatim.
# The image tag always keeps the API level exactly as given.
sdk_platform() {
  case "$android_api" in
    *.*) echo "android-$android_api" ;;
    *)
      if [ "$android_api" -ge 37 ]; then
        echo "android-$android_api.0"
      else
        echo "android-$android_api"
      fi
      ;;
  esac
}

# Image name without the "-<arch>" suffix, e.g.
#   mylittlesuite/mobile_ci:android-36-dart-3.8.1-snapshot
image_base_name() {
  if [ "$target" = "flutter-test" ]; then
    name="flutter-test"
  else
    name="android-$android_api"
  fi

  if [ "$dart" = true ]; then
    name="$name-dart-$dart_version"
  fi

  git_ref="${GIT_REF:-}"
  if [ "${git_ref##refs/heads/}" = "develop" ]; then
    name="$name-snapshot"
  fi

  # RELEASE_NAME wins, otherwise derive it from a tag ref (refs/tags/v1.4.0)
  release="${RELEASE_NAME:-}"
  if [ -z "$release" ]; then
    case "$git_ref" in
      refs/tags/*) release="${git_ref#refs/tags/}" ;;
    esac
  fi
  if [ -n "$release" ]; then
    name="$name-$release"
  fi

  echo "$org_name/$repo_name:$name"
}

docker_login() {
  if [ -z "${DOCKER_USERNAME:-}" ] || [ -z "${DOCKER_PASSWORD:-}" ]; then
    die "DOCKER_USERNAME and DOCKER_PASSWORD are required"
  fi
  printf '%s' "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
}
