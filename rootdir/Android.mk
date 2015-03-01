LOCAL_PATH := $(call my-dir)

CODINARAMFS_ROOTDIR_BIN := ramdisk
CODINARAMFS_ROOTDIR_MODULES := 

# Package content definitions.

CODINARAMFS_ROOTDIR_COPY += \
	$(LOCAL_PATH)/busybox:$(CODINARAMFS_ROOTDIR_BIN)/busybox \
	$(LOCAL_PATH)/stage0:$(CODINARAMFS_ROOTDIR_BIN)/stage0 \
	$(LOCAL_PATH)/stage1:$(CODINARAMFS_ROOTDIR_BIN)/stage1 \
	$(LOCAL_PATH)/boot.cpio:$(CODINARAMFS_ROOTDIR_BIN)/boot.cpio \
	$(LOCAL_PATH)/recovery.cpio:$(CODINARAMFS_ROOTDIR_BIN)/recovery.cpio

CODINARAMFS_ROOTDIR_INIT_LN_TARGET := $(CODINARAMFS_ROOTDIR_BIN)/stage0

# TODO: there should be better way to get makedev compiled.
CODINARAMFS_ROOTDIR_COPY += \
	$(TARGET_OUT_INTERMEDIATES)/EXECUTABLES/makedev_intermediates/makedev:$(CODINARAMFS_ROOTDIR_BIN)/makedev

# Convert definitions to rules.

unique_codinaramfs_rootdir_copy_pairs :=

$(foreach cf,$(CODINARAMFS_ROOTDIR_COPY), \
	$(if $(filter $(unique_codinaramfs_rootdir_copy_pairs),$(cf)),,\
		$(eval unique_codinaramfs_rootdir_copy_pairs += $(cf))))

unique_codinaramfs_rootdir_copy_dests :=

$(foreach cf,$(unique_codinaramfs_rootdir_copy_pairs), \
	$(eval _src := $(call word-colon,1,$(cf))) \
	$(eval _dest := $(call word-colon,2,$(cf))) \
		$(if $(filter $(unique_codinaramfs_rootdir_copy_dests),$(_dest)), \
			$(info CODINARAMFS_ROOTDIR_COPY $(cf) ignored.), \
			$(eval _fulldest := $(call append-path,$(CODINARAMFS_OUT),$(_dest))) \
			$(if $(filter %.xml,$(_dest)),\
				$(eval $(call copy-xml-file-checked,$(_src),$(_fulldest))),\
				$(eval $(call copy-one-file,$(_src),$(_fulldest)))) \
			$(eval CODINARAMFS_ROOTDIR_MODULES += $(_fulldest)) \
			$(eval unique_codinaramfs_rootdir_copy_dests += $(_dest))))

unique_codinaramfs_rootdir_copy_pairs :=
unique_codinaramfs_rootdir_copy_dests :=

# Define how to build init.

$(CODINARAMFS_OUT_INIT): $(CODINARAMFS_ROOTDIR_MODULES)
	rm -f $@
	ln -s $(CODINARAMFS_ROOTDIR_INIT_LN_TARGET) $@

