#!/bin/sh
set -eux

. ./config

# gcc >= 6.3.0
# ANDROID_TARGET_API (ANDROID_SDK_VERSION) >= 24

PKG_HOMEPAGE=https://nodejs.org/
PKG_DESCRIPTION="Open Source, cross-platform JavaScript runtime environment"
PKG_LICENSE="MIT"

PKG_VERSION=21.6.0
PKG_BASENAME=node-v${PKG_VERSION}
PKG_EXTNAME=.tar.xz
PKG_SRCURL=https://nodejs.org/dist/v${PKG_VERSION}/node-v${PKG_VERSION}${PKG_EXTNAME}
# PKG_SRCURL=https://mirrors.ustc.edu.cn/node/v${PKG_VERSION}/node-v${PKG_VERSION}${PKG_EXTNAME}

get_source

cd "${BUILD_DIR}/${PKG_BASENAME}"

# ../deps/zlib/cpu_features.c:43:10: fatal error: 'cpu-features.h' file not found
export CFLAGS=" -I${ANDROID_NDK_ROOT}/sources/android/cpufeatures"

# ../deps/v8/src/base/debug/stack_trace_posix.cc:156:9: error: use of undeclared identifier 'backtrace_symbols'
patch -f ./deps/v8/src/trap-handler/trap-handler.h -up1 <"${WORK_DIR}/packages/nodejs/21.x.fixed-trap-handler.patch"

# ../deps/v8/src/base/debug/stack_trace_posix.cc:156:9: error: use of undeclared identifier 'backtrace_symbols'
echo >test/cctest/test_crypto_clienthello.cc

# g++: error: unrecognized command-line option ‘-mbranch-protection=standard’
patch -up1 <"${WORK_DIR}/packages/nodejs/node_gyp_mbranch-protection.patch" || true

case ${TARGET} in
aarch64-linux-android*)
	DEST_CPU="arm64"
	TARGET_ARCH="arm64"
	HOST_M32=""
	;;
armv7a-linux-androideabi*)
	DEST_CPU="arm"
	HOST_M32=" -m32"
	;;
x86_64-linux-android*)
	DEST_CPU="x64"
	TARGET_ARCH="x64"
	HOST_M32=""
	;;
i686-linux-android*)
	DEST_CPU="ia32"
	HOST_M32=" -m32"
	;;
*) ;;
esac

HOST_OS=$(uname -m)
export GYP_DEFINES="\
	target_arch=${TARGET_ARCH} \
	v8_target_arch=${TARGET_ARCH} \
	android_target_arch=${TARGET_ARCH} \
	host_os=${HOST_OS} \
	OS=android \
	android_ndk_path=${ANDROID_NDK_ROOT}"

export CXXLASGS=" -Wno-unused-command-line-argument"
CC_host="gcc${HOST_M32}"
CXX_host="g++${HOST_M32}"
export CC_host CXX_host

build_with_make() {
	./configure \
		--dest-cpu="${DEST_CPU}" \
		--dest-os=android \
		--openssl-no-asm \
		--cross-compiling \
		--partly-static \
		--prefix="${OUTPUT_DIR}"

	make -j"${JOBS}"
}

build_with_ninja() {
	patch -up1 <"${WORK_DIR}/packages/nodejs/build_with_ninja.patch"

	./configure \
		--dest-cpu="${DEST_CPU}" \
		--dest-os=android \
		--openssl-no-asm \
		--cross-compiling \
		--partly-static \
		--prefix="${OUTPUT_DIR}" \
		--ninja

	ninja -C out/Release -j"${JOBS}"
}

build_with_ninja

# TERMUX_PKG_HOMEPAGE=https://nodejs.org/
# TERMUX_PKG_DESCRIPTION="Open Source, cross-platform JavaScript runtime environment"
# TERMUX_PKG_LICENSE="MIT"
# TERMUX_PKG_MAINTAINER="Yaksh Bariya <thunder-coding@termux.dev>"
# TERMUX_PKG_VERSION=20.2.0
# TERMUX_PKG_REVISION=1
# TERMUX_PKG_SRCURL=https://nodejs.org/dist/v${TERMUX_PKG_VERSION}/node-v${TERMUX_PKG_VERSION}.tar.xz
# TERMUX_PKG_SHA256=22523df2316c35569714ff1f69b053c2e286ced460898417dee46945efcdf989
#  # thunder-coding: don't try to autoupdate nodejs, that thing takes 2 whole hours to build for a single arch, and requires a lot of patch updates everytime. Also I run tests everytime I update it to ensure least bugs
# TERMUX_PKG_AUTO_UPDATE=false
# # Note that we do not use a shared libuv to avoid an issue with the Android
# # linker, which does not use symbols of linked shared libraries when resolving
# # symbols on dlopen(). See https://github.com/termux/termux-packages/issues/462.
# TERMUX_PKG_DEPENDS="libc++, openssl, c-ares, libicu, zlib"
# TERMUX_PKG_CONFLICTS="nodejs-lts, nodejs-current"
# TERMUX_PKG_BREAKS="nodejs-dev"
# TERMUX_PKG_REPLACES="nodejs-current, nodejs-dev"
# TERMUX_PKG_SUGGESTS="clang, make, pkg-config, python"
# TERMUX_PKG_RM_AFTER_INSTALL="lib/node_modules/npm/html lib/node_modules/npm/make.bat share/systemtap lib/dtrace"
# TERMUX_PKG_BUILD_IN_SRC=true
# TERMUX_PKG_HOSTBUILD=true

