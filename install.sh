#!/usr/bin/env bash
set -euo pipefail

APP_NAME="codex_usage_report"
BIN_DIR="dist"
BIN_FILE="$BIN_DIR/$APP_NAME"

# Destinos possíveis
SYSTEM_TARGET="/usr/local/bin/$APP_NAME"
USER_TARGET="$HOME/.local/bin/$APP_NAME"

# Verifica se o binário existe
if [[ ! -f "$BIN_FILE" ]]; then
  echo "[ERROR] Binary not found: $BIN_FILE"
  echo "Run 'make build' or 'make release' before installing."
  exit 1
fi

install_to_user() {
  mkdir -p "$HOME/.local/bin"
  cp "$BIN_FILE" "$USER_TARGET"
  echo "[OK] Installed to $USER_TARGET"
  echo "⚠️ Make sure ~/.local/bin is in your PATH"
}

install_to_system() {
  echo "[INFO] Copying $BIN_FILE → $SYSTEM_TARGET"
  if sudo cp "$BIN_FILE" "$SYSTEM_TARGET"; then
    echo "[OK] Installed to $SYSTEM_TARGET"
  else
    echo "[WARN] Could not install to /usr/local/bin (no sudo?)"
    install_to_user
  fi
}

# Se usuário passar --user, força instalação local
if [[ "${1:-}" == "--user" ]]; then
  install_to_user
else
  install_to_system
fi

echo "You can now run: $APP_NAME --help"

