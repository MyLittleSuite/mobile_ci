#!/bin/sh

# Exit on errors and on use of unset variables.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

program_name=$0
usage() {
  cat <<EOF
usage: $program_name [--target android|flutter-test] [--android-api 37] [--dart] [--dart-version 3.14.1] [--print-image]
  --target <stage>               Dockerfile stage: android (default) or flutter-test
  --android-api <androidVersion> Android API level, e.g. 36 or 37 (android target only)
  --dart                         Dart SDK variant (requires --dart-version)
  --dart-version <version>       Use specific dart version
  --print-image                  Print the manifest image name and exit

Combines <image>-amd64 and <image>-arm64 into the multi-arch <image> manifest.
EOF
  exit "${1:-1}"
}

print_image=false

while [ $# -gt 0 ]; do
  if parse_image_flag "$@"; then
    shift "$consumed"
    continue
  fi
  case "$1" in
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

full_image_name="$(image_base_name)"

if [ "$print_image" = true ]; then
  echo "$full_image_name"
  exit 0
fi

echo "Updating manifest $full_image_name"
docker_login

set -x
docker buildx imagetools create \
  --tag "$full_image_name" \
  "$full_image_name-amd64" \
  "$full_image_name-arm64"
set +x
