#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo 'release is not set'
  exit 1
fi

RELEASE="$1"
echo "$RELEASE"

docker build --no-cache --platform linux/amd64 -t kpine/caddy-webtrees:latest -t kpine/caddy-webtrees:"${RELEASE}" --push .
