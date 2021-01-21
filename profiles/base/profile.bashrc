# Copyright 2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/profiles/base/profile.bashrc,v 1.3 2009/07/21 00:08:05 zmedico Exp $

# Set LANG=C globally because it speeds up build times, and we don't need
# localized messages inside of our builds.
export LANG=C

# Since unittests on the buildbots don't automatically get access to an
# X server, don't let local dev stations get access either.  If a test
# really needs an X server, they should launch their own with Xvfb.
unset DISPLAY

if ! declare -F elog >/dev/null ; then
	elog() {
		einfo "$@"
	}
fi

# Dumping ground for build-time helpers to utilize since SYSROOT/tmp/
# can be nuked at any time.
CROS_BUILD_BOARD_TREE="${SYSROOT}/build"
CROS_BUILD_BOARD_BIN="${CROS_BUILD_BOARD_TREE}/bin"

CROS_ADDONS_TREE="/usr/local/portage/chromiumos/chromeos"

# Are we merging for the board sysroot, or for the cros sdk, or for
# the target hardware?  Returns a string:
#  - cros_host (the sdk)
#  - board_sysroot
#  - target_image
# We can't rely on "use cros_host" as USE gets filtred based on IUSE,
# and not all packages have IUSE=cros_host.
cros_target() {
	if [[ ${CROS_SDK_HOST} == "cros-sdk-host" ]] ; then
		echo "cros_host"
	elif [[ "${SYSROOT:-/}" != "/" && "${ROOT%/}" == "${SYSROOT%/}" ]] ; then
		echo "board_sysroot"
	else
		echo "target_image"
	fi
}

# Load all additional bashrc files we have for this package.
cros_stack_bashrc() {
	local cfg cfgd

	# Old location.
	cfgd="${CROS_ADDONS_TREE}/config/env"
	for cfg in ${PN} ${PN}-${PV} ${PN}-${PV}-${PR} ; do
		cfg="${cfgd}/${CATEGORY}/${cfg}"
		[[ -f ${cfg} ]] && . "${cfg}"
	done

	# New location.
	cfgd="/mnt/host/source/src/third_party/chromiumos-overlay/${CATEGORY}/${PN}"
	export BASHRC_FILESDIR="${cfgd}/files"
	for cfg in ${PN} ${P} ${PF} ; do
		cfg="${cfgd}/${cfg}.bashrc"
		[[ -f ${cfg} ]] && . "${cfg}"
	done
}
cros_stack_bashrc

# The standard bashrc hooks do not stack.  So take care of that ourselves.
# Now people can declare:
#   cros_pre_pkg_preinst_foo() { ... }
# And we'll automatically execute that in the pre_pkg_preinst func.
#
# Note: profile.bashrc's should avoid hooking phases that differ across
# EAPI's (src_{prepare,configure,compile} for example).  These are fine
# in the per-package bashrc tree (since the specific EAPI is known).
cros_lookup_funcs() {
	declare -f | egrep "^$1 +\(\) +$" | awk '{print $1}'
}
cros_stack_hooks() {
	local phase=$1 func
	local header=true

	for func in $(cros_lookup_funcs "cros_${phase}_[-_[:alnum:]]+") ; do
		if ${header} ; then
			einfo "Running stacked hooks for ${phase}"
			header=false
		fi
		ebegin "   ${func#cros_${phase}_}"
		${func}
		eend $?
	done
}
cros_setup_hooks() {
	# Avoid executing multiple times in a single build.
	[[ ${cros_setup_hooks_run+set} == "set" ]] && return

	local phase
	for phase in {pre,post}_{src_{unpack,prepare,configure,compile,test,install},pkg_{{pre,post}{inst,rm},setup}} ; do
		eval "${phase}() { cros_stack_hooks ${phase} ; }"
	done
	export cros_setup_hooks_run="booya"
}
cros_setup_hooks

