# claude-desktop-archlinux

Unofficial Arch Linux package for [Claude Desktop](https://claude.ai/download).

It wraps [`aaddrick/claude-desktop-debian`](https://github.com/aaddrick/claude-desktop-debian) in a PKGBUILD so `pacman` owns the install cleanly. No `debtap`, no stray files.

Not on the AUR. If you'd rather have an AUR package, [`claude-desktop-bin`](https://aur.archlinux.org/packages/claude-desktop-bin) works too.

## Install

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/eclipse-senpai/claude-desktop-archlinux/main/install.sh | bash
```

The script clones this repo to `~/.cache/claude-desktop-archlinux`, installs any missing build deps, and runs `makepkg -si`. Safe to run more than once.

Or do it yourself:

```bash
git clone https://github.com/eclipse-senpai/claude-desktop-archlinux
cd claude-desktop-archlinux
makepkg -si
```

## Update

```bash
bash ~/.cache/claude-desktop-archlinux/claudeupdate.sh
```

Or via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/eclipse-senpai/claude-desktop-archlinux/main/claudeupdate.sh | bash
```

It pulls the repo, checks if upstream Claude Desktop has a newer version, and rebuilds only if there's something new. If you're already on the latest, it exits.

## Uninstall

```bash
sudo pacman -R claude-desktop
```

## Dependencies

Runtime: `gtk3`, `nss`, `alsa-lib`, `libsecret`, `libnotify`, `libxss`, `nspr`. Normal Electron stuff, pulled in by pacman.

Build: `icoutils`, `imagemagick`, `7zip`, `nodejs`, `npm`, `wget`. `makepkg -s` grabs whatever's missing.

No `dpkg` needed. The PKGBUILD skips upstream's `.deb` step and builds the package directly.

## Sandbox

Upstream ships with `--no-sandbox` on `deb`/`nix` builds because the sandbox breaks on some Wayland setups. This PKGBUILD turns it back on. If Claude won't launch on your machine, disable it:

```bash
CLAUDE_ENABLE_SANDBOX=0 claude-desktop
```

## How it works

The `source` array pulls upstream fresh on every build:

```bash
source=(
  "claude-desktop-debian-main.tar.gz::https://github.com/aaddrick/claude-desktop-debian/archive/refs/heads/main.tar.gz"
  'arch-compat.patch'
)
```

A tarball (~400 KB) instead of a `git+` source, because `makepkg`'s mirror clone of upstream balloons to 13 GB once all the pull-request refs come with it.

`prepare()` applies `arch-compat.patch`, which has two fixes on top of upstream `main`:

1. **Regex fixes** in `build.sh` (lines 824, 837, 900, 929). Claude's minifier sometimes names variables with a `$` prefix (like `$m`), and upstream's `grep -oP '\w+'` patterns skip those. The patch loosens them to `\$?\w+`. This belongs upstream, I'll file a PR.
2. **Sandbox default** in `scripts/launcher-common.sh`. Flips the env guard so the sandbox is on by default on Arch.

`prepare()` also no-ops `scripts/build-deb-package.sh`. The rest of `build.sh` still runs and leaves `build/electron-app/` with the patched `app.asar`, `app.asar.unpacked`, and an Electron tree.

`package()` drops that into `$pkgdir`:

- `/usr/lib/claude-desktop/node_modules/` (Electron + launcher library)
- `/usr/lib/claude-desktop/node_modules/electron/dist/resources/app.asar`
- `/usr/bin/claude-desktop` (launcher, written inline)
- `/usr/share/applications/claude-desktop.desktop`
- `/usr/share/icons/hicolor/{16,24,32,48,64,256}x*/apps/claude-desktop.png`

The `.install` hook sets `chmod 4755` on `chrome-sandbox` and refreshes the desktop database.

## Trust model

Three bits of code run when you build:

1. **Anthropic's Windows installer.** `build.sh` downloads it from `downloads.claude.ai` and verifies the checksum before extracting. The Electron app that ends up installed is Anthropic's, and its use falls under Anthropic's Terms of Service.
2. **`aaddrick/claude-desktop-debian`** (Apache-2.0 / MIT). Does the extraction, the JS patching, and the asar repack. Read it if you want to know what runs on your machine.
3. **This repo.** Small PKGBUILD plus two shell scripts. `LICENSE` covers the packaging only, not Claude itself or the upstream builder.

## Credits

- [Anthropic](https://www.anthropic.com/), who make Claude Desktop.
- [k3d3](https://github.com/k3d3/claude-desktop-linux-flake), who figured out the original Linux repackaging approach.
- [aaddrick](https://github.com/aaddrick/claude-desktop-debian), who maintains the Debian builder this repo wraps.
