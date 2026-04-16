# Maintainer: moon <moonsenpai002@gmail.com>
# Unofficial Arch PKGBUILD wrapping aaddrick/claude-desktop-debian.
# Not on AUR. See README.md for the trust model and rationale.

pkgname=claude-desktop
pkgver=1.2773.0
pkgrel=1
pkgdesc="Anthropic Claude Desktop (unofficial Linux repackage)"
arch=('x86_64')
url="https://github.com/aaddrick/claude-desktop-debian"
license=('custom:Anthropic')
depends=('gtk3' 'nss' 'alsa-lib' 'libsecret' 'libnotify' 'libxss' 'nspr')
makedepends=('icoutils' 'imagemagick' '7zip' 'nodejs' 'npm' 'wget')
options=('!strip' '!debug')
install="${pkgname}.install"
source=(
	"claude-desktop-debian-main.tar.gz::https://github.com/aaddrick/claude-desktop-debian/archive/refs/heads/main.tar.gz"
	'arch-compat.patch'
)
sha256sums=('SKIP' 'SKIP')

_upstream=claude-desktop-debian-main

pkgver() {
	grep -oP 'x64/\K[0-9]+\.[0-9]+\.[0-9]+' \
		"${srcdir}/${_upstream}/build.sh" | head -1
}

prepare() {
	cd "${srcdir}/${_upstream}"
	patch -p1 < "${srcdir}/arch-compat.patch"
	# Neutralise the .deb packager; we stage the tree ourselves in package().
	# build.sh still runs every step up to (and including) producing
	# build/electron-app/, which is all we need.
	printf '#!/bin/sh\nexit 0\n' > scripts/build-deb-package.sh
	chmod +x scripts/build-deb-package.sh
}

build() {
	cd "${srcdir}/${_upstream}"
	./build.sh --build deb --clean no
	[[ -f build/electron-app/app.asar ]] \
		|| { echo 'staging dir missing app.asar' >&2; exit 1; }
}

package() {
	local staging="${srcdir}/${_upstream}/build/electron-app"
	local work="${srcdir}/${_upstream}/build"
	local libdir="${pkgdir}/usr/lib/${pkgname}"
	local resources="${libdir}/node_modules/electron/dist/resources"

	install -d "${libdir}" "${resources}" "${pkgdir}/usr/bin" \
		"${pkgdir}/usr/share/applications"

	cp -a "${staging}/node_modules" "${libdir}/"
	cp "${staging}/app.asar" "${resources}/"
	cp -a "${staging}/app.asar.unpacked" "${resources}/"
	install -Dm 644 "${srcdir}/${_upstream}/scripts/launcher-common.sh" \
		"${libdir}/launcher-common.sh"

	local -A icons=([16]=13 [24]=11 [32]=10 [48]=8 [64]=7 [256]=6)
	local size
	for size in "${!icons[@]}"; do
		install -Dm 644 "${work}/claude_${icons[$size]}_${size}x${size}x32.png" \
			"${pkgdir}/usr/share/icons/hicolor/${size}x${size}/apps/${pkgname}.png"
	done

	install -Dm 755 /dev/stdin "${pkgdir}/usr/bin/${pkgname}" <<-EOF
		#!/usr/bin/env bash
		source "/usr/lib/${pkgname}/launcher-common.sh"
		if [[ "\${1:-}" == '--doctor' ]]; then
			run_doctor "/usr/lib/${pkgname}/node_modules/electron/dist/electron"
			exit \$?
		fi
		setup_logging || exit 1
		setup_electron_env
		cleanup_orphaned_cowork_daemon
		cleanup_stale_lock
		cleanup_stale_cowork_socket
		check_display || {
			echo 'Error: Claude Desktop requires a graphical session.' >&2
			exit 1
		}
		detect_display_backend
		build_electron_args 'deb'
		electron_args+=("/usr/lib/${pkgname}/node_modules/electron/dist/resources/app.asar")
		cd "/usr/lib/${pkgname}" || exit 1
		exec "/usr/lib/${pkgname}/node_modules/electron/dist/electron" \\
			"\${electron_args[@]}" "\$@"
	EOF

	cat > "${pkgdir}/usr/share/applications/${pkgname}.desktop" <<-EOF
		[Desktop Entry]
		Name=Claude
		Exec=/usr/bin/${pkgname} %u
		Icon=${pkgname}
		Type=Application
		Terminal=false
		Categories=Office;Utility;
		MimeType=x-scheme-handler/claude;
		StartupWMClass=Claude
	EOF
}
