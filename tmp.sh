#!/bin/sh
set -eu

          VERSION=25.07.1
          echo "Downloading cloudflared ${VERSION}"
          ARCH=$(uname -m)
          URL="https://github.com/helix-editor/helix/releases/download/${VERSION}/helix-${VERSION}-${ARCH}-linux.tar.xz"
          curl -L "${URL}" | xz -d | tar -C /opt -x
          ln -snf /opt/helix-${URL}-${ARCH}-linux/hx /usr/local/bin/hx
          hx --version