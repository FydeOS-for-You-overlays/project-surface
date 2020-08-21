# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for ath10k WIFI for surface"
HOMEPAGE="http://fydeos.com"

LICENSE="LICENSE.QualcommAtheros_ath10k"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/linux-firmware-surface"

SRC_URI="${FYDEBASE_URI}/ath10k_firmware.zip"

FIRMWARE_INSTALL_ROOT="/lib/firmware/ath10k"

S=$WORKDIR

src_install() {
  insinto ${FIRMWARE_INSTALL_ROOT}
  doins -r *
}
