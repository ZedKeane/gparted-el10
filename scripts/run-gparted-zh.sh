#!/usr/bin/env sh
set -eu

# Ensure inherited LC_ALL does not override the Chinese locale.
unset LC_ALL
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_MESSAGES=zh_CN.UTF-8

exec /usr/bin/gparted "$@"
