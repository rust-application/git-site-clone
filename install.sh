#!/bin/sh

set -e

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
REPO="rust-application/git-site-clone"

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
    *) echo "Unsupported architecture: $ARCH" && exit 1 ;;
esac

# Map to targets
case "$OS" in
    linux)
        TARGET="${ARCH}-unknown-linux-musl"
        ;;
    darwin|macos)
        if [ "$ARCH" = "x86_64" ]; then
            TARGET="x86_64-apple-darwin"
        else
            TARGET="aarch64-apple-darwin"
        fi
        ;;
    *)
        echo "Unsupported OS: $OS" && exit 1
        ;;
esac

# Get latest release
echo "Checking for latest release..."
LATEST=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed 's/.*"tag_name".*:.*"\(.*\)".*/\1/')

if [ -z "$LATEST" ]; then
    echo "Could not fetch latest release"
    exit 1
fi

echo "Latest version: $LATEST"

# Construct download URL
if [ "$OS" = "windows" ]; then
    BINARY="git-site-clone.exe"
else
    BINARY="git-site-clone"
fi

URL="https://github.com/${REPO}/releases/download/${LATEST}/${BINARY}-${TARGET}.tar.gz"

echo "Downloading: $URL"
curl -sL "$URL" | tar -xz -C "$INSTALL_DIR"

chmod +x "${INSTALL_DIR}/${BINARY}"

echo "Installed ${BINARY} to ${INSTALL_DIR}"

# Check if running without self-update feature
if ! "${INSTALL_DIR}/${BINARY}" --help 2>&1 | grep -q "self-update"; then
    echo ""
    echo "Note: This binary was built without self-update support."
    echo "To enable self-update, install with --features self-update"
fi

echo "Done!"