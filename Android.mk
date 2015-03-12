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

CODINARAMFS_INTERMEDIATES_COPY := 
CODINARAMFS_INTERMEDIATES_OUT := $(CODINARAMFS_OUT)/intermediates

CODINARAMFS_INITRAMFS_CMDLINE := 
CODINARAMFS_INITRAMFS_LIST := $(CODINARAMFS_OUT)/initramfs.list

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

# TODO: hardlink is not supported yet...

define codinaramfs-initramfs-keyparse
$(eval codinaramfs_initramfs_key := $(1)) \
$(eval codinaramfs_initramfs_key_i := \
	$(or \
		$(if $(filter $(1),-f), name location mode uid gid), \
		$(if $(filter $(1),-d), name mode uid gid), \
		$(if $(filter $(1),-n), name mode uid gid type maj min), \
		$(if $(filter $(1),-l), name target mode uid gid), \
		$(if $(filter $(1),-p), name mode uid gid), \
		$(if $(filter $(1),-s), name mode uid gid), \
		$(error codinaramfs: invalid initramfs key: $(1))))
endef

# foreach() mechanism: check for key_i, empty means keyparse, non-empty
# means in-param parse, process param & pop first key_i.
# key_i must be empty after parsing or error(uncomplete param detected)

define codinaramfs-initramfs-loop
$(foreach cf, $(CODINARAMFS_INITRAMFS_CMDLINE), \
	$(if $(codinaramfs_initramfs_key_i), \
		$(call $(1),$(codinaramfs_initramfs_key),$(firstword \
			$(codinaramfs_initramfs_key_i)),$(cf)) \
		$(eval codinaramfs_initramfs_key_i := $(wordlist 2, $(words \
			$(codinaramfs_initramfs_key_i)),$(codinaramfs_initramfs_key_i))), \
		$(call codinaramfs-initramfs-keyparse,$(cf)))) \
$(if $(codinaramfs_initramfs_key_i), \
	$(error codinaramfs: missing params for $(codinaramfs_initramfs_key)))
endef

define codinaramfs-initramfs-parse-st1
$(if $(filter $(1),-f), $(if $(filter $(2),location), $(3)))
endef

# TODO: stage2 not completed!

define codinaramfs-initramfs-parse-st2
$(if $(filter $(1),-f), \
	$(if $(filter $(2),location), $(3)))
endef

$(CODINARAMFS_INITRAMFS_OUT): $(CODINARAMFS_KERNEL_M) $(call codinaramfs-initramfs-loop, codinaramfs-initramfs-parse-st1)
	# TODO: uncompleted!

#

else
$(warning codinaramfs: codinaramfs is disabled)
endif # if CODINARAMFS_IS_ENABLED is true

