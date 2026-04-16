#!/usr/bin/env bash
# claude-desktop-archlinux bootstrap installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/eclipse-senpai/claude-desktop-archlinux/main/install.sh | bash
#
# Clones the repo to ~/.cache/claude-desktop-archlinux, installs any missing
# build deps via sudo pacman, and runs makepkg -si. Safe to re-run.

set -euo pipefail

REPO_URL="https://github.com/eclipse-senpai/claude-desktop-archlinux.git"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-desktop-archlinux"

err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '==> %s\n' "$*"; }

[[ $EUID -ne 0 ]] || err "Run as a normal user; makepkg refuses to run as root."
command -v pacman >/dev/null 2>&1 \
    || err "pacman not found; this installer only supports Arch-based distros."

info "Ensuring git and base-devel are installed."
sudo pacman -S --needed --noconfirm git base-devel

if [[ -d $CACHE_DIR/.git ]]; then
    info "Updating existing checkout at $CACHE_DIR"
    git -C "$CACHE_DIR" pull --ff-only
else
    info "Cloning $REPO_URL into $CACHE_DIR"
    mkdir -p "$(dirname "$CACHE_DIR")"
    git clone --depth 1 "$REPO_URL" "$CACHE_DIR"
fi

cd "$CACHE_DIR"
info "Building and installing with makepkg -si"
makepkg -si

info "Done. Launch with 'claude-desktop' or from your app launcher."
info "To update later: bash $CACHE_DIR/claudeupdate.sh"