cros_emit_build_metric() {
	# We only enable build metrics on servers currently, but we need to make
	# sure the binpkgs they produce are usable when deployed for developers
	# & DUTs.
	local emit_metric="/mnt/host/source/chromite/bin/emit_metric"
	if [[ -n "${BUILD_API_METRICS_LOG}" ]] && [[ -e "${emit_metric}" ]] ; then
		local operation=$1
		local phase=$2
		local metric="emerge.${phase}.${CATEGORY}/${PF}"
		local key="${metric}"
		"${emit_metric}" "${operation}" "${metric}" "${key}"
	fi
}

if [[ -n "${BUILD_API_METRICS_LOG}" ]] ; then
	# Set up recording of Build API metrics events.
	cros_setup_metric_events() {
		# Avoid executing multiple times in a single build.
		[[ ${cros_setup_metric_events_run+set} == "set" ]] && return

		local phase
		for phase in {src_{unpack,prepare,configure,compile,test,install},pkg_{{pre,post}{inst,rm},setup}} ; do
			eval "cros_pre_${phase}_start_timer() { cros_emit_build_metric start-timer "${phase}" ; }"
			eval "cros_post_${phase}_stop_timer() { cros_emit_build_metric stop-timer "${phase}" ; }"
		done
		export cros_setup_metric_events_run="yes"
	}
	cros_setup_metric_events
fi

# If we ran clang-tidy during the compile phase, we need to capture the build
# logs, which contain the actual clang-tidy warnings.
cros_pre_src_install_tidy_setup() {
	if [[ -v WITH_TIDY ]] ; then
		if [[ ${WITH_TIDY} -eq 1 ]] ; then
			clang_tidy_logs_dir="/tmp/clang-tidy-logs/${BOARD}"
			mkdir -p ${clang_tidy_logs_dir}
			cp ${PORTAGE_LOG_FILE} ${clang_tidy_logs_dir}
			sudo chmod 644 ${clang_tidy_logs_dir}/*
		fi
	fi
}

# Since we're storing the wrappers in a board sysroot, make sure that
# is actually in our PATH.
cros_pre_pkg_setup_sysroot_build_bin_dir() {
	PATH+=":${CROS_BUILD_BOARD_BIN}"
}

# The python-utils-r1.eclass:python_wrapper_setup installs a stub program named
# `python2` when PYTHON_COMPAT only lists python-3 programs.  It's designed to
# catch bad packages that still use `python2` even though we said not to.  We
# normally expect packages installed by Gentoo to use specific versions like
# `python2.7`, so the stub doesn't break things there.  In Chromium OS though,
# our chromite code (by design) uses `python2`.  We don't install a copy via
# the ebuild, so we wouldn't rewrite the she-bang.  Delete the stub since it
# doesn't add a lot of value for us and breaks chromite.
#
# We can delete this code iif we only ever support a single major version of
# Python in the entire system.  We'd have to drop all of Python 2 completely,
# and never have Python 4 :).
cros_post_pkg_setup_python_eclass_hack() {
	rm -f "${T}"/python2.*/bin/python3
}
# A few packages run this during src_* phases.
cros_post_src_compile_python_eclass_hack() {
	cros_post_pkg_setup_python_eclass_hack
}

