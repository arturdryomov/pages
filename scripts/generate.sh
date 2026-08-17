#!/bin/bash
set -eou pipefail

readonly HUGO_VERSION="0.165.0"

readonly HUGO_PACKAGE_NAME="hugo.tar.gz"
readonly HUGO_PACKAGE_PATH="hugo"

trap 'rm -rf "${HUGO_PACKAGE_NAME}" "${HUGO_PACKAGE_PATH}"' EXIT

echo ":: Fetching Hugo..."

curl \
  --silent \
  --fail \
  --show-error \
  --retry 3 \
  --location "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz" \
  --output "${HUGO_PACKAGE_NAME}"

echo ":: Unpacking Hugo..."

mkdir --parents "${HUGO_PACKAGE_PATH}"
tar --extract --gzip --file "${HUGO_PACKAGE_NAME}" --directory "${HUGO_PACKAGE_PATH}"

echo ":: Running Hugo..."

"${HUGO_PACKAGE_PATH}/hugo"
