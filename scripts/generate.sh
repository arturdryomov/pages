#!/bin/bash
set -eou pipefail

readonly HUGO_VERSION="0.165.0"

HUGO_PATH="$(mktemp --directory)"; readonly HUGO_PATH
HUGO_PACKAGE_PATH="${HUGO_PATH}/hugo.tar.gz"; readonly HUGO_PACKAGE_PATH

trap 'rm -rf "${HUGO_PATH}"' EXIT

echo ":: Fetching Hugo..."

curl \
  --silent \
  --fail \
  --show-error \
  --retry 3 \
  --location "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz" \
  --output "${HUGO_PACKAGE_PATH}"

echo ":: Extracting Hugo..."

tar --extract --gzip --file "${HUGO_PACKAGE_PATH}" --directory "${HUGO_PATH}"

echo ":: Running Hugo..."

"${HUGO_PATH}/hugo"