# We don't want builds to run tools directly like `gcc` or `clang` or
# `pkg-config`.  This indicates the packages are written incorrectly and
# would use the wrong toolchain for the board.  They might seem to work for
# x86_64 boards (since the SDK is x86_64), but it's still unreliable.
# https://crbug.com/985180
cros_pre_src_prepare_build_toolchain_catch() {
	local targetenv
	if [[ $(cros_target) == "cros_host" ]]; then
		targetenv="sdk"
	else
		targetenv="board"
	fi

	# Note: Do not add any more packages to these lists.  Fix the bugs instead.

	# TODO(vapier): Finish fixing these packages.
	_sdk_build_filter_pkg_config() {
		case ${CATEGORY}/${PN} in
		*/gdb) return 1;;
		# Haskell has some internal logic that invokes `pkg-config --version`.
		app-admin/haskell-updater) return 1;;
		dev-embedded/u-boot-tools) return 1;;
		dev-util/shellcheck) return 1;;
		dev-haskell/*) return 1;;
		dev-lang/ghc) return 1;;
		dev-lang/rust) return 1;;
		dev-python/pycairo) return 1;;
		media-video/ffmpeg) return 1;;
		net-analyzer/wireshark) return 1;;
		# Used during `aclocal` to find glib macros.
		x11-libs/cairo) return 1;;
		esac
	}
	_sdk_build_filter_cc() {
		case ${CATEGORY}/${PN} in
		*/binutils|\
		*/gcc|\
		*/gdb|\
		app-text/xmlto|\
		cross-*/gdb|\
		dev-embedded/u-boot-tools|\
		dev-lang/rust|\
		dev-libs/libffi|\
		dev-libs/libusb-compat|\
		dev-libs/lzo|\
		dev-python/grpcio|\
		dev-python/psutil|\
		dev-util/patchutils|\
		net-libs/libmnl|\
		sys-apps/groff|\
		sys-devel/m4|\
		sys-libs/binutils-libs|\
		x11-libs/gdk-pixbuf) return 1;;
		esac
	}
	_sdk_build_filter_gcc() {
		case ${CATEGORY}/${PN} in
		cross-*/glibc|\
		*/linux-headers|\
		chromeos-base/ec-utils|\
		dev-embedded/u-boot-tools|\
		dev-python/numpy|\
		dev-util/ragel|\
		net-misc/socat|\
		sys-boot/grub|\
		sys-boot/syslinux|\
		sys-libs/binutils-libs|\
		sys-libs/libselinux) return 1;;
		esac
	}
	_sdk_build_filter_g++() {
		return 0
	}
	_sdk_build_filter_clang() {
		case ${CATEGORY}/${PN} in
		chromeos-base/ec-devutils) return 1;;
		esac
	}
	_sdk_build_filter_clang++() {
		return 0
	}
	_sdk_build_filter_ld() {
		case ${CATEGORY}/${PN} in
		app-crypt/nss|\
		cross-*/gcc|\
		cross-*/go|\
		dev-embedded/coreboot-sdk|\
		dev-lang/go|\
		dev-libs/nss|\
		dev-util/perf) return 1;;
		esac
	}
	_sdk_build_filter_as() {
		case ${CATEGORY}/${PN} in
		dev-embedded/coreboot-sdk|\
		dev-libs/nspr) return 1;;
		esac
	}

	_board_build_filter_pkg_config() {
		case ${CATEGORY}/${PN} in
		app-benchmarks/lmbench|\
		app-emulation/docker|\
		app-text/ghostscript-gpl|\
		chromeos-base/autotest-tests-lakitu|\
		media-libs/arc-cros-gralloc|\
		media-libs/arc-img-ddk|\
		media-libs/arc-mali-drivers|\
		media-libs/arc-mali-drivers-bifrost|\
		media-libs/arc-mesa|\
		media-libs/arc-mesa-amd|\
		media-libs/arc-mesa-freedreno|\
		media-libs/arc-mesa-img|\
		media-libs/arc-mesa-iris|\
		media-libs/arc-mesa-virgl|\
		media-libs/mali-drivers-bifrost|\
		media-libs/mali-drivers-valhall|\
		media-libs/mesa|\
		media-libs/mesa-amd|\
		media-libs/mesa-llvmpipe|\
		net-analyzer/wireshark|\
		net-dns/dnsmasq|\
		net-misc/dhcpcd|\
		net-misc/improxy|\
		net-print/cups|\
		sys-apps/cavium-n3fips-driver|\
		sys-apps/fwupd|\
		sys-apps/loadpin-trigger|\
		sys-apps/snaggletooth-drivers|\
		sys-boot/coreboot|\
		sys-boot/depthcharge|\
		sys-boot/libpayload|\
		sys-boot/loonix-u-boot|\
		sys-boot/u-boot|\
		sys-devel/arc-llvm|\
		sys-devel/gdb|\
		sys-fs/avfs|\
		sys-kernel/arcvm-kernel-*|\
		sys-kernel/chromeos-kernel-*|\
    sys-kernel/surface-kernel-*|\
		sys-kernel/dump-capture-kernel|\
		sys-kernel/gw-kernel-*|\
		sys-kernel/kernel-beaglebone-*|\
		sys-kernel/lakitu-kernel-*|\
		sys-kernel/loonix-kernel-*|\
		sys-kernel/raspberrypi-kernel|\
		sys-kernel/ti-nokia-kernel|\
		sys-kernel/upstream-kernel-*|\
		sys-libs/efivar|\
		x11-base/xwayland|\
		x11-libs/arc-libdrm|\
		x11-libs/cairo) return 1;;
		esac
	}
	_board_build_filter_cc() {
		case ${CATEGORY}/${PN} in
		app-benchmarks/sysbench|\
		dev-libs/libdaemon|\
		dev-libs/libffi|\
		dev-libs/libusb-compat|\
		dev-python/grpcio|\
		dev-python/psutil|\
		media-libs/libogg|\
		net-dns/avahi|\
		net-libs/libmnl|\
		net-libs/libnetfilter_cthelper|\
		net-libs/libnetfilter_cttimeout|\
		net-libs/libnetfilter_queue|\
		net-libs/libnfnetlink|\
		net-misc/nldaemon|\
		net-wireless/openthread|\
		net-wireless/ot-br-posix|\
		sys-apps/groff|\
		sys-apps/kbd|\
		sys-apps/ureadahead|\
		sys-block/parted|\
		sys-boot/arria10-u-boot|\
		sys-boot/loonix-u-boot|\
		sys-devel/binutils|\
		sys-devel/gdb|\
		sys-devel/m4|\
		sys-fs/rar2fs|\
		sys-libs/gcc-libs|\
		x11-libs/gdk-pixbuf) return 1;;
		esac
	}
	_board_build_filter_gcc() {
		case ${CATEGORY}/${PN} in
		app-benchmarks/lmbench|\
		app-emulation/docker|\
		chromeos-base/autotest-tests|\
		chromeos-base/chromeos-ec|\
		chromeos-base/chromeos-ish|\
		chromeos-base/ec-utils|\
		dev-go/syzkaller|\
		dev-python/numpy|\
		media-libs/arc-img-ddk|\
		media-libs/img-ddk|\
		media-sound/gsm|\
		net-fs/autofs|\
		net-misc/socat|\
		sys-apps/cavium-n3fips-tools|\
		sys-block/blktrace|\
		sys-boot/chromeos-mrc|\
		sys-boot/coreboot|\
		sys-boot/depthcharge|\
		sys-boot/grub-lakitu|\
		sys-boot/libpayload|\
		sys-boot/qca-framework|\
		sys-boot/syslinux|\
		sys-firmware/chromeos-fpmcu-release-bloonchipper|\
		sys-firmware/chromeos-fpmcu-release-dartmonkey|\
		sys-firmware/chromeos-fpmcu-release-nami|\
		sys-firmware/chromeos-fpmcu-release-nocturne|\
		sys-fs/mdadm|\
		sys-kernel/linux-headers|\
		sys-libs/efivar) return 1;;
		esac
	}
	_board_build_filter_g++() {
		case ${CATEGORY}/${PN} in
		media-libs/img-ddk|\
		net-print/hplip|\
		sys-boot/qca-framework) return 1;;
		esac
	}
	_board_build_filter_clang() {
		case ${CATEGORY}/${PN} in
		chromeos-base/autotest-tests-lakitu|\
		chromeos-base/chromeos-ec|\
		chromeos-base/ec-devutils|\
		media-libs/arc-mali-drivers-bifrost|\
		media-libs/mali-drivers-bifrost|\
		media-libs/mali-drivers-valhall|\
		net-libs/nodejs|\
		sys-boot/coreboot|\
		sys-boot/libpayload|\
		sys-devel/arc-llvm|\
		sys-devel/llvm) return 1;;
		esac
	}
	_board_build_filter_clang++() {
		case ${CATEGORY}/${PN} in
		media-libs/arc-mali-drivers-bifrost|\
		media-libs/mali-drivers-bifrost|\
		media-libs/mali-drivers-valhall|\
		net-libs/nodejs|\
		sys-devel/arc-llvm|\
		sys-devel/llvm) return 1;;
		esac
	}
	_board_build_filter_ld() {
		case ${CATEGORY}/${PN} in
		app-crypt/nss|\
		dev-libs/nss|\
		dev-util/perf|\
		media-libs/arc-mali-drivers-bifrost|\
		media-libs/mali-drivers-bifrost|\
		sys-kernel/arcvm-kernel-*|\
		sys-kernel/chromeos-kernel-*|\
    sys-kernel/surface-kernel-*|\
		sys-kernel/dump-capture-kernel|\
		sys-kernel/lakitu-kernel-*|\
		sys-kernel/raspberrypi-kernel|\
		sys-kernel/upstream-kernel-*|\
		sys-libs/gcc-libs) return 1;;
		esac
	}
	_board_build_filter_as() {
		case ${CATEGORY}/${PN} in
		dev-embedded/coreboot-sdk|\
		dev-libs/nspr|\
		net-misc/nldaemon|\
		sys-boot/coreboot|\
		sys-boot/libpayload) return 1;;
		esac
	}

	local dir="${T}/build-toolchain-wrappers"
	mkdir -p "${dir}"
	local tool tcvar
	for tool in as ld clang clang++ c++ g++ cc gcc pkg-config; do
		tcvar=${tool^^}
		tcvar=${tcvar//-/_}

		case ${tool} in
		as|cc|clang|clang++|g++|gcc|ld|pkg-config)
			_${targetenv}_build_filter_${tool//-/_} || continue
			;;
		esac

		cat <<EOF > "${dir}/${tool}"
#!/bin/sh
$(which eerror) "\$(
err() { echo "${tool}: ERROR: \$*"; }
err "Do not call unprefixed tools directly."
err "For board tools, use \\\`tc-export ${tcvar}\\\` (or \\\${CHOST}-${tool})."
err "For build-time-only tools, \\\`tc-export BUILD_${tcvar}\\\` (or \\\${CBUILD}-${tool})."
pstree -a -A -s -l \$\$
)"
$(which die) "Bad ${tool} [\$*] invocation"
exit 1
EOF
		chmod a+rx "${dir}/${tool}"
	done
	PATH="${dir}:${PATH}"
}
cros_post_src_install_build_toolchain_catch() {
	# Some portage install hooks will run tools.  We probably want to change
	# those, but at least for now, we'll undo the wrappers.
	rm -rf "${T}/build-toolchain-wrappers"
}

