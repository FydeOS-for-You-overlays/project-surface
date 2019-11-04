# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for nvidia gv100 firmware for surface"
HOMEPAGE="http://fydeos.com"

LICENSE="LICENCE.nvidia"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/linux-firmware-surface"

SRC_URI="${FYDEBASE_URI}/nvidia_firmware_gv100.zip"

FIRMWARE_INSTALL_ROOT="/lib/firmware/nvidia/gv100"
S=$WORKDIR

src_install() {
  insinto ${FIRMWARE_INSTALL_ROOT}
  doins *
}
