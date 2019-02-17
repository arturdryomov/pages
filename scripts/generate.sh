#!/bin/bash
set -eu

VERSION="0.54.0"
PACKAGE="hugo.tar.gz"
DIRECTORY="hugo"
BINARY="hugo"

case "${OSTYPE}" in
  darwin*) OS="macOS" ;;
  linux*)  OS="Linux" ;;
  *)       exit 1 ;;
esac

trap 'rm -rf "${PACKAGE}" "${DIRECTORY}"' EXIT

echo ":: Downloading..."
curl \
  --silent \
  --fail \
  --show-error \
  --retry 3 \
  --location "https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_${OS}-64bit.tar.gz" \
  --output "${PACKAGE}"

echo ":: Extracting..."
mkdir -p "${DIRECTORY}" && tar -xzf "${PACKAGE}" -C "${DIRECTORY}"

echo ":: Generating..."
"${DIRECTORY}/${BINARY}"
