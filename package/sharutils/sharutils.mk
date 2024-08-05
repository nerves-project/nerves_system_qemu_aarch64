################################################################################
#
# sharutils
#
################################################################################

SHARUTILS_VERSION = 4.15.2
SHARUTILS_SITE = https://ftp.gnu.org/gnu/sharutils
SHARUTILS_SOURCE = sharutils-$(SHARUTILS_VERSION).tar.xz
SHARUTILS_LICENSE = GPL-3.0+
SHARUTILS_LICENSE_FILES = COPYING

UBOOT_PRE_BUILD_HOOKS += SHARUTILS_RDEPEND_HOOK

define SHARUTILS_RDEPEND_HOOK
	$(MAKE) host-sharutils -C $(BASE_DIR)
endef

SHARUTILS_DEPENDENCIES = host-pkgconf

HOST_SHARUTILS_CONF_ENV += \
	CFLAGS="-fcommon -Wno-format-security"

HOST_SHARUTILS_CONF_OPTS = \
	--enable-nls

$(eval $(host-autotools-package))
