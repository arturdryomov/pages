#!/bin/bash
set -eou pipefail

HUGO_VERSION="0.155.1"

HUGO_PACKAGE_NAME="hugo.tar.gz"
HUGO_PACKAGE_PATH="hugo"

trap 'rm -rf "${HUGO_PACKAGE_NAME}" "${HUGO_PACKAGE_PATH}"' EXIT

function fetch_hugo_package() {
  echo ":: Fetching Hugo package..."

  curl \
    --silent \
    --fail \
    --show-error \
    --retry 3 \
    --location "$(resolve_hugo_package_url)" \
    --output "${HUGO_PACKAGE_NAME}"
}

function resolve_hugo_package_url() {
  echo "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_$(resolve_hugo_package_platform).tar.gz"
}

function resolve_hugo_package_platform() {
  case "$(uname)" in
    "Darwin")
      echo "darwin-universal"
      ;;
    "Linux")
      echo "linux-amd64"
      ;;
  esac
}

function unpack_hugo_package() {
  echo ":: Unpacking Hugo package..."

  mkdir -p "${HUGO_PACKAGE_PATH}" && tar -xzf "${HUGO_PACKAGE_NAME}" -C "${HUGO_PACKAGE_PATH}"
}

function execute_hugo() {
  echo ":: Generating..."

  "${HUGO_PACKAGE_PATH}/hugo"
}

fetch_hugo_package && unpack_hugo_package && execute_hugo
