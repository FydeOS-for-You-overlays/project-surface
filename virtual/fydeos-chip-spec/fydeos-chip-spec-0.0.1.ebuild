# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
  sys-kernel/linux-firmware-surface
  sys-firmware/intel-microcode
  chromeos-base/libwidevine
  chromeos-base/fydeos-power-daemon-go
  chromeos-base/surface-cover-gesture
  chromeos-base/surface-power-management-policy
  chromeos-base/bluetooth-input-fix
"

DEPEND="${RDEPEND}"
