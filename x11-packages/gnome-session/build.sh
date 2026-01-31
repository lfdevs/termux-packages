TERMUX_PKG_HOMEPAGE=https://gitlab.gnome.org/GNOME/gnome-session/
TERMUX_PKG_DESCRIPTION="The GNOME session manager"
TERMUX_PKG_LICENSE="GPL-2.0-or-later"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="49.3"
TERMUX_PKG_SRCURL="https://download.gnome.org/sources/gnome-session/${TERMUX_PKG_VERSION%%.*}/gnome-session-$TERMUX_PKG_VERSION.tar.xz"
TERMUX_PKG_SHA256=b424a90cfe51de4941b791a5102aeaadb2c62c185522a21f71cb485270053fe1
TERMUX_PKG_DEPENDS="glib, gnome-desktop4"
TERMUX_PKG_RECOMMENDS="gnome-shell"
TERMUX_PKG_BUILD_DEPENDS="glib-cross"
TERMUX_PKG_VERSIONED_GIR=false
# Should be bumped with gnome-shell
TERMUX_PKG_AUTO_UPDATE=false

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Dx11=true
-Dsystemd=false
"

termux_step_pre_configure() {
	termux_setup_gir
	termux_setup_glib_cross_pkg_config_wrapper

	export TERMUX_MESON_ENABLE_SOVERSION=1
}
