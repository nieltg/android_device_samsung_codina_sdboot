LOCAL_PATH := $(call my-dir)

# Use simple copy mechanism instead of BUILD_PREBUILT
# to prevent unnecessary copies in $(TARGET_OUT_INTERMEDIATES)

CODINARAMFS_INTERMEDIATE_COPY += \
	$(LOCAL_PATH)/busybox \
	$(LOCAL_PATH)/stage0 \
	$(LOCAL_PATH)/stage1 \
	$(LOCAL_PATH)/boot.cpio \
	$(LOCAL_PATH)/recovery.cpio

# Package content definitions.

CODINARAMFS_INITRAMFS_LIST += \
	-f /ramdisk/busybox $(CODINARAMFS_OBJ_OUT)/busybox 755 0 0 \
	-f /ramdisk/makedev $(CODINARAMFS_OBJ_OUT)/makedev 755 0 0 \
	-f /ramdisk/stage0 $(CODINARAMFS_OBJ_OUT)/stage0 755 0 0 \
	-f /ramdisk/stage1 $(CODINARAMFS_OBJ_OUT)/stage1 755 0 0 \
	-f /ramdisk/boot.cpio $(CODINARAMFS_OBJ_OUT)/boot.cpio 644 0 0 \
	-f /ramdisk/recovery.cpio $(CODINARAMFS_OBJ_OUT)/recovery.cpio 644 0 0 \
	-l /init /ramdisk/stage0 755 0 0