# termux_step_post_get_source() {
# 	# Prevent caching of host build:
# 	rm -Rf $TERMUX_PKG_HOSTBUILD_DIR
# }

# termux_step_host_build() {
# 	local ICU_VERSION=74.1
# 	local ICU_TAR=icu4c-${ICU_VERSION//./_}-src.tgz
# 	local ICU_DOWNLOAD=https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION//./-}/$ICU_TAR
# 	termux_download \
# 		$ICU_DOWNLOAD\
# 		$TERMUX_PKG_CACHEDIR/$ICU_TAR \
# 		86ce8e60681972e60e4dcb2490c697463fcec60dd400a5f9bffba26d0b52b8d0
# 	tar xf $TERMUX_PKG_CACHEDIR/$ICU_TAR
# 	cd icu/source
# 	if [ "$TERMUX_ARCH_BITS" = 32 ]; then
# 		./configure --prefix $TERMUX_PKG_HOSTBUILD_DIR/icu-installed \
# 			--disable-samples \
# 			--disable-tests \
# 			--build=i686-pc-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32"
# 	else
# 		./configure --prefix $TERMUX_PKG_HOSTBUILD_DIR/icu-installed \
# 			--disable-samples \
# 			--disable-tests
# 	fi
# 	make -j $TERMUX_MAKE_PROCESSES install
# }

# termux_step_configure() {
# 	local DEST_CPU
# 	if [ $TERMUX_ARCH = "arm" ]; then
# 		DEST_CPU="arm"
# 	elif [ $TERMUX_ARCH = "i686" ]; then
# 		DEST_CPU="ia32"
# 	elif [ $TERMUX_ARCH = "aarch64" ]; then
# 		DEST_CPU="arm64"
# 	elif [ $TERMUX_ARCH = "x86_64" ]; then
# 		DEST_CPU="x64"
# 	else
# 		termux_error_exit "Unsupported arch '$TERMUX_ARCH'"
# 	fi

# 	export GYP_DEFINES="host_os=linux"
# 	export CC_host=gcc
# 	export CXX_host=g++
# 	export LINK_host=g++

# 	LDFLAGS+=" -ldl"
# 	# See note above TERMUX_PKG_DEPENDS why we do not use a shared libuv.
# 	./configure \
# 		--prefix=$TERMUX_PREFIX \
# 		--dest-cpu=$DEST_CPU \
# 		--dest-os=android \
# 		--shared-cares \
# 		--shared-openssl \
# 		--shared-zlib \
# 		--with-intl=system-icu \
# 		--cross-compiling

# 	export LD_LIBRARY_PATH=$TERMUX_PKG_HOSTBUILD_DIR/icu-installed/lib
# 	perl -p -i -e "s@LIBS := \\$\\(LIBS\\)@LIBS := -L$TERMUX_PKG_HOSTBUILD_DIR/icu-installed/lib -lpthread -licui18n -licuuc -licudata -ldl -lz@" \
# 		$TERMUX_PKG_SRCDIR/out/tools/v8_gypfiles/mksnapshot.host.mk \
# 		$TERMUX_PKG_SRCDIR/out/tools/v8_gypfiles/torque.host.mk \
# 		$TERMUX_PKG_SRCDIR/out/tools/v8_gypfiles/bytecode_builtins_list_generator.host.mk \
# 		$TERMUX_PKG_SRCDIR/out/tools/v8_gypfiles/v8_libbase.host.mk \
# 		$TERMUX_PKG_SRCDIR/out/tools/v8_gypfiles/gen-regexp-special-case.host.mk
# }

# termux_step_make_install() {
# 	python ./tools/install.py install '' $TERMUX_PREFIX
# }

# termux_step_create_debscripts() {
# 	cat <<- EOF > ./postinst
# 	#!$TERMUX_PREFIX/bin/sh
# 	npm config set foreground-scripts true
# 	EOF
# }

# TERMUX_PKG_VERSION=20.2.0
# TERMUX_PKG_REVISION=1
# TERMUX_PKG_SRCURL=https://nodejs.org/dist/v${TERMUX_PKG_VERSION}/node-v${TERMUX_PKG_VERSION}.tar.xz
# TERMUX_PKG_SHA256=22523df2316c35569714ff1f69b053c2e286ced460898417dee46945efcdf989
#  # thunder-coding: don't try to autoupdate nodejs, that thing takes 2 whole hours to build for a single arch, and requires a lot of patch updates everytime. Also I run tests everytime I update it to ensure least bugs
# TERMUX_PKG_AUTO_UPDATE=false
# # Note that we do not use a shared libuv to avoid an issue with the Android
# # linker, which does not use symbols of linked shared libraries when resolving
# # symbols on dlopen(). See https://github.com/termux/termux-packages/issues/462.
# TERMUX_PKG_DEPENDS="libc++, openssl, c-ares, libicu, zlib"
# TERMUX_PKG_CONFLICTS="nodejs-lts, nodejs-current"
# TERMUX_PKG_BREAKS="nodejs-dev"
# TERMUX_PKG_REPLACES="nodejs-current, nodejs-dev"
# TERMUX_PKG_SUGGESTS="clang, make, pkg-config, python"
# TERMUX_PKG_RM_AFTER_INSTALL="lib/node_modules/npm/html lib/node_modules/npm/make.bat share/systemtap lib/dtrace"
# TERMUX_PKG_BUILD_IN_SRC=true
# TERMUX_PKG_HOSTBUILD=true
