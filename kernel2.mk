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

KERNEL_OUT := $(CODINARAMFS_KERNEL_OUT)
KERNEL_CONFIG := $(KERNEL_OUT)/.config

KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_MODULES_INSTALL := $(realpath $(CODINARAMFS_ROOT))
KERNEL_MODULES_OUT := $(CODINARAMFS_ROOT)/lib/modules

# Utilities from source file.

ifneq ($(BOARD_KERNEL_IMAGE_NAME),)
	TARGET_PREBUILT_INT_KERNEL_TYPE := $(BOARD_KERNEL_IMAGE_NAME)
	TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/$(TARGET_PREBUILT_INT_KERNEL_TYPE)
else
	TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/zImage
	TARGET_PREBUILT_INT_KERNEL_TYPE := zImage
endif

ifeq ($(KERNEL_TOOLCHAIN),)
KERNEL_TOOLCHAIN := $(ARM_EABI_TOOLCHAIN)
endif
ifeq ($(KERNEL_TOOLCHAIN_PREFIX),)
KERNEL_TOOLCHAIN_PREFIX := arm-eabi-
endif

define mv-modules
	mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`; \
	if [ "$$mdpath" != "" ];then \
		mpath=`dirname $$mdpath`; \
		ko=`find $$mpath/kernel -type f -name *.ko`; \
		for i in $$ko; do $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)strip --strip-unneeded $$i; \
		mv $$i $(KERNEL_MODULES_OUT)/; done; \
	fi
endef

define clean-module-folder
	mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`; \
	if [ "$$mdpath" != "" ];then \
		mpath=`dirname $$mdpath`; rm -rf $$mpath; \
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
	CODINARAMFS_KERNEL_BIN := $(KERNEL_OUT)/piggy
else
	CODINARAMFS_KERNEL_BIN := $(TARGET_PREBUILT_INT_KERNEL)
endif

define config-codinaramfs
	$(KERNEL_SRC)/kernel/scripts/config --file $(KERNEL_OUT)/.config \
		--set-str CONFIG_INITRAMFS_SOURCE "$(realpath $(CODINARAMFS_OUT))" \
		--set-val CONFIG_INITRAMFS_ROOT_UID 0 \
		--set-val CONFIG_INITRAMFS_ROOT_GID 0
endef

# Create kernel built output dir.

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)
	mkdir -p $(KERNEL_MODULES_OUT)

# Make config & headers install.

$(KERNEL_CONFIG): $(KERNEL_OUT) $(CODINARAMFS_OUT)
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) VARIANT_DEFCONFIG=$(VARIANT_DEFCONFIG) SELINUX_DEFCONFIG=$(SELINUX_DEFCONFIG) $(KERNEL_DEFCONFIG)
	$(config-codinaramfs)

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) headers_install

# Make kernel main & external modules.

TARGET_KERNEL_MAIN_MODULES: $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) modules
	-$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) modules_install
	$(mv-modules)
	$(clean-module-folder)

$(TARGET_KERNEL_MODULES): TARGET_KERNEL_MAIN_MODULES

TARGET_KERNEL_ALL_MODULES: $(TARGET_KERNEL_MODULES)
	$(mv-modules)
	$(clean-module-folder)

# Make initramfs.

TARGET_KERNEL_INITRAMFS: $(CODINARAMFS_BUILD_TARGET)

# Make kernel binaries.

TARGET_KERNEL_BINARIES: $(KERNEL_OUT) $(KERNEL_CONFIG) TARGET_KERNEL_INITRAMFS
	$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)
	-$(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(TARGET_ARCH) $(ARM_CROSS_COMPILE) dtbs

$(TARGET_PREBUILT_INT_KERNEL): TARGET_KERNEL_BINARIES

$(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

