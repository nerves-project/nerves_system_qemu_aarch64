################################################################################
#
# little_loader
#
################################################################################

LITTLE_LOADER_VERSION = v0.1.1
LITTLE_LOADER_SITE = $(call github,fhunleth,little_loader,$(LITTLE_LOADER_VERSION))
LITTLE_LOADER_LICENSE = BSD-2-Clause BSD-3-Clause
LITTLE_LOADER_LICENSE_FILES = LICENSES/BSD-2-Clause.txt LICENSES/BSD-3-Clause.txt

LITTLE_LOADER_INSTALL_IMAGES = YES

define LITTLE_LOADER_BUILD_CMDS
	$(MAKE1) -e CROSS=$(TARGET_CROSS) -C $(@D) little_loader.elf
endef

define LITTLE_LOADER_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0755 $(@D)/little_loader.elf $(BINARIES_DIR)/little_loader.elf
endef

$(eval $(generic-package))
