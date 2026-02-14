#!/bin/sh
set -eu

REPO="ThomasNowProductions/SGIT"
INSTALL_DIR="${SGIT_INSTALL_DIR:-${HOME}/.local/bin}"
VERSION="${SGIT_VERSION:-latest}"

check_deps() {
    for dep in curl; do
        command -v "$dep" >/dev/null 2>&1 || { printf "ERROR: '%s' is required but not installed\n" "$dep"; exit 1; }
    done
    if [ "$(uname -s)" = "MINGW"* ] || [ "$(uname -s)" = "MSYS"* ] || [ "$(uname -s)" = "CYGWIN"* ]; then
        command -v unzip >/dev/null 2>&1 || { printf "ERROR: 'unzip' is required but not installed\n"; exit 1; }
    else
        command -v tar >/dev/null 2>&1 || { printf "ERROR: 'tar' is required but not installed\n"; exit 1; }
    fi
}

check_writable() {
    mkdir -p "$1" 2>/dev/null || return 1
    [ -w "$1" ] || return 1
    return 0
}

detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux)
            case "$ARCH" in
                x86_64) echo "x86_64-linux" ;;
                aarch64|arm64) echo "aarch64-linux" ;;
                *) echo "unsupported" ;;
            esac
            ;;
        Darwin)
            case "$ARCH" in
                x86_64) echo "x86_64-macos" ;;
                aarch64|arm64) echo "aarch64-macos" ;;
                *) echo "unsupported" ;;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*)
            case "$ARCH" in
                x86_64) echo "x86_64-windows" ;;
                *) echo "unsupported" ;;
            esac
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

status() {
    printf "\r\033[K%s" "$1"
}

check_deps

if ! check_writable "$INSTALL_DIR"; then
    printf "ERROR: Cannot write to %s\n" "$INSTALL_DIR"
    printf "       Try: SGIT_INSTALL_DIR=/path/to/writable/dir ./install.sh\n"
    exit 1
fi

PLATFORM="$(detect_platform)"
if [ "$PLATFORM" = "unsupported" ]; then
    printf "ERROR: Unsupported platform (OS: $(uname -s), Arch: $(uname -m))\n"
    exit 1
fi

if [ "$VERSION" = "latest" ]; then
    status "Fetching latest release..."
    RELEASE_INFO="$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null)" || RELEASE_INFO=""
    if [ -z "$RELEASE_INFO" ] || printf '%s' "$RELEASE_INFO" | grep -q 'API rate limit exceeded'; then
        printf "\r\033[KERROR: Failed to fetch release info from GitHub\n"
        printf "       (Rate limited? Try: SGIT_VERSION=v0.1.0 ./install.sh)\n"
        printf "       See all releases: https://github.com/$REPO/releases\n"
        exit 1
    fi
    VERSION="$(printf '%s' "$RELEASE_INFO" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)"
    if [ -z "$VERSION" ]; then
        printf "\r\033[KERROR: No releases found. Visit https://github.com/$REPO/releases\n"
        exit 1
    fi
fi

if [ "$(uname -s)" = "MINGW"* ] || [ "$(uname -s)" = "MSYS"* ] || [ "$(uname -s)" = "CYGWIN"* ]; then
    ARCHIVE="sgit-${PLATFORM}.zip"
else
    ARCHIVE="sgit-${PLATFORM}.tar.gz"
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$ARCHIVE"

status "Downloading SGIT $VERSION for $PLATFORM..."
TEMP_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null
}
trap cleanup EXIT

if ! curl -sSLf "$DOWNLOAD_URL" -o "$TEMP_DIR/$ARCHIVE"; then
    printf "\r\033[KERROR: Failed to download $DOWNLOAD_URL\n"
    exit 1
fi

status "Extracting..."
cd "$TEMP_DIR"
if [ "$(uname -s)" = "MINGW"* ] || [ "$(uname -s)" = "MSYS"* ] || [ "$(uname -s)" = "CYGWIN"* ]; then
    unzip -q "$ARCHIVE"
else
    tar -xzf "$ARCHIVE"
fi

BINARY="$(find . -maxdepth 2 -name "sgit" -o -name "sgit.exe" 2>/dev/null | head -1)"
if [ -z "$BINARY" ]; then
    printf "\r\033[KERROR: Binary not found in archive\n"
    exit 1
fi

status "Installing SGIT to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp "$BINARY" "$INSTALL_DIR/sgit"
chmod 755 "$INSTALL_DIR/sgit"

status "Verifying installation..."
if ! "$INSTALL_DIR/sgit" --version >/dev/null 2>&1; then
    printf "\r\033[KERROR: Installed binary failed to run\n"
    printf "       This may indicate an architecture mismatch\n"
    exit 1
fi

printf "\r\033[K🎉 SGIT $VERSION is installed 🎉\n"

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        printf "\n⚠️  $INSTALL_DIR is not in your PATH\n"
        printf "   Add it by running:\n"
        printf "     echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.bashrc && source ~/.bashrc\n"
        printf "   (or use ~/.zshrc for zsh)\n"
        ;;
esac
