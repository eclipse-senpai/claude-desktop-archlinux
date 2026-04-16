#!/usr/bin/env bash
# Update Claude Desktop on Arch Linux.
#
# Usage:
#   bash ~/.cache/claude-desktop-archlinux/claudeupdate.sh
#   curl -fsSL https://raw.githubusercontent.com/eclipse-senpai/claude-desktop-archlinux/main/claudeupdate.sh | bash
#
# Pulls the packaging repo, compares installed claude-desktop version against
# upstream's build.sh, and rebuilds only if the upstream version moved.

set -euo pipefail

REPO_URL="https://github.com/eclipse-senpai/claude-desktop-archlinux.git"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-desktop-archlinux"
UPSTREAM_BUILD_SH="https://raw.githubusercontent.com/aaddrick/claude-desktop-debian/main/build.sh"

err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '==> %s\n' "$*"; }

[[ $EUID -ne 0 ]] || err "Run as a normal user; makepkg refuses to run as root."
command -v pacman >/dev/null 2>&1 \
    || err "pacman not found; this updater only supports Arch-based distros."
command -v curl >/dev/null 2>&1 || err "curl is required."

sudo pacman -S --needed --noconfirm git base-devel

if [[ -d $CACHE_DIR/.git ]]; then
    info "Pulling latest packaging scripts."
    git -C "$CACHE_DIR" pull --ff-only
else
    info "No existing checkout; cloning."
    mkdir -p "$(dirname "$CACHE_DIR")"
    git clone --depth 1 "$REPO_URL" "$CACHE_DIR"
fi

latest="$(curl -fsSL "$UPSTREAM_BUILD_SH" \
    | grep -oP 'x64/\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
[[ -n $latest ]] || err "Could not read upstream Claude Desktop version."

installed="$(pacman -Q claude-desktop 2>/dev/null | awk '{print $2}' | cut -d- -f1 || true)"

info "Installed: ${installed:-<none>}   Upstream: $latest"

if [[ $installed == "$latest" ]]; then
    info "Already on the latest version. Nothing to do."
    exit 0
fi

info "Building Claude Desktop $latest."
cd "$CACHE_DIR"
makepkg -si

info "Updated to $latest."
