#!/bin/bash

HUGO_VERSION="0.53"
HUGO_PACKAGE="hugo.tar.gz"
HUGO_DIRECTORY="hugo"
HUGO_BINARY="hugo"

curl --location "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" --output "${HUGO_PACKAGE}"
mkdir -p "${HUGO_DIRECTORY}" && tar -xzf "${HUGO_PACKAGE}" -C "${HUGO_DIRECTORY}"

"./${HUGO_DIRECTORY}/${HUGO_BINARY}"
