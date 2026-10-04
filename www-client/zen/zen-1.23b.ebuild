# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Based on www-client/firefox's ebuild (Zen 1.23b is based on Firefox
# 157.0). The Gentoo firefox patchset does not apply to Zen; we fetch the
# non-musl subset of firefox-157-patches-01 as a distfile plus two build
# patches from the AUR zen-browser package (files/0004*, files/0005*).

LLVM_COMPAT=( 22 )

# This will also filter rust versions that don't match LLVM_COMPAT in the non-clang path; this is fine.
RUST_NEEDS_LLVM=1
RUST_MIN_VER=1.90.0

PYTHON_COMPAT=( python3_{12..14} )
PYTHON_REQ_USE="ncurses,sqlite,ssl"

VIRTUALX_REQUIRED="manual"

# Information about the bundled wasi toolchain from
# https://github.com/WebAssembly/wasi-sdk/
WASI_SDK_VER=34.0
WASI_SDK_LLVM_VER=23

# Gentoo firefox patchset, fetched as a distfile like the firefox ebuild
# does; we apply its non-musl subset.
FIREFOX_PATCHSET="firefox-157-patches-01.tar.xz"

HOMEPAGE="https://zen-browser.app/"
DESCRIPTION="Zen Browser, a Firefox-based browser focused on tranquillity and customization"

SRC_URI="https://github.com/zen-browser/desktop/releases/download/${PV}/zen.source.tar.zst -> zen-${PV}.source.tar.zst
	https://dev.gentoo.org/~juippis/mozilla/patchsets/${FIREFOX_PATCHSET}
	wasm-sandbox? (
		amd64? ( https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VER/.*/}/wasi-sdk-${WASI_SDK_VER}-x86_64-linux.tar.gz )
		arm64? ( https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VER/.*/}/wasi-sdk-${WASI_SDK_VER}-arm64-linux.tar.gz )
	)"

# The upstream release tarball is created with "tar -C engine ." (no
# top-level directory), so the tree unpacks directly into ${WORKDIR}.
S="${WORKDIR}"

inherit check-reqs desktop flag-o-matic gnome2-utils linux-info llvm-r1 multiprocessing \
	optfeature pax-utils python-any-r1 rust toolchain-funcs virtualx xdg

LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+clang dbus debug eme-free hardened hwaccel jack libproxy pgo pulseaudio selinux sndio"
IUSE+=" +system-av1 +system-harfbuzz +system-icu +system-jpeg +system-libevent +system-libvpx"
IUSE+=" system-pipewire system-png +system-webp test wayland wifi +X"

# Zen-specific IUSE
IUSE+=" +jpegxl +jumbo-build +telemetry wasm-sandbox"

REQUIRED_USE="|| ( X wayland )
	debug? ( !system-av1 )
	pgo? ( jumbo-build )
	wayland? ( dbus )
	wifi? ( dbus )
"

RESTRICT="mirror !test? ( test )"

BDEPEND="${PYTHON_DEPS}
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}
		llvm-core/llvm:${LLVM_SLOT}
		clang? (
			llvm-core/lld:${LLVM_SLOT}
			pgo? ( llvm-runtimes/compiler-rt-sanitizers:${LLVM_SLOT}[profile] )
		)
		wasm-sandbox? ( llvm-core/lld:${LLVM_SLOT} )
	')
	app-alternatives/awk
	app-arch/unzip
	app-arch/zip
	app-arch/zstd
	>=dev-util/cbindgen-0.29.4
	net-libs/nodejs
	virtual/pkgconfig
	amd64? ( >=dev-lang/nasm-2.14 )
	x86? ( >=dev-lang/nasm-2.14 )
	pgo? (
		X? (
			sys-devel/gettext
			x11-base/xorg-server[xvfb]
			x11-apps/xhost
		)
		!X? (
			gui-wm/tinywl
			x11-misc/xkeyboard-config
		)
	)"
COMMON_DEPEND=">=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/glib:2
	dev-libs/libffi:=
	>=dev-libs/nss-3.129
	>=dev-libs/nspr-4.39
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/mesa
	media-video/ffmpeg
	virtual/zlib:=
	virtual/freedesktop-icon-theme
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/libdrm
	x11-libs/pango
	x11-libs/pixman
	dbus? (
		sys-apps/dbus
	)
	jack? ( virtual/jack )
	pulseaudio? (
		|| (
			media-libs/libpulse
			>=media-sound/apulse-0.1.12-r4[sdk]
		)
	)
	libproxy? ( net-libs/libproxy )
	selinux? ( sec-policy/selinux-mozilla )
	sndio? ( >=media-sound/sndio-1.8.0-r1 )
	system-av1? (
		>=media-libs/dav1d-1.5.4:=
		>=media-libs/libaom-3.12.1:=
	)
	system-harfbuzz? (
		>=media-libs/harfbuzz-2.8.1:0=
		!wasm-sandbox? ( >=media-gfx/graphite2-1.3.13 )
	)
	system-icu? ( >=dev-libs/icu-78.1:= )
	system-jpeg? ( >=media-libs/libjpeg-turbo-1.2.1:= )
	system-libevent? ( >=dev-libs/libevent-2.1.12:0=[threads(+)] )
	system-libvpx? ( >=media-libs/libvpx-1.8.2:0=[postproc] )
	system-pipewire? ( >=media-video/pipewire-1.6.8:= )
	system-png? ( >=media-libs/libpng-1.6.45:0=[apng] )
	system-webp? ( >=media-libs/libwebp-1.1.0:0= )
	wayland? (
		>=media-libs/libepoxy-1.5.10-r1
		x11-libs/gtk+:3[wayland]
	)
	wifi? (
		kernel_linux? (
			|| (
				net-misc/networkmanager
				net-misc/connman[networkmanager]
			)
			sys-apps/dbus
		)
	)
	X? (
		virtual/opengl
		x11-libs/cairo[X]
		x11-libs/gtk+:3[X]
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXrandr
		x11-libs/libxcb:=
	)"
