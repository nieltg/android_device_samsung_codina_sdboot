# codina-initramfs-sdboot

This repo contains simple init script which is especially made for __codina__. Its purpose is to boot via SD card, so it will be easier to test new ROM.

This is __EXPERIMENTAL__. Consider read the whole things to know how it work before implementing it to your device.

## The Build System

Since initramfs is compiled with the kernel itself, there should be another way to compile the kernel instead of the default way.

To accomplish that, `Android.mk` hijacks default kernel compiling mechanism. `Android.mk` runs before `kernel.mk` and after `BoardConfig.mk`, so it can modify variables before they are read by `kernel.mk`.

`Android.mk` requires `TARGET_PREBUILT_KERNEL = $(CODINARAMFS_KERNEL)` to work, so `kernel.mk` can be tricked to believe that it has a prebuilt kernel that actually has rules, which is our own way to compile the kernel.

### Step 1: Add Local Manifest

There should be a codina kernel and this repo in your local repo.

To accomplish that, you can add local manifests which can be put on `.repo/local_manifests` directory. For example:

```XML
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
	
	<!-- kernels & bootables -->
	<project path="kernel/codina/ace2nutzer" name="ace2nutzer/Samsung_STE_Kernel" revision="3.0.101" />
	<project path="bootable/codinaramfs" name="nieltg/codina-initramfs-sdboot" revision="master" />
	
</manifest>
```

### Step 2: Modify `BoardConfig.mk`

Like usual, you should define `TARGET_KERNEL_SOURCE` and `TARGET_KERNEL_CONFIG` in your `BoardConfig.mk` to compile a kernel. For example:

```
TARGET_KERNEL_SOURCE := kernel/codina/ace2nutzer
TARGET_KERNEL_CONFIG := codina_ext4_defconfig
```

Then, you should add this hook to activate:

```Makefile
TARGET_PREBUILT_KERNEL = $(CODINARAMFS_KERNEL)
```

### Step 3: Internal Ramdisk & Recovery

This repo contains `boot.cpio` for stock ROM (Jelly Bean 4.1.2) which you should replace if you use another internal ROM.

Replace `boot.cpio` with your internal ROM ramdisk, so you can boot into it. You can also replace `recovery.cpio` with recovery system you would like to use.

### Step 4: Compile

Now, you can start compiling by typing `mka bootimage`, or `brunch codina` if you want to make a full build. You should also get message like this:

```
bootable/codinaramfs/Android.mk:18: codinaramfs: codinaramfs is enabled
bootable/codinaramfs/Android.mk:19: codinaramfs: should be used for testing purposes only
```

After the compilation process, you will get a kernel which is located at `out/target/product/codina/kernel`.

### Step 5: Flash

You can flash `out/target/product/codina/kernel` to your device by `dd`-ing to boot partition. Then, you can reboot your device. It should be able to boot internal ROM.

Don't forget to backup your old kernel. __You do it all at your own risk!__

## Runtime

After flashing the kernel, `init` which is actually `stage0` will be executed in every boot and it will prepare profilling & logging mechanism before executing `stage1`.

SD ROM partition will be mounted by `stage1`. If there is `enable_sdboot` file inside that partition, it will delete that file and boot SD ROM. Otherwise, it will boot the internal ROM.

You should apply some modifications to ROM which you install to SD. You should ensure that it works independently and will not break the internal ROM.

### Step 1: Partition SD Card

I assume you has flashed the kernel & able to boot to internal ROM.

Then, you should repartition your SD card to keep SD ROM & its internal data storage. There are some essential partitions:

- __`/dev/block/mmcblk1p1`__ (FAT) as external storage.
- __`/dev/block/mmcblk1p2`__ (ext4) to keep SD ROM & its `ramdisk.cpio`, approx. 600 Mb.
- __`/dev/block/mmcblk1p3`__ (ext4) as SD ROM internal storage, approx. 300 Mb.

### Step 2: Prepare SD ROM

ROM in SD card should not touch internal ROM. It should work independently. So, there are some modifications you must apply.

There are things which you must __ensure__:

- Any flashable zip you apply for the SD ROM __extracts to SD partitions__ instead of internal.
- Kernel is __not going to be replaced__ after flashing any flashable zip.
- SD ROM __mounts appropriate SD partitions__ instead of internal partitions.
- SD & internal ROM __look for kernel modules__ in `/lib/modules`.

To be exact, you should check and modify `updater-script` to ensure that flashable zip you apply for the SD ROM extracts to SD partitions. Replace any references to `mmcblk0p3` (system) with `mmcblk1p2`, and `mmcblk0p5` (data) with `mmcblk1p3`. For example:

```
mount("ext4", "EMMC", "/dev/block/mmcblk0p3", "/system", "");
```

And replace it like this:

```
mount("ext4", "EMMC", "/dev/block/mmcblk1p2", "/system", "");
```

Then, you should remove routine which reflash kernel in `updater-script` to ensure it will not be replaced. You should remove this:

```
package_extract_file("boot.img", "/dev/block/mmcblk0p15");
```

To ensure that SD ROM will mounts appropriate SD partitions, you should extract your SD ROM flashable zips & ramdisk to a directory. Then, search for any `mmcblk0` text and replace with appropriate SD boot partitions. I suggest you to check `fstab.samsungcodina` & `init.recovery.samsungcodina.rc` inside the ramdisk.

There are ROMs which look for kernel modules in `/system/lib/modules`. Since kernel modules are located in `/lib/modules`, you can replace `/system/lib/modules` with symlink to `/lib/modules`.

Then, you can recheck everything, take a backup, and start flashing. __You do it all at your own risk!__

### Step 3: Boot into SD ROM

You can boot SD ROM by creating a dummy file named `enable_sdboot` in `mmcblk1p2` (SD ROM partition) as a flag, so `stage1` knows that you want to boot the SD ROM instead of internal.

You can type this with root permission:

```
cd /tmp ; mkdir l ; mount -t ext4 /dev/block/mmcblk1p2 l
cd l ; echo > enable_sdboot ; cd .. ; umount l ; rmdir l
```

Then, you can reboot your phone and enjoy! To go back, just reboot your device again and it will boot to internal ROM.

