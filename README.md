# Claude Desktop For Arch Linux

Arch Linux PKGBUILD for Anthropic's Claude Desktop. The actual extraction and Electron repack is done by [`aaddrick/claude-desktop-debian`](https://github.com/aaddrick/claude-desktop-debian). This repo wraps that work in an Arch package, with a small patch on top.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/eclipse-senpai/claude-desktop-archlinux/main/install.sh | bash
```

The script clones this repo to `~/.cache/claude-desktop-archlinux`, installs any missing build deps through sudo, then runs `makepkg -si`. Re-running it pulls and rebuilds.

To build it yourself:

```bash
git clone https://github.com/eclipse-senpai/claude-desktop-archlinux
cd claude-desktop-archlinux
makepkg -si
```

## Update

```bash
bash ~/.cache/claude-desktop-archlinux/claudeupdate.sh
```

Or through curl:

```bash
curl -fsSL https://raw.githubusercontent.com/eclipse-senpai/claude-desktop-archlinux/main/claudeupdate.sh | bash
```

It pulls the repo, checks upstream's `build.sh` for the current Claude version, and compares with what pacman has installed. If they match, nothing happens. If upstream has moved ahead, it rebuilds.

## Uninstall

```bash
sudo pacman -R claude-desktop
```

## Dependencies

Runtime: `gtk3`, `nss`, `alsa-lib`, `libsecret`, `libnotify`, `libxss`, `nspr`. Pacman pulls these in automatically.

Build: `icoutils`, `imagemagick`, `7zip`, `nodejs`, `npm`, `wget`. `makepkg -s` installs any of these that are missing.

The PKGBUILD intercepts upstream's final dpkg step, so `dpkg` isn't needed on the system.

## Sandbox

Upstream passes `--no-sandbox` on `deb` builds because the sandbox breaks on some Wayland setups. I've flipped that back on in the packaged launcher. If Claude won't open on your machine, you can disable it:

```bash
CLAUDE_ENABLE_SANDBOX=0 claude-desktop
```

## How it works

Upstream comes in as a tarball:

```bash
source=(
  "claude-desktop-debian-main.tar.gz::https://github.com/aaddrick/claude-desktop-debian/archive/refs/heads/main.tar.gz"
  'arch-compat.patch'
)
```

Using the tarball because makepkg's default git handling does a full mirror clone, and upstream's pull-request refs push that to around 13 GB. The tarball is 400 KB.

`prepare()` applies `arch-compat.patch`. The patch contains two changes:

1. **Regex fixes** in upstream `build.sh` at lines 824, 837, 900, 929. Claude's JS minifier sometimes emits variable names with a leading `$` (like `$m`), and the upstream patterns use `grep -oP '\w+'` which won't match that. The patch relaxes them to `\$?\w+`. This belongs upstream; I'll file a PR for it.
2. **Sandbox default** in `scripts/launcher-common.sh`. The env guard is flipped from `${CLAUDE_ENABLE_SANDBOX:-0}` to `${CLAUDE_ENABLE_SANDBOX:-1}`, so the sandbox runs unless you ask it not to.

`prepare()` also replaces `scripts/build-deb-package.sh` with a no-op. The rest of `build.sh` still runs and stages the real output at `build/electron-app/`: patched `app.asar`, `app.asar.unpacked`, and a local Electron tree.

`package()` installs that into `$pkgdir`:

- `/usr/lib/claude-desktop/node_modules/` with Electron and the launcher library
- `/usr/lib/claude-desktop/node_modules/electron/dist/resources/app.asar`
- `/usr/bin/claude-desktop`, a launcher script written inline in the PKGBUILD
- `/usr/share/applications/claude-desktop.desktop`
- `/usr/share/icons/hicolor/{16,24,32,48,64,256}x*/apps/claude-desktop.png`

The `.install` hook sets `chmod 4755` on `chrome-sandbox` after install and refreshes the desktop database.

## Trust model

A few different pieces of code run when you build:

1. **Anthropic's Windows installer.** `build.sh` downloads it from `downloads.claude.ai` and verifies the checksum before extracting. What ends up under `/usr/lib/claude-desktop` is Anthropic's proprietary Electron bundle, governed by their Terms of Service.
2. **[`aaddrick/claude-desktop-debian`](https://github.com/aaddrick/claude-desktop-debian)** (Apache-2.0 / MIT). Where the extraction, asar patching, and repack happen. Worth reading if you want to know what executes on your machine during a build.
3. **This repo.** The PKGBUILD plus a couple of shell scripts. `LICENSE` applies to those; it doesn't cover Claude Desktop or the upstream builder.

## Credits

- [Anthropic](https://www.anthropic.com/), who make Claude Desktop.
- [k3d3](https://github.com/k3d3/claude-desktop-linux-flake), who worked out how to repack the Windows installer for Linux originally.
- [aaddrick](https://github.com/aaddrick/claude-desktop-debian), who maintains the Debian builder this repo wraps.
