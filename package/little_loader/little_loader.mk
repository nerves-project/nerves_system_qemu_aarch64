################################################################################
#
# little_loader
#
################################################################################

LITTLE_LOADER_VERSION = v0.1.0
LITTLE_LOADER_SITE = $(call github,fhunleth,little_loader,$(LITTLE_LOADER_VERSION))
LITTLE_LOADER_SOURCE = little_loader-$(LITTLE_LOADER_VERSION).tar.gz
LITTLE_LOADER_LICENSE = 0BSD, GPL-2.0-only (demo/Image), LicenseRefGaryBrown1986 (src/crc32.c), 0BSD or Unlicense (src/nanoprintf.h)
LITTLE_LOADER_LICENSE_FILES = LICENSES/0BSD.txt LICENSES/BSD-2-Clause.txt LICENSES/BSD-3-Clause.txt LICENSES/GPL-2.0-only.txt LICENSES/GPL-2.0-or-later.txt LICENSES/LicenseRef-GaryBrown1986.txt LICENSES/Unlicense.txt

LITTLE_LOADER_DEPENDENCIES = fwup

LITTLE_LOADER_INSTALL_STAGING = YES

define LITTLE_LOADER_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0755 $(@D)/little_loader.elf $(STAGING_DIR)/little.elf
endef

define LITTLE_LOADER_BUILD_CMDS
	$(MAKE) -C $(@D)
endef

$(eval $(generic-package))
