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

CODINARAMFS_SYMLINK_NAME := codinaramfs_dir
CODINARAMFS_SYMLINK_OUT := $(CODINARAMFS_KERNEL_OUT)/$(CODINARAMFS_SYMLINK_NAME)

CODINARAMFS_INTERMEDIATE_COPY := 
CODINARAMFS_INTERMEDIATE_OUT := $(CODINARAMFS_OUT)/intermediates

CODINARAMFS_INITRAMFS_LIST := 
CODINARAMFS_INITRAMFS_TMP_HEAD := $(CODINARAMFS_OUT)/_head.list
CODINARAMFS_INITRAMFS_TMP_BODY := $(CODINARAMFS_OUT)/_tail.list
CODINARAMFS_INITRAMFS_OUT := $(CODINARAMFS_OUT)/initramfs.list

# Include more files.

include \
	$(call first-makefiles-under, $(LOCAL_PATH)) \
	$(LOCAL_PATH)/kernel2.mk

# Copy intermediate files.

unique_codinaramfs_intermediate_copy_pairs := 

$(foreach cf,$(CODINARAMFS_INTERMEDIATE_COPY), \
	$(if $(filter $(unique_codinaramfs_intermediate_copy_pairs),$(cf)),,\
		$(eval unique_codinaramfs_intermediate_copy_pairs += $(cf))))

unique_codinaramfs_intermediate_copy_dests := 

$(foreach cf,$(unique_codinaramfs_intermediate_copy_pairs), \
	$(eval _src := $(call word-colon,1,$(cf))) \
	$(eval _dest := $(call word-colon,2,$(cf))) \
	$(if $(_dest),, $(eval _dest := $(notdir $(_src)))) \
		$(if $(filter $(unique_codinaramfs_intermediate_copy_dests),$(_dest)), \
			$(info CODINARAMFS_INTERMEDIATE_COPY $(cf) ignored.), \
			$(eval _fulldest := $(call append-path,$(CODINARAMFS_INTERMEDIATE_OUT),$(_dest))) \
			$(info codinaramfs: DEBUG: _src=$(_src) _fulldest=$(_fulldest)) \
			$(if $(filter %.xml,$(_dest)),\
				$(eval $(call copy-xml-file-checked,$(_src),$(_fulldest))),\
				$(eval $(call copy-one-file,$(_src),$(_fulldest)))) \
			$(eval unique_codinaramfs_intermediate_copy_dests += $(_dest))))

unique_codinaramfs_intermediate_copy_pairs := 
unique_codinaramfs_intermediate_copy_dests := 

# Generate initramfs list file.

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

define codinaramfs-initramfs-mix-init
$(eval _mixf_outh := $(CODINARAMFS_INITRAMFS_TMP_HEAD)) \
$(eval _mixf_outp := $(CODINARAMFS_INITRAMFS_TMP_BODY)) \
true > $(CODINARAMFS_INITRAMFS_TMP_HEAD)
true > $(CODINARAMFS_INITRAMFS_TMP_BODY)
$(eval _mixc_objf := ) \
$(eval _mixc_objd := ) \
$(eval _mixc_idir := )
endef

define codinaramfs-initramfs-mix-prep
$(eval _prep_name := $(2:/%=%)) \
$(if $(filter $(_prep_name), $(_mixc_objd) $(_mixc_objf)), \
	$(error codinaramfs: duplicate initramfs entry: $(_prep_name)), \
	$(if $(filter -d, $(1)), \
		$(eval _mixc_objd += $(_prep_name)), \
		$(eval _mixc_objf += $(_prep_name)))) \
$(if $(filter $(_prep_name), $(_mixc_idir)), \
	$(if $(filter -d, $(1)),, \
		$(error codinaramfs: $(_prep_name) is needed to be a directory))) \
$(eval _prep_path := ) \
$(foreach mdir, $(subst /, ,$(dir $(_prep_name))), \
	$(if $(filter .,$(mdir)),, \
		$(eval _prep_path := $(patsubst /%, %, $(_prep_path)/$(mdir))) \
		$(if $(filter $(_prep_path), $(_mixc_objf)), \
			$(error codinaramfs: $(_prep_path) must be a directory)) \
		$(if $(filter $(_prep_path), $(_mixc_idir) $(_mixc_objd)),, \
			$(eval _mixc_idir += $(_prep_path)))))
