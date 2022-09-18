#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo 'version is not set'
  exit 1
fi

WEBTREES_VERSION="$1"

echo "Building webtrees v$WEBTREES_VERSION"

[[ -z $EARTHLY_PUSH ]] && echo "Set EARTHLY_PUSH=true to push image."

earthly --ci +docker --WEBTREES_VERSION="${RELEASE}"
