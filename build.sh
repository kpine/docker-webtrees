#!/usr/bin/env bash
docker buildx build --progress plain --platform linux/amd64 -t kpine/caddy-webtrees:local --load .
