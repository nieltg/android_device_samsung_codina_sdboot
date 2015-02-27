ifeq ($(TARGET_DEVICE),codina)

LOCAL_PATH := $(call my-dir)

$(warning codinaramfs: codinaramfs is not ready yet)
$(warning codinaramfs: should be used for testing purposes only)

# Prepare common variables.

CODINARAMFS_OUT := $(TARGET_OUT_INTERMEDIATES)/CODINARAMFS_OBJ
CODINARAMFS_KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/CODINARAMFS_KERNEL_OBJ

CODINARAMFS_BUILD_TARGET :=

# Include more files.

include $(call first-makefiles-under,$(LOCAL_PATH))
include kernel2.mk

# Define final rules.

$(CODINARAMFS_OUT):
	mkdir -p $(CODINARAMFS_OUT)

endif # if TARGET_DEVICE is codina

