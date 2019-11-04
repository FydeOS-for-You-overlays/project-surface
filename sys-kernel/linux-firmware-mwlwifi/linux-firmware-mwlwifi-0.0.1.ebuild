# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for mwlwifii for surface"
HOMEPAGE="http://fydeos.com"

LICENSE="LICENCE.Marvell"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/linux-firmware-surface"

SRC_URI="${FYDEBASE_URI}/mwlwifi_firmware.zip"

FIRMWARE_INSTALL_ROOT="/lib/firmware/mwlwifi"
S=$WORKDIR

src_install() {
  insinto ${FIRMWARE_INSTALL_ROOT}
  doins *
}
