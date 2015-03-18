# codina-initramfs-sdboot

This repo contains simple init script which is especially made for __codina__.
Its purpose is to boot via SD card, so it'll be easier to test new ROM. To use,
it should be adjusted & be placed in Android build system.

It works by extracting specified .cpio file instead of default one if asked to.
The ROM on SD card must has __fstab__ pointed to the SD card itself instead of
internal partition. You should ensure that before placing new ROM, so it doesn't
break the internal ROM.

This is __EXPERIMENTAL__. Consider read the whole script to know how it work
before implementing it to your kernel.

Note: __busybox__ taken from TeamCanjica/Samsung_STE_Kernel.
