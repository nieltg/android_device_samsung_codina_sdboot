LOCAL_PATH := $(call my-dir)

CODINARAMFS_IS_ENABLED := true

ifneq ($(TARGET_DEVICE),codina)
$(warning codinaramfs: TARGET_DEVICE is not codina)
CODINARAMFS_IS_ENABLED := 
endif

CODINARAMFS_KERNEL := test
ifneq ($(TARGET_PREBUILT_KERNEL),test)
$(warning codinaramfs: TARGET_PREBUILT_KERNEL is not CODINARAMFS_KERNEL)
CODINARAMFS_IS_ENABLED := 
endif

ifeq ($(CODINARAMFS_IS_ENABLED),true)

$(warning codinaramfs: codinaramfs is enabled)
$(warning codinaramfs: should be used for testing purposes only)

# Hijack kernel.mk so it doesn't build the kernel.

ifdef TARGET_KERNEL_SOURCE
CODINARAMFS_KERNEL_SOURCE := $(TARGET_KERNEL_SOURCE)
endif

TARGET_KERNEL_SOURCE := 

# Prepare common variables.

CODINARAMFS_OUT := $(TARGET_OUT_INTERMEDIATES)/CODINARAMFS_OBJ
CODINARAMFS_KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/CODINARAMFS_KERNEL_OBJ

CODINARAMFS_OUT_INIT := $(CODINARAMFS_OUT)/init

# Include more files.

include \
	$(call first-makefiles-under, $(LOCAL_PATH)) \
	$(LOCAL_PATH)/kernel2.mk

else
$(warning codinaramfs: codinaramfs is disabled)
endif # if CODINARAMFS_IS_ENABLED is true

