################################################################################
#
# cpio to archive target filesystem
#
################################################################################

ifeq ($(BR2_ROOTFS_DEVICE_CREATION_STATIC),y)

define ROOTFS_CPIO_ADD_INIT
	if [ ! -e $(TARGET_DIR)/init ]; then \
		ln -sf sbin/init $(TARGET_DIR)/init; \
	fi
endef

else
# devtmpfs does not get automounted when initramfs is used.
# Add a pre-init script to mount it before running init
# We must have /dev/console very early, even before /init runs,
# for stdin/stdout/stderr
define ROOTFS_CPIO_ADD_INIT
	if [ ! -e $(TARGET_DIR)/init ]; then \
		$(INSTALL) -m 0755 fs/cpio/init $(TARGET_DIR)/init; \
	fi
	mkdir -p $(TARGET_DIR)/dev
	mknod -m 0622 $(TARGET_DIR)/dev/console c 5 1
endef

endif # BR2_ROOTFS_DEVICE_CREATION_STATIC

ROOTFS_CPIO_PRE_GEN_HOOKS += ROOTFS_CPIO_ADD_INIT

# --reproducible option was introduced in cpio v2.12, which may not be
# available in some old distributions, so we build host-cpio
ifeq ($(BR2_REPRODUCIBLE),y)
ROOTFS_CPIO_DEPENDENCIES += host-cpio
ROOTFS_CPIO_OPTS += --reproducible
endif

ifeq ($(BR2_TARGET_ROOTFS_CPIO_FULL),y)

define ROOTFS_CPIO_CMD
	cd $(TARGET_DIR) && \
	find . \
	| LC_ALL=C sort \
	| cpio $(ROOTFS_CPIO_OPTS) --quiet -o -H newc \
	> $@
endef

else ifeq ($(BR2_TARGET_ROOTFS_CPIO_DRACUT),y)

ROOTFS_CPIO_DEPENDENCIES += host-dracut host-kmod dracut

ROOTFS_CPIO_ENV += DRACUT_INSTALL_PATH=$(ROOTFS_CPIO_TARGET_DIR)/usr/bin:$(ROOTFS_CPIO_TARGET_DIR)/usr/sbin:$(ROOTFS_CPIO_TARGET_DIR)/usr/lib \
	prefix="" \
	DESTROOTDIR="$(ROOTFS_DRACUT_TARGET_DIR)" \
	DRACUT_ARCH=$(BR2_ARCH) \
	DRACUT_COMPRESS_BZIP2="$(HOST_DIR)/bin/bzip2" \
	DRACUT_COMPRESS_GZIP="$(HOST_DIR)/bin/gzip" \
	DRACUT_COMPRESS_LZMA="$(HOST_DIR)/bin/lzma" \
	DRACUT_FIRMWARE_PATH="$(ROOTFS_DRACUT_TARGET_DIR)/usr/lib/firmware" \
	DRACUT_INSTALL="$(HOST_DIR)/usr/lib/dracut-install" \
	DRACUT_MODPROBE="$(HOST_DIR)/sbin/modprobe" \
	STRIP_CMD="$(TARGET_CROSS)strip" \
	udevdir="$(ROOTFS_DRACUT_TARGET_DIR)/usr/lib/udev"
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
	systemdutilconfdir="/etc/systemd"

ROOTFS_CPIO_DRACUT_MODULES = $(call qstrip,$(BR2_TARGET_ROOTFS_CPIO_DRACUT_MODULES))
ifeq ($(BR_BUILDING),y)
ifneq ($(words $(ROOTFS_CPIO_DRACUT_MODULES)),$(words $(sort $(notdir $(ROOTFS_CPIO_DRACUT_MODULES)))))
$(error No two dracut modules can have the same basename, check your BR2_TARGET_ROOTFS_CPIO_DRACUT_MODULES setting)
endif
endif

