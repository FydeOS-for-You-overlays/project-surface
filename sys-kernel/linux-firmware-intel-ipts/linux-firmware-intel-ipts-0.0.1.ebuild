# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for intel ipts(touch screen) firmware for surface"
HOMEPAGE="http://fydeos.com"

LICENSE="LICENSE.i915"
SLOT="0"
KEYWORDS="*"
IUSE_INTEL_IPTS=(
  76
  78
  79
  101
  102
  103
  137
)
IUSE="${IUSE_INTEL_IPTS[@]/#/ipts_}"

RDEPEND=""

DEPEND="${RDEPEND}"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/linux-firmware-surface"

SRC_URI="
  ipts_76? ( ${FYDEBASE_URI}/ipts_firmware_v76.zip )
  ipts_78? ( ${FYDEBASE_URI}/ipts_firmware_v78.zip )
  ipts_79? ( ${FYDEBASE_URI}/ipts_firmware_v79.zip )
  ipts_101? ( ${FYDEBASE_URI}/ipts_firmware_v101.zip )
  ipts_102? ( ${FYDEBASE_URI}/ipts_firmware_v102.zip )
  ipts_103? ( ${FYDEBASE_URI}/ipts_firmware_v103.zip )
  ipts_137? ( ${FYDEBASE_URI}/ipts_firmware_v137.zip )
"

FIRMWARE_INSTALL_ROOT="/lib/firmware/intel/ipts"

S=$WORKDIR
src_install() {
  insinto ${FIRMWARE_INSTALL_ROOT}
  doins *
}