RDEPEND="${COMMON_DEPEND}
	hwaccel? (
		media-video/libva-utils
		sys-apps/pciutils
	)"
DEPEND="${COMMON_DEPEND}
	X? (
		x11-base/xorg-proto
		x11-libs/libICE
		x11-libs/libSM
	)"

llvm_check_deps() {
	if ! has_version -b "llvm-core/clang:${LLVM_SLOT}" ; then
		einfo "llvm-core/clang:${LLVM_SLOT} is missing! Cannot use LLVM slot ${LLVM_SLOT} ..." >&2
		return 1
	fi

	if use clang && ! tc-ld-is-mold ; then
		if ! has_version -b "llvm-core/lld:${LLVM_SLOT}" ; then
			einfo "llvm-core/lld:${LLVM_SLOT} is missing! Cannot use LLVM slot ${LLVM_SLOT} ..." >&2
			return 1
		fi
	fi

	if use pgo ; then
		if ! has_version -b "=llvm-runtimes/compiler-rt-sanitizers-${LLVM_SLOT}*[profile]" ; then
			einfo "=llvm-runtimes/compiler-rt-sanitizers-${LLVM_SLOT}*[profile] is missing!" >&2
			einfo "Cannot use LLVM slot ${LLVM_SLOT} ..." >&2
			return 1
		fi
	fi

	einfo "Using LLVM slot ${LLVM_SLOT} to build" >&2
}

mozconfig_add_options_ac() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${#} -lt 2 ]] ; then
		die "${FUNCNAME} requires at least two arguments"
	fi

	local reason=${1}
	shift

	local option
	for option in ${@} ; do
		echo "ac_add_options ${option} # ${reason}" >>${MOZCONFIG}
	done
}

mozconfig_add_options_mk() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${#} -lt 2 ]] ; then
		die "${FUNCNAME} requires at least two arguments"
	fi

	local reason=${1}
	shift

	local option
	for option in ${@} ; do
		echo "mk_add_options ${option} # ${reason}" >>${MOZCONFIG}
	done
}

mozconfig_use_enable() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${#} -lt 1 ]] ; then
		die "${FUNCNAME} requires at least one arguments"
	fi

	local flag=$(use_enable "${@}")
	mozconfig_add_options_ac "$(use ${1} && echo +${1} || echo -${1})" "${flag}"
}

mozconfig_use_with() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${#} -lt 1 ]] ; then
		die "${FUNCNAME} requires at least one arguments"
	fi

	local flag=$(use_with "${@}")
	mozconfig_add_options_ac "$(use ${1} && echo +${1} || echo -${1})" "${flag}"
}

moz_clear_vendor_checksums() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${#} -ne 1 ]] ; then
		die "${FUNCNAME} requires exact one argument"
	fi

	einfo "Clearing cargo checksums for ${1} ..."

	sed -i \
		-e 's/\("files":{\)[^}]*/\1/' \
		"${S}"/third_party/rust/${1}/.cargo-checksum.json || die
}