ROOTFS_CPIO_DRACUT_CONF_FILES = $(call qstrip,$(BR2_TARGET_ROOTFS_CPIO_DRACUT_CONF_FILES))
ifeq ($(BR_BUILDING),y)
ifeq ($(ROOTFS_CPIO_DRACUT_CONF_FILES),)
$(error No dracut config file name specified, check your BR2_TARGET_ROOTFS_CPIO_DRACUT_CONF_FILES setting)
endif
ifneq ($(words $(ROOTFS_CPIO_DRACUT_CONF_FILES)),$(words $(sort $(notdir $(ROOTFS_CPIO_DRACUT_CONF_FILES)))))
$(error No two dracut config files can have the same basename, check your BR2_TARGET_ROOTFS_CPIO_DRACUT_CONF_FILES setting)
endif
endif

ifeq ($(BR2_LINUX_KERNEL),y)
ROOTFS_DRACUT_KERNEL_IMAGE_PATH=$(BINARIES_DIR)/$(LINUX_TARGET_NAME)
ROOTFS_DRACUT_KERNEL_VERSION=$(LINUX_VERSION_PROBED)

ROOTFS_CPIO_DEPENDENCIES += linux
ROOTFS_CPIO_OPTS += --kver $(ROOTFS_DRACUT_KERNEL_VERSION) \
	--kernel-image $(ROOTFS_DRACUT_KERNEL_IMAGE_PATH) \
	--kmoddir $(TARGET_DIR)/usr/lib/modules/$(ROOTFS_DRACUT_KERNEL_VERSION) \
	--fwdir $(TARGET_DIR)/usr/lib/firmware
else
ROOTFS_CPIO_OPTS += --no-kernel
endif

ifeq ($(BR2_ROOTFS_DEVICE_TABLE_SUPPORTS_EXTENDED_ATTRIBUTES),y)
ROOTFS_CPIO_ENV += DRACUT_NO_XATTR=true
endif

define ROOTFS_CPIO_CMD
	mkdir -p $(ROOTFS_CPIO_DIR)/tmp $(ROOTFS_CPIO_DIR)/confdir $(HOST_DIR)/lib/dracut/modules.d
	touch $(ROOTFS_CPIO_DIR)/empty-config
	$(foreach cfg,$(ROOTFS_CPIO_DRACUT_CONF_FILES), \
		cp $(cfg) $(ROOTFS_CPIO_DIR)/confdir/$(notdir $(cfg))
	)
	$(foreach m,$(ROOTFS_CPIO_DRACUT_MODULES), \
		cp -a $(m)/* $(HOST_DIR)/lib/dracut/modules.d/
	)
	$(ROOTFS_CPIO_ENV) \
	$(HOST_DIR)/bin/dracut \
		$(ROOTFS_CPIO_OPTS) \
		-c $(ROOTFS_CPIO_DIR)/empty-config \
		--confdir $(ROOTFS_CPIO_DIR)/confdir \
		--sysroot $(TARGET_DIR) \
		--tmpdir $(ROOTFS_CPIO_DIR)/tmp \
		--libdirs "$(TARGET_DIR)/lib $(TARGET_DIR)/usr/lib" \
		--basedir $(HOST_DIR)/usr/lib/dracut \
		-M \
		--force \
		--fstab \
		--verbose \
		--no-compress \
		$@
endef

endif #BR2_TARGET_ROOTFS_CPIO_DRACUT

ifeq ($(BR2_TARGET_ROOTFS_CPIO_UIMAGE),y)
ROOTFS_CPIO_DEPENDENCIES += host-uboot-tools
define ROOTFS_CPIO_UBOOT_MKIMAGE
	$(MKIMAGE) -A $(MKIMAGE_ARCH) -T ramdisk \
		-C none -d $@$(ROOTFS_CPIO_COMPRESS_EXT) $@.uboot
endef
ROOTFS_CPIO_POST_GEN_HOOKS += ROOTFS_CPIO_UBOOT_MKIMAGE
endif

$(eval $(rootfs))
