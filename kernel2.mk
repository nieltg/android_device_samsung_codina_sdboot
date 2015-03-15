# Copyright (C) 2012 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Android makefile to build kernel as a part of Android Build

# kernel2.mk - To compile custom kernel
# This file is modified version of build/core/tasks/kernel.mk

TARGET_AUTO_KDIR := $(shell echo $(TARGET_DEVICE_DIR) | sed -e 's/^device/kernel/g')

CODINARAMFS_KERNEL_SOURCE ?= $(TARGET_AUTO_KDIR)
CODINARAMFS_KERNEL_S := $(CODINARAMFS_KERNEL_SOURCE)

# KERNEL_DEFCONFIG, etc will be provided by kernel.mk
# No need to define here, since they will be used in recipes (deferred)

CODINARAMFS_KERNEL_C := $(CODINARAMFS_KERNEL_OUT)/.config
CODINARAMFS_KERNEL_H := $(CODINARAMFS_KERNEL_OUT)/usr

CODINARAMFS_KERNEL_U_PATH := $(CODINARAMFS_OUT)
CODINARAMFS_KERNEL_U := $(CODINARAMFS_OUT)/initramfs.list

CODINARAMFS_KERNEL_M_PATH := $(CODINARAMFS_OUT)/modules
CODINARAMFS_KERNEL_M_PREP := $(CODINARAMFS_KERNEL_M_PATH)/out
CODINARAMFS_KERNEL_M := $(CODINARAMFS_KERNEL_M_PATH)/modules.list

# Utilities from source file.