virtwl() {
	debug-print-function ${FUNCNAME} "$@"

	[[ $# -lt 1 ]] && die "${FUNCNAME} needs at least one argument"
	[[ -n $XDG_RUNTIME_DIR ]] || die "${FUNCNAME} needs XDG_RUNTIME_DIR to be set; try xdg_environment_reset"
	tinywl -h >/dev/null || die 'tinywl -h failed'

	local VIRTWL VIRTWL_PID
	coproc VIRTWL { WLR_BACKENDS=headless exec tinywl -s 'echo $WAYLAND_DISPLAY; read _; kill $PPID'; }
	local -x WAYLAND_DISPLAY
	read WAYLAND_DISPLAY <&${VIRTWL[0]}

	debug-print "${FUNCNAME}: $@"
	"$@"
	local r=$?

	[[ -n $VIRTWL_PID ]] || die "tinywl exited unexpectedly"
	exec {VIRTWL[0]}<&- {VIRTWL[1]}>&-
	return $r
}

pkg_pretend() {
	if [[ ${MERGE_TYPE} != binary ]] ; then
		# Ensure we have enough disk space to compile
		if use pgo || use debug ; then
			CHECKREQS_DISK_BUILD="18700M"
		elif tc-is-lto ; then
			CHECKREQS_DISK_BUILD="10900M"
		else
			CHECKREQS_DISK_BUILD="9700M"
		fi

		check-reqs_pkg_pretend
	fi
}

pkg_setup() {

	# Get LTO from environment; export after this phase for use in src_configure (etc)
	use_lto=no

	if [[ ${MERGE_TYPE} != binary ]] ; then

		if tc-is-lto; then
			use_lto=yes
			# LTO is handled via configure
			filter-lto
		fi

		if use pgo ; then
			if ! has userpriv ${FEATURES} ; then
				eerror "Building ${PN} with USE=pgo and FEATURES=-userpriv is not supported!"
			fi
		fi

		if [[ ${use_lto} = yes ]]; then
			# -Werror=lto-type-mismatch -Werror=odr are going to fail with GCC,
			# bmo#1516758, bgo#942288
			filter-flags -Werror=lto-type-mismatch -Werror=odr
		fi

		# Ensure we have enough disk space to compile
		if use pgo || use debug ; then
			CHECKREQS_DISK_BUILD="18700M"
		elif [[ ${use_lto} == "yes" ]] ; then
			CHECKREQS_DISK_BUILD="10900M"
		else
			CHECKREQS_DISK_BUILD="9700M"
		fi

		check-reqs_pkg_setup
		llvm-r1_pkg_setup
		rust_pkg_setup
		python-any-r1_pkg_setup

		# Avoid PGO profiling problems due to enviroment leakage
		# These should *always* be cleaned up anyway
		unset \
			DBUS_SESSION_BUS_ADDRESS \
			DISPLAY \
			ORBIT_SOCKETDIR \
			SESSION_MANAGER \
			XAUTHORITY \
			XDG_CACHE_HOME \
			XDG_SESSION_COOKIE

		# Build system is using /proc/self/oom_score_adj, bug #604394
		addpredict /proc/self/oom_score_adj

		if use pgo ; then
			# Update 105.0: "/proc/self/oom_score_adj" isn't enough anymore with pgo, but not sure
			# whether that's due to better OOM handling by Firefox (bmo#1771712), or portage
			# (PORTAGE_SCHEDULING_POLICY) update...
			addpredict /proc

			# Clear tons of conditions, since PGO is hardware-dependant.
			addpredict /dev
		fi

		if ! mountpoint -q /dev/shm ; then
			# If /dev/shm is not available, configure is known to fail with
			# a traceback report referencing /usr/lib/pythonN.N/multiprocessing/synchronize.py
			ewarn "/dev/shm is not mounted -- expect build failures!"
		fi

		# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
		# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
		# get your own set of keys.
		if [[ -z "${MOZ_API_KEY_GOOGLE+set}" ]] ; then
			MOZ_API_KEY_GOOGLE="AIzaSyDEAOvatFogGaPi0eTgsV_ZlEzx0ObmepsMzfAc"
		fi

		if [[ -z "${MOZ_API_KEY_LOCATION+set}" ]] ; then
			MOZ_API_KEY_LOCATION="AIzaSyB2h2OuRgGaPicUgy5N-5hsZqiPW6sH3n_rptiQ"
		fi

		# Mozilla API keys (see https://location.services.mozilla.com/api)
		# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
		# get your own set of keys.
		if [[ -z "${MOZ_API_KEY_MOZILLA+set}" ]] ; then
			MOZ_API_KEY_MOZILLA="edb3d487-3a84-46m0ap1e3-9dfd-92b5efaaa005"
		fi

		# Ensure we use C locale when building, bug #746215
		export LC_ALL=C
	fi

	export use_lto

	CONFIG_CHECK="~SECCOMP"
	WARNING_SECCOMP="CONFIG_SECCOMP not set! This system will be unable to play DRM-protected content."
	linux-info_pkg_setup
}

src_unpack() {
	# unpack() has no .tar.zst handler (the suffix is not in the PMS list)
	# and the tarball has no top-level directory; extract it into ${S}.
	tar --zstd -xf "${DISTDIR}"/zen-${PV}.source.tar.zst -C "${WORKDIR}" || die

	# Gentoo firefox patchset (unpacks to ${WORKDIR}/firefox-patches)
	unpack "${FIREFOX_PATCHSET}"

	if use wasm-sandbox ; then
		local wasi_arch
		if use amd64 ; then
			wasi_arch="x86_64"
		elif use arm64 ; then
			wasi_arch="arm64"
		else
			die "wasm-sandbox enabled on unknown/unsupported arch!"
		fi
		unpack "wasi-sdk-${WASI_SDK_VER}-${wasi_arch}-linux.tar.gz"
	fi
}

src_prepare() {
	local patch
	# Gentoo firefox patchset: keep the non-musl subset only.
	rm -f "${WORKDIR}"/firefox-patches/*musl* \
		"${WORKDIR}"/firefox-patches/*RUST_TARGET_override* || die
	for patch in "${WORKDIR}"/firefox-patches/*.patch ; do
		# Conflicts with a full-LTO build (the firefox ebuild drops it too).
		if [[ ${patch} == *LTO-Only-enable-LTO* && ${use_lto} == yes ]] ; then
			einfo "Skipping ${patch##*/} (building with LTO)"
			continue
		fi
		eapply "${patch}"
	done

	# Build fixes from the AUR zen-browser package.
	eapply "${FILESDIR}"/0004-use-wasm32-wasip1-target.patch
	eapply "${FILESDIR}"/0005-cbindgen-budgettype-count.patch

	# Allow user to apply any additional patches without modifying ebuild
	eapply_user

	# Clear checksums from cargo crates we've manually patched.
	moz_clear_vendor_checksums bindgen

	# Like upstream's build tooling (surfer): brand the engine version files
	# with the Zen version, so the browser reports "${PV}" (About dialog).
	printf '%s' "${PV}" > browser/config/version.txt || die
	printf '%s' "${PV}" > browser/config/version_display.txt || die

	# Make cargo respect MAKEOPTS
	export CARGO_BUILD_JOBS="$(makeopts_jobs)"

	# Pre-built wasm-sandbox path manipulation.
	if use wasm-sandbox ; then
		if use amd64 ; then
			export wasi_arch="x86_64"
		elif use arm64 ; then
			export wasi_arch="arm64"
		else
			die "wasm-sandbox enabled on unknown/unsupported arch!"
		fi

		sed -i \
			-e "s:%%PORTAGE_WORKDIR%%:${WORKDIR}:" \
			-e "s:%%WASI_ARCH%%:${wasi_arch}:" \
			-e "s:%%WASI_SDK_VER%%:${WASI_SDK_VER}:" \
			-e "s:%%WASI_SDK_LLVM_VER%%:${WASI_SDK_LLVM_VER}:" \
			toolkit/moz.configure || die "Failed to update wasi-related paths."
	fi

	# Make LTO respect MAKEOPTS
	sed -i -e "s/multiprocessing.cpu_count()/$(makeopts_jobs)/" \
		"${S}"/build/moz.configure/lto-pgo.configure || die "Failed sedding multiprocessing.cpu_count"

	sed -i -e "s/multiprocessing.cpu_count()/$(makeopts_jobs)/" \
		"${S}"/third_party/chromium/build/toolchain/get_cpu_count.py || die "Failed sedding multiprocessing.cpu_count"

	sed -i -e "s/multiprocessing.cpu_count()/$(makeopts_jobs)/" \
		"${S}"/third_party/python/gyp/pylib/gyp/input.py || die "Failed sedding multiprocessing.cpu_count"

	# sed-in toolchain prefix
	sed -i \
		-e "s/objdump/${CHOST}-objdump/" \
		"${S}"/python/mozbuild/mozbuild/configure/check_debug_ranges.py || die "sed failed to set toolchain prefix"

	sed -i \
		-e 's/ccache_stats = None/return None/' \
		"${S}"/python/mozbuild/mozbuild/controller/building.py || die "sed failed to disable ccache stats call"

	einfo "Removing pre-built binaries ..."

	find "${S}"/third_party -type f \( -name '*.so' -o -name '*.o' \) -print -delete || die

	# Respect choice for "jumbo-build"
	# Changing the value for FILES_PER_UNIFIED_FILE may not work, see #905431
	if [[ -n ${FILES_PER_UNIFIED_FILE} ]] && use jumbo-build; then
		local my_files_per_unified_file=${FILES_PER_UNIFIED_FILE:=16}
		elog ""
		elog "jumbo-build defaults modified to ${my_files_per_unified_file}."
		elog "if you get a build failure, try undefining FILES_PER_UNIFIED_FILE,"
		elog "if that fails try -jumbo-build before opening a bug report."
		elog ""

		sed -i -e "s/\"FILES_PER_UNIFIED_FILE\", 16/\"FILES_PER_UNIFIED_FILE\", "${my_files_per_unified_file}"/" \
			python/mozbuild/mozbuild/frontend/data.py ||
				die "Failed to adjust FILES_PER_UNIFIED_FILE in python/mozbuild/mozbuild/frontend/data.py"
		sed -i -e "s/FILES_PER_UNIFIED_FILE = 6/FILES_PER_UNIFIED_FILE = "${my_files_per_unified_file}"/" \
			js/src/moz.build ||
				die "Failed to adjust FILES_PER_UNIFIED_FILE in js/src/moz.build"
	fi

	# Create build dir
	BUILD_DIR="${WORKDIR}/${PN}_build"
	mkdir -p "${BUILD_DIR}" || die

	# Write API keys to disk
	echo -n "${MOZ_API_KEY_GOOGLE//gGaPi/}" > "${S}"/api-google.key || die
	echo -n "${MOZ_API_KEY_LOCATION//gGaPi/}" > "${S}"/api-location.key || die
	echo -n "${MOZ_API_KEY_MOZILLA//m0ap1/}" > "${S}"/api-mozilla.key || die

	xdg_environment_reset
}

src_configure() {
	# Show flags set at the beginning
	einfo "Current BINDGEN_CFLAGS:\t${BINDGEN_CFLAGS:-no value set}"
	einfo "Current CFLAGS:\t\t${CFLAGS:-no value set}"
	einfo "Current CXXFLAGS:\t\t${CXXFLAGS:-no value set}"
	einfo "Current LDFLAGS:\t\t${LDFLAGS:-no value set}"
	einfo "Current RUSTFLAGS:\t\t${RUSTFLAGS:-no value set}"

	local have_switched_compiler=
	if use clang; then
		# Force clang
		einfo "Enforcing the use of clang due to USE=clang ..."

		local version_clang=$(clang --version 2>/dev/null | grep -F -- 'clang version' | awk '{ print $3 }')
		[[ -n ${version_clang} ]] && version_clang=$(ver_cut 1 "${version_clang}")
		[[ -z ${version_clang} ]] && die "Failed to read clang version!"

		if tc-is-gcc; then
			have_switched_compiler=yes
		fi

		AR=llvm-ar
		CC=${CHOST}-clang-${version_clang}
		CXX=${CHOST}-clang++-${version_clang}
		NM=llvm-nm
		RANLIB=llvm-ranlib
	elif ! use clang && ! tc-is-gcc ; then
		# Force gcc
		have_switched_compiler=yes
		einfo "Enforcing the use of gcc due to USE=-clang ..."
		AR=gcc-ar
		CC=${CHOST}-gcc
		CXX=${CHOST}-g++
		NM=gcc-nm
		RANLIB=gcc-ranlib
	fi

	if [[ -n "${have_switched_compiler}" ]] ; then
		# Because we switched active compiler we have to ensure
		# that no unsupported flags are set
		strip-unsupported-flags
	fi

	# Ensure we use correct toolchain,
	# AS is used in a non-standard way by upstream, #bmo1654031
	export HOST_CC="$(tc-getBUILD_CC)"
	export HOST_CXX="$(tc-getBUILD_CXX)"
	export AS="$(tc-getCC) -c"

	# Configuration tests expect llvm-readelf output, bug 913130
	READELF="llvm-readelf"

	tc-export CC CXX LD AR AS NM OBJDUMP RANLIB READELF PKG_CONFIG

	# Pass the correct toolchain paths through cbindgen
	if tc-is-cross-compiler ; then
		export BINDGEN_CFLAGS="${SYSROOT:+--sysroot=${ESYSROOT}} --target=${CHOST} ${BINDGEN_CFLAGS-}"
	fi

	# Set MOZILLA_FIVE_HOME
	export MOZILLA_FIVE_HOME="/usr/$(get_libdir)/${PN}"

	# python/mach/mach/mixin/process.py fails to detect SHELL
	export SHELL="${EPREFIX}/bin/bash"

	export MOZBUILD_STATE_PATH="${BUILD_DIR}"
	export MOZCONFIG="${S}/.mozconfig"

	# Start from a clean mozconfig (a re-run must not append duplicate blocks)
	: > "${MOZCONFIG}" || die

	# Initialize MOZCONFIG
	mozconfig_add_options_ac '' --enable-application=browser
	mozconfig_add_options_ac '' --enable-project=browser

	# Shipped build: unlocks the Zen first-run defaults in zen.js (the OOBE,
	# watermark, marketplace injections, mods auto-update, ...).  Not tied to
	# USE=telemetry -- -telemetry is handled by MOZ_*REPORTING=0 below and by
	# zen-telemetry-prefs.js.
	export MOZILLA_OFFICIAL=1
	# Written in both forms like upstream's mozconfig: only
	# `mk_add_options "export ..."` entries are re-exported into the
	# configure environment by mach (a plain `export` line is not).
	echo "mk_add_options \"export MOZILLA_OFFICIAL=1\" # Zen official build" >>${MOZCONFIG} || die

	mozconfig_add_options_ac 'Gentoo default' \
		--allow-addon-sideload \
		--disable-cargo-incremental \
		--disable-crashreporter \
		--disable-disk-remnant-avoidance \
		--disable-geckodriver \
		--disable-install-strip \
		--disable-legacy-profile-creation \
		--disable-parental-controls \
		--disable-strip \
		--disable-updater \
		--enable-negotiateauth \
		--enable-new-pass-manager \
		--enable-packed-relative-relocs \
		--enable-release \
		--enable-system-policies \
		--host="${CBUILD:-${CHOST}}" \
		--libdir="${EPREFIX}/usr/$(get_libdir)" \
		--prefix="${EPREFIX}/usr" \
		--target="${CHOST}" \
		--without-ccache \
		--with-intl-api \
		--with-libclang-path="$(llvm-config --libdir)" \
		--with-system-ffi \
		--with-system-gbm \
		--with-system-libdrm \
		--with-system-nspr \
		--with-system-nss \
		--with-system-pixman \
		--with-system-zlib \
		--with-toolchain-prefix="${CHOST}-" \
		--with-unsigned-addon-scopes=app,system

	# Zen identity/branding (as in upstream's surfer.json and
	# configs/common/mozconfig).  The directory must be selected with
	# --with-branding: MOZ_BRANDING_DIRECTORY and
	# MOZ_OFFICIAL_BRANDING_DIRECTORY are confvars (settable only from
	# confvars.sh, see toolkit/moz.configure), so setting them in the
	# environment does nothing and the stock browser/confvars.sh values would
	# leak Firefox branding into the UI (window title, about dialog).
	# browser/branding/release holds the Zen logo and brand.ftl and is what
	# the official release binaries are built with.  --enable-official-branding
	# must stay off: it takes precedence over --with-branding and would force
	# browser/branding/official.
	mozconfig_add_options_ac 'Zen upstream' \
		--with-app-name=zen \
		--with-app-basename=Zen \
		--with-branding=browser/branding/release \
		--with-distribution-id=app.zen-browser \
		--with-l10n-base="${S}/browser/locales"

	export MOZ_APP_REMOTINGNAME=zen

	mozconfig_add_options_ac '' --enable-update-channel=release

	# Whitelist to allow unkeyworded arches to build with "--disable-rust-simd" by default.
	if use amd64 || use arm64 || use ppc64 || use loong || use riscv ; then
		mozconfig_add_options_ac '' --enable-rust-simd
	fi

	# Sandbox is currently (97.0) only supported on amd64, arm, arm64 & x86,
	# bug 833001, bug 903411#c8
	if use loong || use ppc64 || use riscv; then
		mozconfig_add_options_ac '' --disable-sandbox
	else
		mozconfig_add_options_ac '' --enable-sandbox
	fi

	# riscv-related options, bgo#947337, bgo#947338, bgo#977845
	if use riscv ; then
		mozconfig_add_options_ac 'Disable webrtc for RISC-V' --disable-webrtc
	fi

	if [[ -s "${S}/api-google.key" ]] ; then
		local key_origin="Gentoo default"
		if [[ $(cat "${S}/api-google.key" | md5sum | awk '{ print $1 }') != 709560c02f94b41f9ad2c49207be6c54 ]] ; then
			key_origin="User value"
		fi

		mozconfig_add_options_ac "${key_origin}" \
			--with-google-safebrowsing-api-keyfile="${S}/api-google.key"
	else
		einfo "Building without Google API key ..."
	fi

	if [[ -s "${S}/api-location.key" ]] ; then
		local key_origin="Gentoo default"
		if [[ $(cat "${S}/api-location.key" | md5sum | awk '{ print $1 }') != ffb7895e35dedf832eb1c5d420ac7420 ]] ; then
			key_origin="User value"
		fi

		mozconfig_add_options_ac "${key_origin}" \
			--with-google-location-service-api-keyfile="${S}/api-location.key"
	else
		einfo "Building without Location API key ..."
	fi

	if [[ -s "${S}/api-mozilla.key" ]] ; then
		local key_origin="Gentoo default"
		if [[ $(cat "${S}/api-mozilla.key" | md5sum | awk '{ print $1 }') != 3927726e9442a8e8fa0e46ccc39caa27 ]] ; then
			key_origin="User value"
		fi

		mozconfig_add_options_ac "${key_origin}" \
			--with-mozilla-api-keyfile="${S}/api-mozilla.key"
	else
		einfo "Building without Mozilla API key ..."
	fi

	mozconfig_use_with system-av1
	mozconfig_use_with system-harfbuzz
	mozconfig_use_with system-icu
	mozconfig_use_with system-jpeg
	mozconfig_use_with system-libevent
	mozconfig_use_with system-libvpx
	mozconfig_use_with system-pipewire
	mozconfig_use_with system-png
	mozconfig_use_with system-webp

	mozconfig_use_enable dbus
	mozconfig_use_enable libproxy
	mozconfig_use_enable jumbo-build unified-build

	use eme-free && mozconfig_add_options_ac '+eme-free' --disable-eme

	if use hardened ; then
		mozconfig_add_options_ac "+hardened" --enable-hardening
		mozconfig_add_options_ac "+hardened stl" --enable-stl-hardening
		append-ldflags "-Wl,-z,relro -Wl,-z,now"

		# Increase the FORTIFY_SOURCE value, #910071.
		sed -i -e '/-D_FORTIFY_SOURCE=/s:2:3:' "${S}"/build/moz.configure/toolchain.configure || die
	fi

	local myaudiobackends=""
	use jack && myaudiobackends+="jack,"
	use sndio && myaudiobackends+="sndio,"
	use pulseaudio && myaudiobackends+="pulseaudio,"
	! use pulseaudio && myaudiobackends+="alsa,"

	mozconfig_add_options_ac '--enable-audio-backends' --enable-audio-backends="${myaudiobackends::-1}"

	mozconfig_use_enable wifi necko-wifi

	if use X && use wayland ; then
		mozconfig_add_options_ac '+x11+wayland' --enable-default-toolkit=cairo-gtk3-x11-wayland
	elif ! use X && use wayland ; then
		mozconfig_add_options_ac '+wayland' --enable-default-toolkit=cairo-gtk3-wayland-only
	else
		mozconfig_add_options_ac '+x11' --enable-default-toolkit=cairo-gtk3-x11-only
	fi

	# wasm-sandbox
	# Since graphite2 is one of the sandboxed libraries, system-graphite2 obviously can't work with +wasm-sandbox.
	if use wasm-sandbox ; then
		mozconfig_add_options_ac '+wasm-sandbox' --with-wasi-sysroot="${WORKDIR}/wasi-sdk-${WASI_SDK_VER}-${wasi_arch}-linux/share/wasi-sysroot/"
	else
		mozconfig_add_options_ac 'no wasm-sandbox' --without-wasm-sandboxed-libraries
		mozconfig_use_with system-harfbuzz system-graphite2
	fi

	# Zen upstream enables JXL by default (configs/common/mozconfig: --enable-jxl).
	if use jpegxl ; then
		mozconfig_add_options_ac '+jpegxl' --enable-jxl
	else
		mozconfig_add_options_ac '-jpegxl' --disable-jxl
	fi

	if [[ ${use_lto} == "yes" ]] ; then
		if use clang ; then
			# Upstream only supports lld or mold when using clang.
			if tc-ld-is-mold ; then
				# mold expects the -flto line from *FLAGS configuration, bgo#923119
				append-ldflags "-flto=thin"
				mozconfig_add_options_ac "using ld=mold due to system selection" --enable-linker=mold
			else
				mozconfig_add_options_ac "forcing ld=lld due to USE=clang and USE=lto" --enable-linker=lld
			fi

			mozconfig_add_options_ac '+lto' --enable-lto=cross

		else
			# ThinLTO is currently broken, see bmo#1644409.
			# mold does not support gcc+lto combination.
			mozconfig_add_options_ac '+lto' --enable-lto=full
			mozconfig_add_options_ac "linker is set to bfd" --enable-linker=bfd
		fi

	else
		# Avoid auto-magic on linker
		if use clang ; then
			# lld is upstream's default
			if tc-ld-is-mold ; then
				mozconfig_add_options_ac "using ld=mold due to system selection" --enable-linker=mold
			else
				mozconfig_add_options_ac "forcing ld=lld due to USE=clang" --enable-linker=lld
			fi

		else
			if tc-ld-is-mold ; then
				mozconfig_add_options_ac "using ld=mold due to system selection" --enable-linker=mold
			else
				mozconfig_add_options_ac "linker is set to bfd due to USE=-clang" --enable-linker=bfd
			fi
		fi
	fi

	# PGO was moved outside lto block to allow building pgo without lto.
	if use pgo ; then
		mozconfig_add_options_ac '+pgo' MOZ_PGO=1

		# Avoid compressing just-built instrumented Firefox with
		# high levels of compression. Just use tar as a container
		# to save >=10 minutes.
		export MOZ_PKG_FORMAT=TAR

		if use clang ; then
			# Used in build/pgo/profileserver.py
			export LLVM_PROFDATA="llvm-profdata"
		else
			# Attempt to fix pgo hanging with gcc, bgo#966309.
			export MOZ_REMOTE_SETTINGS_DEVTOOLS=1
		fi
	fi

	mozconfig_use_enable debug
	if use debug ; then
		mozconfig_add_options_ac '+debug' --disable-optimize
		mozconfig_add_options_ac '+debug' --enable-jemalloc
		mozconfig_add_options_ac '+debug' --enable-real-time-tracing
	else
		mozconfig_add_options_ac 'Gentoo defaults' --disable-real-time-tracing

		if is-flag '-g*' ; then
			if use clang ; then
				mozconfig_add_options_ac 'from CFLAGS' --enable-debug-symbols=$(get-flag '-g*')
			else
				mozconfig_add_options_ac 'from CFLAGS' --enable-debug-symbols
			fi
		else
			mozconfig_add_options_ac 'Gentoo default' --disable-debug-symbols
		fi

		if is-flag '-O0' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O0
		elif is-flag '-O4' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O4
		elif is-flag '-O3' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O3
		elif is-flag '-O1' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O1
		elif is-flag '-Os' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-Os
		else
			mozconfig_add_options_ac "Gentoo default" --enable-optimize=-O2
		fi
	fi

	# Debug flag was handled via configure
	filter-flags '-g*'

	# Optimization flag was handled via configure
	filter-flags '-O*'

	# elf-hack
	# Filter "-z,pack-relative-relocs" and let the build system handle it instead.
	if use amd64 || use x86 ; then
		filter-flags "-z,pack-relative-relocs"

		if tc-ld-is-mold ; then
			# relr-elf-hack is currently broken with mold, bgo#916259
			mozconfig_add_options_ac 'disable elf-hack with mold linker' --disable-elf-hack
		else
			mozconfig_add_options_ac 'relr elf-hack' --enable-elf-hack=relr
		fi
	elif use loong || use ppc64 || use riscv ; then
		# '--disable-elf-hack' is not recognized on loong/ppc64/riscv,
		# see bgo #917049, #930046
		:;
	else
		mozconfig_add_options_ac 'disable elf-hack on non-supported arches' --disable-elf-hack
	fi

	if ! use elibc_glibc; then
		mozconfig_add_options_ac '!elibc_glibc' --disable-jemalloc
	fi

	# System-av1 fix
	use system-av1 && append-ldflags "-Wl,--undefined-version"

	# Make revdep-rebuild.sh happy; Also required for musl
	append-ldflags -Wl,-rpath="${MOZILLA_FIVE_HOME}",--enable-new-dtags

	# Pass $MAKEOPTS to build system
	export MOZ_MAKE_FLAGS="${MAKEOPTS}"

	# Use system's Python environment
	export PIP_NETWORK_INSTALL_RESTRICTED_VIRTUALENVS=mach

	export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE="none"

	if ! use telemetry; then
		mozconfig_add_options_mk '-telemetry setting' "MOZ_CRASHREPORTER=0"
		mozconfig_add_options_mk '-telemetry setting' "MOZ_DATA_REPORTING=0"
		mozconfig_add_options_mk '-telemetry setting' "MOZ_SERVICES_HEALTHREPORT=0"
		mozconfig_add_options_mk '-telemetry setting' "MOZ_TELEMETRY_REPORTING=0"
	fi

	mozconfig_use_enable test tests

	# Disable notification when build system has finished
	export MOZ_NOSPAM=1

	# Portage sets XARGS environment variable to "xargs -r" by default which
	# breaks build system's check_prog() function which doesn't support arguments
	mozconfig_add_options_ac 'Gentoo default' "XARGS=${EPREFIX}/usr/bin/xargs"

	mozconfig_add_options_mk 'Gentoo default' "MOZ_OBJDIR=${BUILD_DIR}"

	# Show flags we will use
	einfo "Build BINDGEN_CFLAGS:\t${BINDGEN_CFLAGS:-no value set}"
	einfo "Build CFLAGS:\t\t${CFLAGS:-no value set}"
	einfo "Build CXXFLAGS:\t\t${CXXFLAGS:-no value set}"
	einfo "Build LDFLAGS:\t\t${LDFLAGS:-no value set}"
	einfo "Build RUSTFLAGS:\t\t${RUSTFLAGS:-no value set}"

	# Handle EXTRA_CONF and show summary
	local ac opt hash reason

	# Apply EXTRA_ECONF entries to $MOZCONFIG
	if [[ -n ${EXTRA_ECONF} ]] ; then
		IFS=\! read -a ac <<<${EXTRA_ECONF// --/\!}
		for opt in "${ac[@]}"; do
			mozconfig_add_options_ac "EXTRA_ECONF" --${opt#--}
		done
	fi

	echo
	echo "=========================================================="
	echo "Building ${PF} with the following configuration"
	grep ^ac_add_options "${MOZCONFIG}" | while read ac opt hash reason; do
		[[ -z ${hash} || ${hash} == \# ]] \
			|| die "error reading mozconfig: ${ac} ${opt} ${hash} ${reason}"
		printf "    %-30s  %s\n" "${opt}" "${reason:-mozilla.org default}"
	done
	echo "=========================================================="
	echo

	./mach configure || die
}

src_compile() {
	local virtx_cmd=

	if [[ ${use_lto} == "yes" ]] && tc-ld-is-mold ; then
		# increase ulimit with mold+lto, bugs #892641, #907485
		if ! ulimit -n 16384 1>/dev/null 2>&1 ; then
			ewarn "Unable to modify ulimits - building with mold+lto might fail due to low ulimit -n resources."
			ewarn "Please see bugs #892641 & #907485."
		else
			ulimit -n 16384
		fi
	fi

	if use pgo; then
		# Reset and cleanup environment variables used by GNOME/XDG
		gnome2_environment_reset

		addpredict /root

		if ! use X; then
			virtx_cmd=virtwl
		else
			virtx_cmd=virtx
		fi
	fi

	if ! use X; then
		local -x GDK_BACKEND=wayland
	else
		local -x GDK_BACKEND=x11
	fi

	${virtx_cmd} ./mach build --verbose || die

	# Build a language pack (XPI) for every shipped locale, as Debian's
	# firefox-l10n packages do.  The in-build MOZ_CHROME_MULTILOCALE path
	# cannot be used: it requires legacy chrome dirs that the Fluent-only
	# locale data no longer ships.
	local lang
	for lang in "${S}"/browser/locales/*/ ; do
		lang=${lang%/}
		lang=${lang##*/}
		[[ ${lang} == en-US ]] && continue
		einfo "Building language pack: ${lang}"
		# The manifest's compatibility range is checked against the
		# *platform* version (157.0), so the default maximum derived from
		# MOZ_APP_VERSION ("1.*") would make every pack incompatible.  A
		# numeric maximum avoids that ("*" would be shell-globbed in make).
		emake -C "${BUILD_DIR}/browser/locales" "langpack-${lang}" \
			MOZ_CHROME_FILE_FORMAT=flat \
			MOZ_APP_MAXVERSION="9999" \
			MOZ_LANGPACK_EID="langpack-${lang}@zen-browser.app" \
			PKG_LANGPACK_BASENAME="langpack-${lang}@zen-browser.app" \
			PKG_LANGPACK_PATH=xpi/ \
			|| die "Building language pack for ${lang} failed"
	done
}

src_test() {
	# https://firefox-source-docs.mozilla.org/testing/automated-testing/index.html
	local -a failures=()

	# Some tests respect this
	local -x MOZ_HEADLESS=1

	# Check testing/mach_commands.py
	einfo "Testing with cppunittest ..."
	./mach cppunittest
	local ret=$?
	if [[ ${ret} -ne 0 ]]; then
		eerror "Test suite cppunittest failed with error code ${ret}"
		failures+=( cppunittest )
	fi

	if [[ ${#failures} -eq 0 ]]; then
		einfo "Test suites succeeded"
	else
		die "Test suites failed: ${failures[@]}"
	fi
}

src_install() {
	# xpcshell is getting called during install
	local bin
	for bin in xpcshell zen zen-bin plugin-container ; do
		if [[ -e "${BUILD_DIR}"/dist/bin/${bin} ]] ; then
			pax-mark m "${BUILD_DIR}"/dist/bin/${bin}
		fi
	done

	DESTDIR="${D}" ./mach install || die

	# Upstream cannot ship symlink but we can (bmo#658850)
	if [[ -e "${ED}${MOZILLA_FIVE_HOME}/${PN}-bin" ]] ; then
		rm "${ED}${MOZILLA_FIVE_HOME}/${PN}-bin" || die
		dosym ${PN} ${MOZILLA_FIVE_HOME}/${PN}-bin
	fi

	# Don't install llvm-symbolizer from llvm-core/llvm package
	if [[ -f "${ED}${MOZILLA_FIVE_HOME}/llvm-symbolizer" ]] ; then
		rm -v "${ED}${MOZILLA_FIVE_HOME}/llvm-symbolizer" || die
	fi

	# The updater is disabled at configure time; drop any leftovers.
	rm -f "${ED}${MOZILLA_FIVE_HOME}"/updater \
		"${ED}${MOZILLA_FIVE_HOME}"/updater.ini \
		"${ED}${MOZILLA_FIVE_HOME}"/update-settings.ini

	# Disable application self-updates at runtime, too
	insinto "${MOZILLA_FIVE_HOME}/distribution"
	doins "${FILESDIR}"/policies.json

	# Install system-wide preferences
	local PREFS_DIR="${MOZILLA_FIVE_HOME}/browser/defaults/preferences"
	insinto "${PREFS_DIR}"
	newins "${FILESDIR}"/zen-prefs.js zen-prefs.js

	local ZEN_PREFS="${ED}${PREFS_DIR}/zen-prefs.js"

	# Set dictionary path to use system hunspell
	cat >>"${ZEN_PREFS}" <<-EOF || die "failed to set spellchecker.dictionary_path pref"
	pref("spellchecker.dictionary_path", "${EPREFIX}/usr/share/myspell");
	EOF

	# Force hwaccel prefs if USE=hwaccel is enabled
	if use hwaccel ; then
		cat "${FILESDIR}"/zen-hwaccel-prefs.js \
		>>"${ZEN_PREFS}" \
		|| die "failed to add prefs to force hardware-accelerated rendering to zen-prefs.js"

		if use wayland; then
			cat >>"${ZEN_PREFS}" <<-EOF || die "failed to set hwaccel wayland prefs"
			pref("gfx.x11-egl.force-enabled", false);
			EOF
		else
			cat >>"${ZEN_PREFS}" <<-EOF || die "failed to set hwaccel x11 prefs"
			pref("gfx.x11-egl.force-enabled", true);
			EOF
		fi

		# Install the gfxtest binary on supported arches
		exeinto "${MOZILLA_FIVE_HOME}"
		doexe "${BUILD_DIR}"/dist/bin/gfxtest
	fi

	# Force the graphite pref if USE=system-harfbuzz is enabled, since the pref cannot disable it
	if use system-harfbuzz ; then
		cat >>"${ZEN_PREFS}" <<-EOF || die "failed to set gfx.font_rendering.graphite.enabled pref"
		sticky_pref("gfx.font_rendering.graphite.enabled", true);
		EOF
	fi

	# Add telemetry config prefs, just in case something happens in future and telemetry build
	# options stop working.
	if ! use telemetry ; then
		cat "${FILESDIR}"/zen-telemetry-prefs.js >>"${ZEN_PREFS}" || die "failed to set telemetry prefs"
	fi

	if use jpegxl ; then
		cat >>"${ZEN_PREFS}" <<-EOF || die "failed to enable jpegxl via pref"
		pref("image.jxl.enabled", true);
		EOF
	fi

	# Install the language packs built in src_compile (the browser's
	# language picker reads app-scoped XPIs from here).
	if compgen -G "${BUILD_DIR}/dist/xpi/langpack-*.xpi" > /dev/null ; then
		insinto "${MOZILLA_FIVE_HOME}/browser/extensions"
		doins "${BUILD_DIR}"/dist/xpi/langpack-*.xpi || die
	fi

	# Install icons
	local icon_srcdir="${S}/browser/branding/release"

	local icon size
	for icon in "${icon_srcdir}"/default*.png ; do
		size=${icon%.png}
		size=${size##*/default}

		if [[ ${size} -eq 48 ]] ; then
			newicon "${icon}" ${PN}.png
		fi

		newicon -s ${size} "${icon}" ${PN}.png
	done

	# Install menu
	newmenu "${FILESDIR}"/zen.desktop ${PN}.desktop

	# Install wrapper script
	[[ -f "${ED}/usr/bin/${PN}" ]] && rm "${ED}/usr/bin/${PN}"
	newbin "${FILESDIR}"/zen.sh ${PN}

	# Update wrapper
	local use_wayland="false"
	if use wayland ; then
		use_wayland="true"
	fi

	sed -i \
		-e "s:@MOZILLA_FIVE_HOME@:${EPREFIX}${MOZILLA_FIVE_HOME}:" \
		-e "s:@DEFAULT_WAYLAND@:${use_wayland}:" \
		"${ED}/usr/bin/${PN}" || die
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature_header "Optional programs for extra features:"
	optfeature "desktop notifications" x11-libs/libnotify
	optfeature "fallback mouse cursor theme e.g. on WMs" gnome-base/gsettings-desktop-schemas
	optfeature "screencasting with pipewire" sys-apps/xdg-desktop-portal
}
