LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE:= makedev

LOCAL_SRC_FILES:= \
	main.c \
	util.c \
	devices.c

LOCAL_STATIC_LIBRARIES := \
	libcutils \
	libc

LOCAL_FORCE_STATIC_EXECUTABLE := true

LOCAL_MODULE_PATH := $(CODINARAMFS_INTERMEDIATE_OUT)

include $(BUILD_EXECUTABLE)

