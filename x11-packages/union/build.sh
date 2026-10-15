TERMUX_PKG_HOMEPAGE="https://invent.kde.org/plasma/union"
TERMUX_PKG_DESCRIPTION="A Qt style supporting both QtQuick and QtWidgets"
TERMUX_PKG_LICENSE="GPL-2.0-only, GPL-3.0-only, LGPL-2.1-only, LGPL-3.0-only"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="6.8.0"
TERMUX_PKG_SRCURL="https://download.kde.org/stable/plasma/${TERMUX_PKG_VERSION}/union-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=d7340ffe4e269c6ee676acc6c93b928932b06ee2654ae3e7b904b699fb46a46c
TERMUX_PKG_DEPENDS="cxx-rust-cssparser, kf6-kcolorscheme (>= 6.30.0), kf6-kconfig (>= 6.30.0), kf6-kcoreaddons (>= 6.30.0), kf6-kguiaddons (>= 6.30.0), kf6-kiconthemes (>= 6.30.0), kf6-kirigami (>= 6.30.0), libc++, qt6-qtbase (>= 6.9.0), qt6-qtdeclarative (>= 6.9.0), qt6-qtshadertools (>= 6.9.0), zlib"
TERMUX_PKG_BUILD_DEPENDS="extra-cmake-modules (>= 6.30.0)"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_SYSTEM_NAME=Linux
"