# Set ASAN settings so they'll work for unittests. http://crbug.com/367879
# We run at src_unpack time so that the hooks have time to get registered
# and saved in the environment.  Portage has a bug where hooks registered
# in the same phase that fails are not run.  http://bugs.gentoo.org/509024
# We run at the _end_ of src_unpack time so that ebuilds which munge ${S}
# (packages which live in the platform2 repo) can do so before we do work.
cros_post_src_unpack_asan_init() {
	local log_path="${T}/asan_logs/asan"
	local coverage_path="${T}/coverage_logs"
	mkdir -p "${log_path%/*}"
	mkdir -p "${coverage_path%/*}"

	local strip_sysroot
	if [[ -n "${PLATFORM_BUILD}" ]]; then
		# platform_test chroots into $SYSROOT before running the unit
		# tests, so we need to strip the $SYSROOT prefix from the
		# 'log_path' option specified in $ASAN_OPTIONS and the
		# 'suppressions' option specified in $LSAN_OPTIONS.
		strip_sysroot="${SYSROOT}"
	fi
	export ASAN_OPTIONS+=" log_path=${log_path#${strip_sysroot}}"
	export MSAN_OPTIONS+=" log_path=${log_path#${strip_sysroot}}"
	export TSAN_OPTIONS+=" log_path=${log_path#${strip_sysroot}}"
	export UBSAN_OPTIONS+=" log_path=${log_path#${strip_sysroot}}"
	# symbolize ubsan crashes.
	export UBSAN_OPTIONS+=":symbolize=1:print_stacktrace=1"
	# Clang coverage file generation location, only for target builds.
	if [[ $(cros_target) == "board_sysroot" ]]; then
		export LLVM_PROFILE_FILE="${coverage_path#${strip_sysroot}}/${P}_%9m.profraw"
	fi

	local lsan_suppression="${S}/lsan_suppressions"
	local lsan_suppression_ebuild="${FILESDIR}/lsan_suppressions"
	export LSAN_OPTIONS+=" print_suppressions=0"
	if [[ -f ${lsan_suppression} ]]; then
		export LSAN_OPTIONS+=" suppressions=${lsan_suppression#${strip_sysroot}}"
	elif [[ -f ${lsan_suppression_ebuild} ]]; then
		export LSAN_OPTIONS+=" suppressions=${lsan_suppression_ebuild}"
	fi

	has asan_death_hook ${EBUILD_DEATH_HOOKS} || EBUILD_DEATH_HOOKS+=" asan_death_hook"
}

