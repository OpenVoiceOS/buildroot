################################################################################
#
# Build the dracut initramfs image
#
################################################################################

# Dracut requires realpath from coreutils
ROOTFS_DRACUT_DEPENDENCIES += \
	host-dracut \
	host-kmod \
	dracut

ROOTFS_DRACUT_MODULES_INCLUDE = \
	base \
	rootfs-block \
	udev-rules

ROOTFS_DRACUT_MODULES_OMIT = \
	lunmask \
	plymouth \
	resume \
	systemd-ldconfig

ROOTFS_DRACUT_TARGET_DIR="$(ROOTFS_DRACUT_DIR)/target
ROOTFS_DRACUT_FS_ENV = \
	PKG_CONFIG=$(STAGING_DIR)/usr/lib/pkgconfig \
	prefix="" \
	DESTROOTDIR="$(ROOTFS_DRACUT_TARGET_DIR)" \
	DRACUT_ARCH=$(BR2_ARCH) \
	DRACUT_COMPRESS_BZIP2="$(HOST_DIR)/bin/bzip2" \
	DRACUT_COMPRESS_GZIP="$(HOST_DIR)/bin/gzip" \
	DRACUT_COMPRESS_LZMA="$(HOST_DIR)/bin/lzma" \
	DRACUT_FIRMWARE_PATH="$(ROOTFS_DRACUT_TARGET_DIR)/usr/lib/firmware" \
	DRACUT_INSTALL="$(HOST_DIR)/lib/dracut/dracut-install" \
	DRACUT_INSTALL_PATH="$(ROOTFS_DRACUT_TARGET_DIR)/usr/bin:$(ROOTFS_DRACUT_TARGET_DIR)/usr/sbin:$(ROOTFS_DRACUT_TARGET_DIR)/usr/lib" \
	DRACUT_MODPROBE="$(HOST_DIR)/sbin/modprobe" \
	DRACUT_PATH="/bin /sbin"

ROOTFS_DRACUT_MKFS_CONF_OPTS = \
	--force \
	--noprefix \
	--sysroot=$(ROOTFS_DRACUT_TARGET_DIR) \
	--tmpdir=$(ROOTFS_DRACUT_DIR)/rootfs.dracut.tmp \
	--verbose

ifeq ($(BR2_ROOTFS_DEVICE_TABLE_SUPPORTS_EXTENDED_ATTRIBUTES),y)
ROOTFS_DRACUT_FS_ENV += DRACUT_NO_XATTR=true
else
ROOTFS_DRACUT_FS_ENV += DRACUT_NO_XATTR=false
endif

# Environment variables used to execute dracut
# We have to unset "prefix" as dracut uses it to move files around.
# Dracut doesn't support decimal points for the systemd version.
ROOTFS_DRACUT_SYSTEMD_VERSION_SANATIZED=`echo $(SYSTEMD_VERSION) |cut -d . -f 1`

# Dbus variables taken from dracut.conf.d/fedora.conf.example
ROOTFS_DRACUT_FS_ENV += \
	udevdir=/usr/lib/udev \
	dbus=/usr/share/dbus-1 \
	dbusinterfaces=/usr/share/dbus-1/interfaces \
	dbusservices=/usr/share/dbus-1/services \
	dbussession=/usr/share/dbus-1/session.d \
	dbussystem=/usr/share/dbus-1/system.d \
	dbussystemservices=/usr/share/dbus-1/system-services \
	dbusconfdir=/etc/dbus-1 \
	dbusinterfacesconfdir=/etc/dbus-1/interfaces \
	dbusservicesconfdir=/etc/dbus-1/services \
	dbussessionconfdir=/etc/dbus-1/session.d \
	dbussystemconfdir=/etc/dbus-1/system.d \
	dbussystemservicesconfdir=/etc/dbus-1/system-services \
	dbussystemservicesconfdir=$(TARGET_DIR)/etc/dbus-1/system-services \
	SYSTEMCTL="$(HOST_DIR)/bin/systemctl" \
	systemctlpath="$(HOST_DIR)/bin/systemctl" \
	systemdsystemconfdir="/etc/systemd/system" \
	systemdsystemunitdir="/usr/lib/systemd/system" \
	systemdutildir="/usr/lib/systemd" \
	systemdutilconfdir="/etc/systemd" \
	SYSTEMD_VERSION=$(ROOTFS_DRACUT_SYSTEMD_VERSION_SANATIZED) \
	UDEVVERSION=$(ROOTFS_DRACUT_SYSTEMD_VERSION_SANATIZED)

ROOTFS_DRACUT_KERNEL_MODULES = $(call qstrip,$(BR2_TARGET_ROOTFS_DRACUT_KERNEL_MODULES))
ROOTFS_DRACUT_MODULES_INCLUDE += $(call qstrip,$(BR2_TARGET_ROOTFS_DRACUT_MODULES))
ROOTFS_DRACUT_CUSTOM_KERNEL_CMDLINE = $(call qstrip,$(BR2_TARGET_ROOTFS_DRACUT_CUSTOM_KERNEL_CMDLINE))
ROOTFS_DRACUT_COMPRESSION_METHOD = $(call qstrip,$(BR2_TARGET_ROOTFS_DRACUT_COMPRESSION_METHOD))
ROOTFS_DRACUT_CONF_PATH = $(call qstrip,$(BR2_TARGET_ROOTFS_DRACUT_CONF_PATH))

ifneq ($(ROOTFS_DRACUT_CUSTOM_KERNEL_CMDLINE),)
ROOTFS_DRACUT_MKFS_CONF_OPTS += --kernel-cmdline=$(ROOTFS_DRACUT_CUSTOM_KERNEL_CMDLINE)
endif

ifeq ($(BR2_LINUX_KERNEL),y)
ROOTFS_DRACUT_KERNEL_IMAGE_PATH=$(BINARIES_DIR)/$(LINUX_TARGET_NAME)
ROOTFS_DRACUT_KERNEL_VERSION=$(LINUX_VERSION_PROBED)

ROOTFS_DRACUT_MKFS_CONF_OPTS += \
	--kver=$(ROOTFS_DRACUT_KERNEL_VERSION) \
	--kernel-image=$(ROOTFS_DRACUT_KERNEL_IMAGE_PATH) \
	--kmoddir="$(ROOTFS_DRACUT_TARGET_DIR)/lib/modules/$(ROOTFS_DRACUT_KERNEL_VERSION)"

ROOTFS_DRACUT_FS_ENV += KERNEL_VERSION=$(ROOTFS_DRACUT_KERNEL_VERSION)
ROOTFS_DRACUT_MODULES_INCLUDE += kernel-modules
else
ROOTFS_DRACUT_MKFS_CONF_OPTS += \
        --no-kernel
endif

ROOTFS_DRACUT_MKFS_CONF_OPTS += \
	--omit="$(ROOTFS_DRACUT_MODULES_OMIT)" \
	--drivers=$(ROOTFS_DRACUT_KERNEL_MODULES) \
	--$(ROOTFS_DRACUT_COMPRESSION_METHOD) \
	--conf=$(ROOTFS_DRACUT_CONF_PATH) \
	--no-hostonly \
	--nostrip

define ROOTFS_DRACUT_CMD
	(mkdir -p $(ROOTFS_DRACUT_DIR)/rootfs.dracut.tmp && \
		$(ROOTFS_DRACUT_FS_ENV) \
		$(HOST_DIR)/bin/dracut \
		$(ROOTFS_DRACUT_MKFS_CONF_OPTS) \
		$(BINARIES_DIR)/rootfs.cpio)
endef

$(eval $(rootfs))
