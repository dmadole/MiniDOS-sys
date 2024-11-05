This command installs a bootloader on an Elf/OS disk to make it bootable.

With two arguments, a filename, and a drive specifier, it installs the original Elf/OS boot loader which loads the kernel from sectors 1-16 of the disk, and it copies the specified kernel into those sectors.

With one argument, a drive specifier, it installs a new bootloader which is able to load a kernel from the filesystem at the path /os/kernel. In this case sectors 1-16 are not needed and are left unchanged. Be sure a kernel exists at the required path or the disk will not boot with the bootloader.

