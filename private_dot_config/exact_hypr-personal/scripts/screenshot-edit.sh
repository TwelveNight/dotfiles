#!/bin/sh
set -eu
image=$(mktemp --suffix=.png)
trap 'rm -f "$image"' EXIT HUP INT TERM
region=$(slurp) || exit 0
[ -n "$region" ] || exit 0
grim -g "$region" "$image"
swappy -f "$image"
