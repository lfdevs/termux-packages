TERMUX_PKG_HOMEPAGE=https://www.mesa3d.org
TERMUX_PKG_DESCRIPTION="An open-source implementation of the OpenGL specification"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_LICENSE_FILE="docs/license.rst"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="26.2.0-devel"
TERMUX_PKG_SRCURL=git+https://github.com/funnymdzz/mesa
TERMUX_PKG_GIT_BRANCH=main
_COMMIT=6a8f518cf31fd0a3c94f471730d0f6f08e02869d
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="libandroid-shmem, libc++, libdrm, libglvnd, libllvm (<< $TERMUX_LLVM_NEXT_MAJOR_VERSION), libwayland, libx11, libxext, libxfixes, libxshmfence, libxxf86vm, ncurses, vulkan-loader, zlib, zstd"
TERMUX_PKG_SUGGESTS="mesa-dev"
TERMUX_PKG_BUILD_DEPENDS="clang, libclc, libwayland-protocols, libxrandr, llvm, llvm-tools, mlir, spirv-llvm-translator, spirv-tools, xorgproto"
TERMUX_PKG_BREAKS="osmesa, osmesa-demos"
TERMUX_PKG_CONFLICTS="libmesa, ndk-sysroot (<= 25b), osmesa"
TERMUX_PKG_REPLACES="libmesa, osmesa"

if [[ "${TERMUX_ARCH}" == "arm" || "${TERMUX_ARCH}" == "aarch64" ]]; then
	TERMUX_PKG_HOSTBUILD=true
fi

# FIXME: Set `shared-llvm` to disabled if possible
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--cmake-prefix-path $TERMUX_PREFIX
-Dgbm=enabled
-Dopengl=true
-Degl=enabled
-Degl-native-platform=x11
-Dgles1=disabled
-Dgles2=enabled
-Dglx=dri
-Dllvm=enabled
-Dshared-llvm=enabled
-Dplatforms=x11,wayland
-Dgallium-drivers=llvmpipe,softpipe,virgl,zink
-Dgallium-rusticl=true
-Dglvnd=enabled
-Dxmlconfig=disabled
"

termux_step_post_get_source() {
	if [ -n "${_COMMIT}" ]; then
		# Ensure the requested commit is available when cloning shallow.
		if git -C "$TERMUX_PKG_SRCDIR" rev-parse --is-shallow-repository | grep -q true; then
			git -C "$TERMUX_PKG_SRCDIR" fetch --unshallow
		fi
		git -C "$TERMUX_PKG_SRCDIR" checkout "$_COMMIT"
	fi

	# Do not use meson wrap projects
	rm -rf subprojects
}

termux_step_host_build() {
	(
		export PATH="${TERMUX_HOST_LLVM_BASE_DIR}/bin:${PATH}"

		AR=
		CC=
		CFLAGS=
		CPPFLAGS=
		CXX=
		CXXFLAGS=
		LD=
		LDFLAGS=
		PKG_CONFIG=
		STRIP=
		termux_setup_meson
		unset AR CC CFLAGS CPPFLAGS CXX CXXFLAGS LD LDFLAGS \
			PKG_CONFIG PKG_CONFIG_LIBDIR PKG_CONFIG_PATH STRIP

		${TERMUX_MESON} setup \
			"${TERMUX_PKG_HOSTBUILD_DIR}" \
			"${TERMUX_PKG_SRCDIR}" \
			--buildtype=release \
			-Dbuild-tests=false \
			-Ddisplay-info=disabled \
			-Degl=disabled \
			-Dgallium-drivers= \
			-Dgbm=disabled \
			-Dgles1=disabled \
			-Dgles2=disabled \
			-Dglx=disabled \
			-Dinstall-mesa-clc=true \
			-Dinstall-precomp-compiler=true \
			-Dlibunwind=disabled \
			-Dllvm=enabled \
			-Dlmsensors=disabled \
			-Dmesa-clc=enabled \
			-Dopengl=false \
			-Dplatforms= \
			-Dprecomp-compiler=enabled \
			-Dshared-glapi=disabled \
			-Dtools=panfrost \
			-Dvalgrind=disabled \
			-Dvideo-codecs= \
			-Dvulkan-drivers= \
			-Dxmlconfig=disabled \
			-Dzstd=disabled

		ninja \
			-C "${TERMUX_PKG_HOSTBUILD_DIR}" \
			-j "${TERMUX_PKG_MAKE_PROCESSES}" \
			src/compiler/clc/mesa_clc \
			src/compiler/spirv/vtn_bindgen2 \
			src/panfrost/clc/panfrost_compile

		install -Dm755 \
			"${TERMUX_PKG_HOSTBUILD_DIR}/src/compiler/clc/mesa_clc" \
			"${TERMUX_PKG_HOSTBUILD_DIR}/bin/mesa_clc"
		install -Dm755 \
			"${TERMUX_PKG_HOSTBUILD_DIR}/src/compiler/spirv/vtn_bindgen2" \
			"${TERMUX_PKG_HOSTBUILD_DIR}/bin/vtn_bindgen2"
		install -Dm755 \
			"${TERMUX_PKG_HOSTBUILD_DIR}/src/panfrost/clc/panfrost_compile" \
			"${TERMUX_PKG_HOSTBUILD_DIR}/bin/panfrost_compile"
	)
}