# Check for & show ASAN failures when dying.
asan_death_hook() {
	local l

	for l in "${T}"/asan_logs/asan*; do
		[[ ! -e ${l} ]] && return 0
		echo
		eerror "ASAN error detected:"
		eerror "$(asan_symbolize.py -d -s "${SYSROOT}" < "${l}")"
		echo
	done
	return 1
}

# Check for any ASAN failures that were missed while testing.
cros_post_src_test_asan_check() {
	# Remove the temporary directories created previously in asan_init.
	# Die if ASAN failures were reported.
	rmdir "${T}/asan_logs" 2>/dev/null || die "asan error not caught"
	# Recreate directories for incremental cros_workon-make --test usage.
	mkdir -p "${T}/asan_logs"
}

cros_post_src_install_coverage_logs() {
	# Generate coverage reports for the package.
	if [[ $(cros_target) != "board_sysroot" ]]; then
		return
	fi
	local coverage_path="${T}/coverage_logs"
	if [[ ! -d "${coverage_path}" ]]; then
		return
	fi

	if [[ -n "$(ls -A "${coverage_path}")" ]]; then
		local rel_cov_dir="build/coverage_data/${CATEGORY}/${PN}"
		[[ "${SLOT:-0}" != "0" ]] && rel_cov_dir+="-${SLOT}"
		local cov_dir="${D}/${rel_cov_dir}"
		mkdir -p "${cov_dir}/raw_profiles"
		cp "${coverage_path}"/*.profraw "${cov_dir}/raw_profiles" || die
		local cov_files=( "${coverage_path}"/*.profraw )

		# Create the indexed profile file from raw profiles.
		llvm-profdata merge -sparse "${cov_files[@]}" \
			-output="${cov_dir}/${PN}.profdata" || die

		# Find all elf binaries built in this package that have
		# coverage instrumentation enabled and add "-object option" to
		# be used later in llvm-cov.
		# TODO: Find more directories other than ${OUT} and ${WORKDIR}
		# that the package may use for producing binaries.
		local cov_args
		readarray -t cov_args < <(scanelf -qRy -k__llvm_covmap \
			-F$'-object\n#k%F' "${OUT}" "${WORKDIR}")
		# Return if there are no elf files with coverage data.
		[[ "${#cov_args[@]}" -eq 0 ]] && return

		# Generate json format coverage report.
		llvm-cov export "${cov_args[@]}" \
			-instr-profile="${cov_dir}/${PN}.profdata" \
			-skip-expansions \
			-skip-functions \
			> ${cov_dir}/coverage.json || die

		# Generate html format coverage report.
		llvm-cov show "${cov_args[@]}" -format=html \
			-instr-profile="${cov_dir}/${PN}.profdata" \
			-output-dir="${cov_dir}" || die
		# Make coverage data readable for all users.
		chmod -R a+rX "${cov_dir}" || die "Could not make ${cov_dir} readable"
		local report_path="${EXTERNAL_TRUNK_PATH}/chroot${SYSROOT}/${rel_cov_dir}/index.html"
		elog "Coverage report for ${PN} generated at file://${report_path}"
	fi
}

# Enables C++ exceptions. We normally disable these by default in
#   chromiumos-overlay/chromeos/config/make.conf.common-target
cros_enable_cxx_exceptions() {
	CXXFLAGS=${CXXFLAGS/ -fno-exceptions/ }
	CXXFLAGS=${CXXFLAGS/ -fno-unwind-tables/ }
	CXXFLAGS=${CXXFLAGS/ -fno-asynchronous-unwind-tables/ }
	CFLAGS=${CFLAGS/ -fno-exceptions/ }
	CFLAGS=${CFLAGS/ -fno-unwind-tables/ }
	CFLAGS=${CFLAGS/ -fno-asynchronous-unwind-tables/ }
	# Set the CXXEXCEPTIONS variable to 1 so packages based on common.mk or
	# platform2 gyp inherit this value by default.
	CXXEXCEPTIONS=1
}

# We still use gcc to build packages even the CC or CXX is set to
# something else.
cros_use_gcc() {
	if [[ $(basename ${CC:-gcc}) != *"gcc"* ]]; then
		export CC=${CHOST}-gcc
		export CXX=${CHOST}-g++
		export LD=${CHOST}-ld
	fi
	if [[ $(basename ${BUILD_CC:-gcc}) != *"gcc"* ]]; then
		export BUILD_CC=${CBUILD}-gcc
		export BUILD_CXX=${CBUILD}-g++
		export BUILD_LD=${CBUILD}-ld
	fi
	filter_unsupported_gcc_flags
	filter_sanitizers
}

# Enforce use of libstdc++ instead of libc++ when building with clang.
cros_use_libstdcxx() {
	if [[ $(basename "${CC:-clang}") == *"clang"* ]]; then
		CXXFLAGS+=" -Xclang-only=-stdlib=libstdc++"
		LDFLAGS+=" -Xclang-only=-stdlib=libstdc++"
	fi
}

cros_log_failed_packages() {
	if [[ -n "${CROS_METRICS_DIR}" ]]; then
		mkdir -p "${CROS_METRICS_DIR}"
		echo "${CATEGORY}/${PF} ${EBUILD_PHASE:-"unknown"}" \
			 >> "${CROS_METRICS_DIR}/FAILED_PACKAGES"
	fi
}

cros_optimize_package_for_speed() {
	# NOTE: Replacing this with -O3 probably isn't worth it. -O3 sometimes speeds
	# up code/sometimes doesn't, and the binaries where literally 94% of our
	# fleetwide cycles are spent (at the time of writing) reject our optimization
	# flags and substitute their own anyway.
	export CFLAGS+=" -O2"
	export CXXFLAGS+=" -O2"
}

register_die_hook cros_log_failed_packages

filter_clang_syntax() {
	local var flag flags=()
	for var in CFLAGS CXXFLAGS; do
		for flag in ${!var}; do
			if [[ ${flag} != "-clang-syntax" ]]; then
				flags+=("${flag}")
			fi
		done
		export ${var}="${flags[*]}"
		flags=()
	done
}

filter_sanitizers() {
	local var flag flags=()
	for var in CFLAGS CXXFLAGS LDFLAGS; do
		for flag in ${!var}; do
			if [[ ${flag} != "-fsanitize"* && ${flag} != "-fno-sanitize"* ]]; then
				flags+=("${flag}")
			fi
		done
		export ${var}="${flags[*]}"
		flags=()
	done
}

filter_unsupported_gcc_flags() {
	local var flag flags=()
	for var in CFLAGS CXXFLAGS LDFLAGS; do
		for flag in ${!var}; do
			if [[ ${flag} != "-Xcompiler" ]]; then
				flags+=("${flag}")
			fi
		done
		export ${var}="${flags[*]}"
		flags=()
	done
}
