# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for surface serial pc"
HOMEPAGE="http://fydeos.com"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/${PN}"

IUSE_SURFACE_TYPE=(
  pro3
  pro4
  pro5
  pro6
  pro7
  studio
  laptop
  laptop2
  book
  book2a
  book2b
  go
)

IUSE="${IUSE_SURFACE_TYPE[@]/#/surface_}"
LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

RDEPEND="
  surface_pro3? ( sys-kernel/linux-firmware-intel-i915[intel_bxt] )
  surface_pro4? ( 
		sys-kernel/linux-firmware-intel-i915[intel_skl] 
    sys-kernel/linux-firmware-intel-ipts[ipts_78]
  )
  surface_pro5? ( 
    sys-kernel/linux-firmware-intel-i915[intel_kbl]
    sys-kernel/linux-firmware-intel-ipts[ipts_102] 
  )
  surface_pro6? (
    sys-kernel/linux-firmware-intel-i915[intel_kbl]
    sys-kernel/linux-firmware-intel-ipts[ipts_102]
  )
  surface_pro7? (
    sys-kernel/linux-firmware-intel-i915[intel_icl]
    sys-kernel/linux-firmware-intel-ipts[ipts_103]
  )
  surface_studio? (
    sys-kernel/linux-firmware-intel-i915[intel_skl]
    sys-kernel/linux-firmware-intel-ipts[ipts_76]
  )
  surface_laptop? (
    sys-kernel/linux-firmware-intel-i915[intel_kbl]
    sys-kernel/linux-firmware-intel-ipts[ipts_79] 
  )
  surface_laptop2? (
    sys-kernel/linux-firmware-intel-i915[intel_kbl]
    sys-kernel/linux-firmware-intel-ipts[ipts_79]
  )
  surface_book? (
    sys-kernel/linux-firmware-intel-i915[intel_skl]
    sys-kernel/linux-firmware-intel-ipts[ipts_76]
  )
  surface_book2a? (
    sys-kernel/linux-firmware-intel-i915[intel_kbl]
    sys-kernel/linux-firmware-intel-ipts[ipts_101]
    sys-kernel/linux-firmware-nvidia-gp108
    sys-kernel/linux-firmware-nvidia-gv100
  )
  surface_book2b? (
    sys-kernel/linux-firmware-intel-i915[intel_kbl]
    sys-kernel/linux-firmware-intel-ipts[ipts_137]
    sys-kernel/linux-firmware-nvidia-gp108
    sys-kernel/linux-firmware-nvidia-gv100
  )
  surface_go? (
    sys-kernel/linux-firmware-ath10k
  )
  sys-kernel/linux-firmware-mrvl
  sys-kernel/linux-firmware-mwlwifi
"

DEPEND="${RDEPEND}"
