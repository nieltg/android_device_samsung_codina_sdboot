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

CODINARAMFS_INTERMEDIATES_OUT := $(CODINARAMFS_OUT)/intermediates

CODINARAMFS_TOOL_PARSE := $(LOCAL_PATH)/parse.py

CODINARAMFS_INITRAMFS_LIST := $(CODINARAMFS_OUT)/initramfs.list


CODINARAMFS_INITRAMFS_CMDLINE := 
CODINARAMFS_INTERMEDIATES_COPY := 

# Include more files.

include \
	$(call first-makefiles-under, $(LOCAL_PATH)) \
	$(LOCAL_PATH)/kernel2.mk

#

unique_codinaramfs_intermediates_copy_pairs :=

$(foreach cf,$(CODINARAMFS_INTERMEDIATES_COPY), \
	$(if $(filter $(unique_codinaramfs_intermediates_copy_pairs),$(cf)),,\
		$(eval unique_codinaramfs_intermediates_copy_pairs += $(cf))))

unique_codinaramfs_intermediates_copy_dests :=

$(foreach cf,$(unique_codinaramfs_intermediates_copy_pairs), \
	$(eval _src := $(call word-colon,1,$(cf))) \
	$(eval _dest := $(call word-colon,2,$(cf))) \
		$(if $(filter $(unique_codinaramfs_intermediates_copy_dests),$(_dest)), \
			$(info CODINARAMFS_INTERMEDIATES_COPY $(cf) ignored.), \
			$(eval _fulldest := $(call append-path,$(CODINARAMFS_INTERMEDIATES_OUT),$(_dest))) \
			$(if $(filter %.xml,$(_dest)),\
				$(eval $(call copy-xml-file-checked,$(_src),$(_fulldest))),\
				$(eval $(call copy-one-file,$(_src),$(_fulldest)))) \
			$(eval unique_codinaramfs_intermediates_copy_dests += $(_dest))))

unique_codinaramfs_intermediates_copy_pairs :=
unique_codinaramfs_intermediates_copy_dests :=

#

codinaramfs_initramfs_key := 
codinaramfs_initramfs_key_i := 

# TODO: hardlink is not supported!

define codinaramfs-initramfs-keyparse \
$(eval codinaramfs_initramfs_key_i := \
	$(or \
		$(if $(filter $(codinaramfs_initramfs_key),-f), x x x x x), \
		$(if $(filter $(codinaramfs_initramfs_key),-d), x x x x), \
		$(if $(filter $(codinaramfs_initramfs_key),-n), x x x x x x x), \
		$(if $(filter $(codinaramfs_initramfs_key),-l), x x x x x), \
		$(if $(filter $(codinaramfs_initramfs_key),-p), x x x x), \
		$(if $(filter $(codinaramfs_initramfs_key),-s), x x x x), \
		$(error INVALID ARGUMENT)))
endef

$(foreach cf, $())


CODINARAMFS_INITRAMFS_PREREQUISITES := \
	$(shell $(CODINARAMFS_TOOL_PARSE) $(CODINARAMFS_INITRAMFS_CMDLINE) --mode pre)

$(CODINARAMFS_INITRAMFS_OUT): $(CODINARAMFS_KERNEL_M) $(CODINARAMFS_INITRAMFS_PREREQUISITES)
	$(CODINARAMFS_TOOL_PARSE) $(CODINARAMFS_INITRAMFS_LIST) --kmod $(CODINARAMFS_KERNEL_M) > $@

#

else
$(warning codinaramfs: codinaramfs is disabled)
endif # if CODINARAMFS_IS_ENABLED is true

