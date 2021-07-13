# Copyright 2017 The FydeOS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="FydeOS power management policy for microsoft surface devices"
LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="-keepwaking"
S="${FILESDIR}"

RDEPEND=""

DEPEND="${RDEPEND}"

src_install() {
  insinto "/usr/share/power_manager/board_specific"
  doins "${FILESDIR}"/powerd_prefs/*
  if use keepwaking; then
    insinto /etc/chromium/policies/managed
    doins "${FILESDIR}"/*
  fi
}