endef

define codinaramfs-initramfs-mix-rloc
$(patsubst $(abspath $(CODINARAMFS_OUT))/%, $(CODINARAMFS_SYMLINK_NAME)/%, $(abspath $(1)))
endef

define codinaramfs-initramfs-mix-post
$(if $(_mixf_outh),, $(error codinaramfs: loop-mix: assert: mix-init not called)) \
echo "# This file is auto-generated" >> $(_mixf_outh)
echo >> $(_mixf_outh)
$(foreach mdir, $(_mixc_idir), \
	echo dir /$(mdir) 755 0 0 >> $(_mixf_outh)
) \
cat $(_mixf_outh) $(_mixf_outp) > $(1)
echo codinaramfs: initramfs.list has been written.
rm $(_mixf_outp) $(_mixf_outh)
$(eval _mixf_outp := ) \
$(eval _mixf_outh := ) \
$(eval _mixc_objf := ) \
$(eval _mixc_objd := ) \
$(eval _mixc_idir := )
endef

define codinaramfs-initramfs-mix-kmod
$(if $(_mixf_outp),, $(error codinaramfs: loop-mix: assert: mix-init not called)) \
$(eval _mixk_bas := $(call codinaramfs-initramfs-mix-rloc, \
	$(CODINARAMFS_KERNEL_M_PATH)))
$(foreach kmod, $(shell cat $(1)), \
	$(eval _mixk_src := $(_mixk_bas)/$(kmod)) \
	$(eval _mixk_dst := /lib/modules/$(kmod)) \
	$(call codinaramfs-initramfs-mix-prep, -f, $(_mixk_dst)) \
	echo file $(_mixk_dst) $(_mixk_src) 755 0 0 >> $(_mixf_outp)
)
endef

define codinaramfs-initramfs-loop
$(eval _loop_key_i := ) \
$(foreach cf, $(CODINARAMFS_INITRAMFS_LIST), \
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

define codinaramfs-initramfs-loop-parse
$(if $(filter $(1),-f), $(if $(filter $(2),location), $(3)))
endef

define codinaramfs-initramfs-loop-mix
$(if $(_mixf_outp),, $(error codinaramfs: loop-mix: assert: mix-init not called)) \
$(if $(2), $(eval _pbuf_$(2) := $(3)), \
	$(call codinaramfs-initramfs-mix-prep, $(1), $(_pbuf_name)) \
	$(if $(filter $(1),-f), \
		$(eval _pbuf_rloc := $(call codinaramfs-initramfs-mix-rloc, $(_pbuf_location))) \
		echo file $(_pbuf_name) $(_pbuf_rloc) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) >> $(_mixf_outp)
		) \
	$(if $(filter $(1),-d), \
		echo dir $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) >> $(_mixf_outp)
		) \
	$(if $(filter $(1),-n), \
		echo nod $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) $(_pbuf_type) $(_pbuf_maj) $(_pbuf_min) >> $(_mixf_outp)
		) \
	$(if $(filter $(1),-l), \
		echo slink $(_pbuf_name) $(_pbuf_target) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) >> $(_mixf_outp)
		) \
	$(if $(filter $(1),-p), \
		echo pipe $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) >> $(_mixf_outp)
		) \
	$(if $(filter $(1),-s), \
		echo sock $(_pbuf_name) $(_pbuf_mode) $(_pbuf_uid) $(_pbuf_gid) >> $(_mixf_outp)
		))
endef

$(CODINARAMFS_SYMLINK_OUT): $(CODINARAMFS_OUT)
	@ln -s $< $@

$(CODINARAMFS_INITRAMFS_OUT): $(CODINARAMFS_SYMLINK_OUT) $(CODINARAMFS_KERNEL_M) $(call codinaramfs-initramfs-loop, codinaramfs-initramfs-loop-parse)
	@$(call codinaramfs-initramfs-mix-init)
	@$(call codinaramfs-initramfs-loop, codinaramfs-initramfs-loop-mix)
	@$(call codinaramfs-initramfs-mix-kmod, $(CODINARAMFS_KERNEL_M))
	@$(call codinaramfs-initramfs-mix-post, $@)

else
$(warning codinaramfs: codinaramfs is disabled)
endif # if CODINARAMFS_IS_ENABLED is true

