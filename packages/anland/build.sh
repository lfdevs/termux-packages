TERMUX_PKG_HOMEPAGE=https://github.com/lfdevs/anland-termux
TERMUX_PKG_DESCRIPTION="Anland display daemon for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@lfdevs"
TERMUX_PKG_VERSION="5.13.3"
TERMUX_PKG_SRCURL=git+https://github.com/lfdevs/anland-termux.git
TERMUX_PKG_GIT_BRANCH=dev/app/add-compatible-version
_COMMIT=1cd0843c7bc10786d6502bf85a385e1281626620
TERMUX_PKG_AUTO_UPDATE=false

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
	install -Dm700 "$TERMUX_PKG_SRCDIR/termux/anland/anland-compatible" \
		"$TERMUX_PREFIX/bin/anland-compatible"

	install -Dm600 "$TERMUX_PKG_SRCDIR/README.md" \
		"$TERMUX_PREFIX/share/doc/anland/README.md"
	install -Dm600 "$TERMUX_PKG_SRCDIR/termux/anland/README.md" \
		"$TERMUX_PREFIX/share/doc/anland/README.daemon.md"
}
