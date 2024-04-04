# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8

inherit meson readme.gentoo-r1 flag-o-matic

SRC_URI="https://dev.gentoo.org/~aidecoe/distfiles/${CATEGORY}/${PN}/gentoo-logo.png"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.freedesktop.org/plymouth/plymouth"
else
	SRC_URI="${SRC_URI} https://www.freedesktop.org/software/plymouth/releases/${P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~ia64 ~loong ~ppc ~ppc64 ~riscv ~sparc ~x86"
fi

DESCRIPTION="Graphical boot animation (splash) and logger"
HOMEPAGE="https://cgit.freedesktop.org/plymouth/"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug +drm +gtk +pango selinux freetype +split-usr static-libs +udev doc upstart-monitoring systemd"

DEPEND="
	virtual/libc
	>=media-libs/libpng-1.2.16:=
	drm? ( x11-libs/libdrm )
	gtk? (
		dev-libs/glib:2
		>=x11-libs/gtk+-3.14:3
		x11-libs/cairo
	)
	systemd? ( sys-apps/systemd )
	pango? (
		>=x11-libs/pango-1.21
		x11-libs/cairo
	)
	freetype? ( media-libs/freetype:2 )
	udev? ( virtual/libudev )
	dev-libs/libevdev
	x11-libs/libxkbcommon
	x11-misc/xkeyboard-config
	upstart-monitoring? (
		sys-apps/dbus
		sys-libs/ncurses
	)

	elibc_musl? ( sys-libs/rpmatch-standalone )
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt
	virtual/pkgconfig
"
BDEPEND="${DEPEND}
	>=dev-build/meson-0.61
"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-plymouthd )
	udev? ( virtual/udev )
	>sys-kernel/dracut-0.37-r3
"

DOC_CONTENTS="
	Follow the following instructions to set up Plymouth:\n
	https://wiki.gentoo.org/wiki/Plymouth#Configuration
"

src_prepare() {
	use elibc_musl && append-ldflags -lrpmatch
	default
}

src_configure() {
	local emesonargs=(
		$(meson_feature gtk)
		$(meson_feature freetype)
		$(meson_feature pango)
		$(meson_feature udev)
		$(meson_use drm)
		$(meson_use systemd systemd-integration)
		$(meson_use doc docs)
		$(meson_use debug tracing)
		$(meson_use upstart-monitoring)
	)
	meson_src_configure
}

src_compile() {
	meson_src_compile
}

src_install() {
	meson_src_install
	insinto /usr/share/plymouth
	newins "${DISTDIR}"/gentoo-logo.png bizcom.png

	if use split-usr ; then
		# Install compatibility symlinks as some rdeps hardcode the paths
		dosym ../usr/bin/plymouth /bin/plymouth
		dosym ../usr/sbin/plymouth-set-default-theme /sbin/plymouth-set-default-theme
		dosym ../usr/sbin/plymouthd /sbin/plymouthd
	fi

	readme.gentoo_create_doc

	# looks like make install create /var/run/plymouth
	# this is not needed for systemd, same should hold for openrc
	# so remove
	rm -rf "${D}"/var/run

	# fix broken symlink
	dosym ../../bizcom.png /usr/share/plymouth/themes/spinfinity/header-image.png
}

pkg_postinst() {
	readme.gentoo_print_elog
	if ! has_version "sys-kernel/dracut"; then
		ewarn "If you want initramfs builder with plymouth support, please emerge"
		ewarn "sys-kernel/dracut."
	fi
}
