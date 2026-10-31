TERMUX_PKG_HOMEPAGE=https://github.com/lfdevs/anland-termux
TERMUX_PKG_DESCRIPTION="Anland display daemon and session helpers for Termux"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@lfdevs"
TERMUX_PKG_VERSION="1.11.0"
TERMUX_PKG_SRCURL=git+https://github.com/lfdevs/anland-termux.git
TERMUX_PKG_GIT_BRANCH=termux
_COMMIT=573e4d1a2a8fc27f03db34534f2f892781b0a256
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_SUGGESTS="weston, proot-distro"

termux_step_post_get_source() {
	if [ -n "${_COMMIT}" ]; then
		if git -C "$TERMUX_PKG_SRCDIR" rev-parse --is-shallow-repository | grep -q true; then
			git -C "$TERMUX_PKG_SRCDIR" fetch --unshallow
		fi
		git -C "$TERMUX_PKG_SRCDIR" checkout "$_COMMIT"
	fi
}

termux_step_make() {
	$CC $CPPFLAGS $CFLAGS \
		-Wall -Wextra -Wpedantic -std=c11 \
		"$TERMUX_PKG_SRCDIR/termux/anland/anland.c" \
		"$TERMUX_PKG_SRCDIR/termux/anland/common/socket_utils.c" \
		-o anland \
		$LDFLAGS
}

termux_step_make_install() {
	install -Dm700 anland "$TERMUX_PREFIX/bin/anland"
	install -Dm700 "$TERMUX_PKG_SRCDIR/scripts/anland-native-session.sh" \
		"$TERMUX_PREFIX/bin/anland-native-session"
	install -Dm700 "$TERMUX_PKG_SRCDIR/scripts/anland-proot-session.sh" \
		"$TERMUX_PREFIX/bin/anland-proot-session"

	install -Dm600 "$TERMUX_PKG_SRCDIR/README.md" \
		"$TERMUX_PREFIX/share/doc/anland/README.md"
	install -Dm600 "$TERMUX_PKG_SRCDIR/termux/anland/README.md" \
		"$TERMUX_PREFIX/share/doc/anland/README.daemon.md"
	install -Dm600 "$TERMUX_PKG_SRCDIR/scripts/README.md" \
		"$TERMUX_PREFIX/share/doc/anland/README.scripts.md"
}
