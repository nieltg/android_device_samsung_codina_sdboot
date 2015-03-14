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

# foreach() mechanism: check for key_i, empty means keyparse, non-empty
# means in-param parse, process param & pop first key_i.
# key_i must be empty after parsing or error(uncomplete param detected)

# TODO: hardlink is not supported yet...

define codinaramfs-initramfs-key
$(or \
	$(if $(filter $(1),-f), name location mode uid gid), \
	$(if $(filter $(1),-d), name mode uid gid), \
	$(if $(filter $(1),-n), name mode uid gid type maj min), \
	$(if $(filter $(1),-l), name target mode uid gid), \
	$(if $(filter $(1),-p), name mode uid gid), \
	$(if $(filter $(1),-s), name mode uid gid), \
	$(error codinaramfs: invalid initramfs key: $(1)))
endef

define codinaramfs-initramfs-loop
$(eval _loop_key_i := ) \
$(foreach cf, $(CODINARAMFS_INITRAMFS_CMDLINE), \
	$(if $(_loop_key_i), \
		$(call $(1),$(_loop_key),$(firstword $(_loop_key_i)),$(cf)) \
		$(eval _loop_key_i := $(wordlist 2, $(words \
			$(_loop_key_i)),$(_loop_key_i))) \
		$(if $(_loop_key_i),,$(call $(1),$(_loop_key),,)), \
		$(eval _loop_key := $(cf)) \
		$(eval _loop_key_i := $(call codinaramfs-initramfs-key,$(cf))))) \
$(if $(_loop_key_i), \
	$(error codinaramfs: missing params for $(_loop_key))) \
$(eval _loop_key := ) \
$(eval _loop_key_i := )
endef

define codinaramfs-initramfs-parse-st1
$(if $(filter $(1),-f), $(if $(filter $(2),location), $(3)))
endef

# TODO: stage2 not completed!

# Standard: dir <name> 755 0 0
# _pbuf_dir: store all created dirs

# $(if $(_pbuf_dir),, $(eval _pbuf_dir := ))
# END: $(eval _pbuf_dir := )

define codinaramfs-initramfs-parse-st2
$(if $(2), $(eval _pbuf_$(2) := $(3)), \
	$(if $(filter $(1),-f), \
		echo file $(_pbuf_name) $(_pbuf_location) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid);) \
	$(if $(filter $(1),-d), \
		echo dir $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid);) \
	$(if $(filter $(1),-n), \
		echo node $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) $(_pbuf_type) $(_pbuf_maj) $(_pbuf_min);) \
	$(if $(filter $(1),-l), \
		echo slink $(_pbuf_name) $(_pbuf_target) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid);) \
	$(if $(filter $(1),-p), \
		echo pipe $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid);) \
	$(if $(filter $(1),-s), \
		echo sock $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid);) \
)
endef

# CODINARAMFS_INITRAMFS_CMDLINE := \
#  -f /test1 loc2 644 0 1 \
#  -d /lib 755 0 0 \
#  -p /lib/pipe1 755 10 20
# This variant out:
#  -f, name, /test1
#  -f, location, loc2
#  -f, mode, 644
#  -f, uid, 0
#  -f, gid, 1
#  -f, ,
#  -d, name, /lib
#  -d, mode, 755
#  -d, uid, 0
#  -d, gid, 0
#  -d, ,
#  -p, name, /lib/pipe1
#  -p, mode, 755
#  -p, uid, 10
#  -p, gid, 20
#  -p, ,
# A line is produced when $(2) is empty.

$(CODINARAMFS_INITRAMFS_OUT): $(CODINARAMFS_KERNEL_M) $(call codinaramfs-initramfs-loop, codinaramfs-initramfs-parse-st1)
	# TODO: uncompleted!

#

else
$(warning codinaramfs: codinaramfs is disabled)
endif # if CODINARAMFS_IS_ENABLED is true