termux_step_pre_configure() {
	if [ "$TERMUX_PKG_API_LEVEL" -lt 29 ]; then
		# ELF TLS is supported starting with API level 29.
		patch --silent -p1 < "$TERMUX_PKG_BUILDER_DIR/0011-lld-undefined-version.diff"
	fi

	termux_setup_cmake
	termux_setup_rust

	: "${CARGO_HOME:=${HOME}/.cargo}"
	export CARGO_HOME

	cargo install --force --locked bindgen-cli
	if [[ "${TERMUX_ON_DEVICE_BUILD}" == "false" ]]; then
		export BINDGEN_EXTRA_CLANG_ARGS="--sysroot ${TERMUX_STANDALONE_TOOLCHAIN}/sysroot"
		case "${TERMUX_ARCH}" in
		arm) BINDGEN_EXTRA_CLANG_ARGS+=" --target=arm-linux-androideabi${TERMUX_PKG_API_LEVEL}" ;;
		*) BINDGEN_EXTRA_CLANG_ARGS+=" --target=${TERMUX_ARCH}-linux-android${TERMUX_PKG_API_LEVEL}" ;;
		esac
	fi

	CPPFLAGS+=" -D__USE_GNU"
	LDFLAGS+=" -landroid-shmem"

	_WRAPPER_BIN=$TERMUX_PKG_BUILDDIR/_wrapper/bin
	mkdir -p $_WRAPPER_BIN
	if [ "$TERMUX_ON_DEVICE_BUILD" = "false" ]; then
		sed 's|@CMAKE@|'"$(command -v cmake)"'|g' \
			$TERMUX_PKG_BUILDER_DIR/cmake-wrapper.in \
			> $_WRAPPER_BIN/cmake
		chmod 0700 $_WRAPPER_BIN/cmake
		termux_setup_wayland_cross_pkg_config_wrapper
	fi
	export LLVM_CONFIG="${TERMUX_PREFIX}/bin/llvm-config"
	export PATH="${_WRAPPER_BIN}:${CARGO_HOME}/bin:${PATH}"

	local _vk_drivers="swrast"
	if [ $TERMUX_ARCH = "arm" ] || [ $TERMUX_ARCH = "aarch64" ]; then
		_vk_drivers+=",freedreno,panfrost"
		TERMUX_PKG_EXTRA_CONFIGURE_ARGS+="
			-Dfreedreno-kmds=msm,kgsl
			-Dpanfrost-kmds=kbase,panthor
			-Dmesa-clc=system
			-Dprecomp-compiler=system
			-Dinstall-mesa-clc=false
			-Dinstall-precomp-compiler=false
		"
		export PATH="${TERMUX_PKG_HOSTBUILD_DIR}/bin:${PATH}"
	fi
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -Dvulkan-drivers=$_vk_drivers"
}

termux_step_post_configure() {
	rm -f $_WRAPPER_BIN/cmake
}

termux_step_post_make_install() {
	# Avoid hard links
	local f1
	for f1 in $TERMUX_PREFIX/lib/dri/*; do
		if [ ! -f "${f1}" ]; then
			continue
		fi
		local f2
		for f2 in $TERMUX_PREFIX/lib/dri/*; do
			if [ -f "${f2}" ] && [ "${f1}" != "${f2}" ]; then
				local s1=$(stat -c "%i" "${f1}")
				local s2=$(stat -c "%i" "${f2}")
				if [ "${s1}" = "${s2}" ]; then
					ln -sfr "${f1}" "${f2}"
				fi
			fi
		done
	done

	# Create symlinks
	ln -sf libEGL_mesa.so ${TERMUX_PREFIX}/lib/libEGL_mesa.so.0
	ln -sf libGLX_mesa.so ${TERMUX_PREFIX}/lib/libGLX_mesa.so.0
	ln -sf libRusticlOpenCL.so ${TERMUX_PREFIX}/lib/libRusticlOpenCL.so.1

	unset BINDGEN_EXTRA_CLANG_ARGS LLVM_CONFIG
}
