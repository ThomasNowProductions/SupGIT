#!/bin/sh
set -eu

status() {
    printf "\r\033[K%s" "$1"
}

if ! command -v cargo >/dev/null 2>&1; then
    printf "ERROR: 'cargo' is required but not installed\n"
    exit 1
fi

status "Uninstalling SupGIT..."
cargo uninstall supgit

printf "\r\033[K👋 SupGIT has been uninstalled 👋\n"