ifneq ($(BOARD_KERNEL_IMAGE_NAME),)
	TARGET_PREBUILT_INT_KERNEL_TYPE := $(BOARD_KERNEL_IMAGE_NAME)
	TARGET_PREBUILT_INT_KERNEL := $(CODINARAMFS_KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/$(TARGET_PREBUILT_INT_KERNEL_TYPE)
else
	TARGET_PREBUILT_INT_KERNEL := $(CODINARAMFS_KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/zImage
	TARGET_PREBUILT_INT_KERNEL_TYPE := zImage
endif

ifeq ($(KERNEL_TOOLCHAIN),)
KERNEL_TOOLCHAIN := $(ARM_EABI_TOOLCHAIN)
endif
ifeq ($(KERNEL_TOOLCHAIN_PREFIX),)
KERNEL_TOOLCHAIN_PREFIX := arm-eabi-
endif

define mv-modules-mklist
	rm $(CODINARAMFS_KERNEL_M); \
	mdpath=`find $(CODINARAMFS_KERNEL_M_PREP) -type f -name modules.order`; \
	if [ "$$mdpath" != "" ]; then \
		mpath=`dirname $$mdpath`; \
		ko=`find $$mpath/kernel -type f -name *.ko`; \
		for i in $$ko; do \
			$(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)strip --strip-unneeded $$i; \
			mv $$i $(CODINARAMFS_KERNEL_M_PATH)/; \
			echo `basename $$i` >> $(CODINARAMFS_KERNEL_M); \
		done; \
	fi
endef

ifeq ($(TARGET_ARCH),arm)
	ifneq ($(USE_CCACHE),)
		ccache := $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache
		# Check that the executable is here.
		ccache := $(strip $(wildcard $(ccache)))
	endif
	ARM_CROSS_COMPILE:=CROSS_COMPILE="$(ccache) $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)"
	ccache = 
endif

ifeq ($(HOST_OS),darwin)
	MAKE_FLAGS := C_INCLUDE_PATH=$(ANDROID_BUILD_TOP)/external/elfutils/0.153/libelf/
endif

ifeq ($(TARGET_KERNEL_MODULES),)
	TARGET_KERNEL_MODULES := no-external-modules
endif

# Custom utilities.

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
	$(info Using uncompressed kernel)
	CODINARAMFS_KERNEL := $(CODINARAMFS_KERNEL_OUT)/piggy
else
	CODINARAMFS_KERNEL := $(TARGET_PREBUILT_INT_KERNEL)
endif

define config-codinaramfs
	bash $(CODINARAMFS_KERNEL_S)/scripts/config --file $(CODINARAMFS_KERNEL_OUT)/.config \
		--set-str CONFIG_INITRAMFS_SOURCE "$(CODINARAMFS_KERNEL_U_PATH)" \
		--set-val CONFIG_INITRAMFS_ROOT_UID 0 \
		--set-val CONFIG_INITRAMFS_ROOT_GID 0
endef

# Create kernel built output dir.

$(CODINARAMFS_KERNEL_OUT) $(CODINARAMFS_KERNEL_U_PATH):
	mkdir -p $@

# Make config & headers install.

$(CODINARAMFS_KERNEL_C): $(CODINARAMFS_KERNEL_OUT) $(CODINARAMFS_KERNEL_U_PATH)
	$(MAKE) $(MAKE_FLAGS) -C $(CODINARAMFS_KERNEL_S) O=$(CODINARAMFS_KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) VARIANT_DEFCONFIG=$(VARIANT_DEFCONFIG) SELINUX_DEFCONFIG=$(SELINUX_DEFCONFIG) $(KERNEL_DEFCONFIG)
	$(config-codinaramfs)

$(CODINARAMFS_KERNEL_H): $(CODINARAMFS_KERNEL_OUT) $(CODINARAMFS_KERNEL_C)
	$(MAKE) $(MAKE_FLAGS) -C $(CODINARAMFS_KERNEL_S) O=$(CODINARAMFS_KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) headers_install

# Make kernel main & external modules.

KERNEL_MODULES_OUT := $(abspath $(CODINARAMFS_KERNEL_M_PREP))

TARGET_CODINARAMFS_KERNEL_M_MAIN: $(CODINARAMFS_KERNEL_OUT) $(CODINARAMFS_KERNEL_C) $(CODINARAMFS_KERNEL_H)
	$(MAKE) $(MAKE_FLAGS) -C $(CODINARAMFS_KERNEL_S) O=$(CODINARAMFS_KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) modules
	$(MAKE) $(MAKE_FLAGS) -C $(CODINARAMFS_KERNEL_S) O=$(CODINARAMFS_KERNEL_OUT) INSTALL_MOD_PATH=$(KERNEL_MODULES_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) modules_install

$(TARGET_KERNEL_MODULES): $(CODINARAMFS_KERNEL_OUT) $(CODINARAMFS_KERNEL_C) $(CODINARAMFS_KERNEL_H)

TARGET_CODINARAMFS_KERNEL_M_EXT: $(TARGET_KERNEL_MODULES)

$(CODINARAMFS_KERNEL_M): TARGET_CODINARAMFS_KERNEL_M_MAIN TARGET_CODINARAMFS_KERNEL_M_EXT
	$(mv-modules-mklist)
	@echo rm -fr $(CODINARAMFS_KERNEL_M_PREP)

# Rules to build initramfs.list should be defined somewhere
# This file only refers it as prerequisites

# Make kernel binaries.

$(TARGET_PREBUILT_INT_KERNEL): $(CODINARAMFS_KERNEL_OUT) $(CODINARAMFS_KERNEL_C) $(CODINARAMFS_KERNEL_U)
	$(MAKE) $(MAKE_FLAGS) -C $(CODINARAMFS_KERNEL_S) O=$(CODINARAMFS_KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)
	$(MAKE) $(MAKE_FLAGS) -C $(CODINARAMFS_KERNEL_S) O=$(CODINARAMFS_KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) dtbs

$(CODINARAMFS_KERNEL_OUT)/piggy: $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(CODINARAMFS_KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/compressed/piggy.gzip > $(CODINARAMFS_KERNEL_OUT)/piggy

