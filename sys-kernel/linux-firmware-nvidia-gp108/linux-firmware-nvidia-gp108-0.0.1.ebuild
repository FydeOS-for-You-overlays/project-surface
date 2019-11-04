# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="Linux firmware for nvidia gp108 firmware for surface"
HOMEPAGE="http://fydeos.com"

LICENSE="LICENCE.nvidia"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND=""

DEPEND="${RDEPEND}"

RESTRICT+=" mirror"
FYDEBASE_URI="ftp://ftp:ftp@flintboy/linux-firmware-surface"

SRC_URI="${FYDEBASE_URI}/nvidia_firmware_gp108.zip"

FIRMWARE_INSTALL_ROOT="/lib/firmware/nvidia/gp108"
S=$WORKDIR

src_install() {
  insinto ${FIRMWARE_INSTALL_ROOT}
  doins *
}
