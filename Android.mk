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

CODINARAMFS_INITRAMFS_OUT := $(CODINARAMFS_OUT)/initramfs.list
CODINARAMFS_INTERMEDIATES_OUT := $(CODINARAMFS_OUT)/intermediates

#

CODINARAMFS_INTERMEDIATES_COPY := 
CODINARAMFS_INITRAMFS_LIST := 

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

CODINARAMFS_INITRAMFS_PREREQUISITES := \
	$(shell $(LOCAL_PATH)/parse.py $(CODINARAMFS_INITRAMFS_LIST) --mode pre)

$(CODINARAMFS_INITRAMFS_OUT): $(CODINARAMFS_KERNEL_M) $(CODINARAMFS_INITRAMFS_PREREQUISITES)
$(CODINARAMFS_INITRAMFS_OUT): _LOCAL := $(LOCAL_PATH)
	$(_LOCAL)/parse.py $(CODINARAMFS_INITRAMFS_LIST) --kmod $(CODINARAMFS_KERNEL_M) > $@

else
$(warning codinaramfs: codinaramfs is disabled)
endif # if CODINARAMFS_IS_ENABLED is true

