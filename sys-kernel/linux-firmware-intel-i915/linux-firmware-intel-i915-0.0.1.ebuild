# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for intel firmware for surface"
HOMEPAGE="http://fydeos.com"

LICENSE="LICENSE.i915"
SLOT="0"
KEYWORDS="*"
IUSE_INTEL=(
  bxt
  cfl
  cnl
  glk
  kbl
  skl 
  icl
  tgl
  all
)

IUSE="${IUSE_INTEL[@]/#/intel_}"

RDEPEND=""

DEPEND="${RDEPEND}"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/linux-firmware-surface"

SRC_URI="
  intel_bxt? ( ${FYDEBASE_URI}/i915_firmware_bxt.zip )
  intel_cfl? ( ${FYDEBASE_URI}/i915_firmware_cfl.zip )
  intel_cnl? ( ${FYDEBASE_URI}/i915_firmware_cnl.zip )
  intel_glk? ( ${FYDEBASE_URI}/i915_firmware_glk.zip )
  intel_kbl? ( ${FYDEBASE_URI}/i915_firmware_kbl.zip )
  intel_skl? ( ${FYDEBASE_URI}/i915_firmware_skl.zip )
  intel_all? ( ${FYDEBASE_URI}/i915_firmware_all.zip )
  intel_icl? ( ${FYDEBASE_URI}/i915_firmware_icl.zip )
  intel_tgl? ( ${FYDEBASE_URI}/i915_firmware_tgl.zip )
"

FIRMWARE_INSTALL_ROOT="/lib/firmware/i915"

S=$WORKDIR

src_install() {
  insinto ${FIRMWARE_INSTALL_ROOT}
  doins *  
}
