#!/bin/bash

# Special Clean For Huawei Kernel.
if [ -d include/config ];
then
    echo "Find config,will remove it"
	rm -rf include/config
else
	echo "No Config,good."
fi

echo " "
echo "***Setting environment...***"

export PATH=$PATH:~/gcc/aarch64-linux-android-4.9/bin
export CROSS_COMPILE=aarch64-linux-android-

export GCC_COLORS=auto
export ARCH=arm64
if [ ! -d "out" ];
then
	mkdir out
fi

start_time=$(date +%Y.%m.%d-%I_%M)

start_time_sum=$(date +%s)

echo "Saisissez pour quel appareil vous voulez compiler："
echo "1. OpenSource Huawei defconfig kirin710 EMUI9.1"
echo "Votre choix :"

read choice

case $choice in
  1)
    defconfig="merge_kirin710_defconfig"
    ;;
  *)
    echo "Aucun choix - fin du script"
    exit 1
    ;;
esac

echo "defconfig : $defconfig"


echo "***Building kernel...***"
make ARCH=arm64 O=out ${defconfig}


make ARCH=arm64 O=out -j64 2>&1 | tee kernel_log-${start_time}.txt

end_time_sum=$(date +%s)

end_time=$(date +%Y.%m.%d-%I_%M)

# Durée
duration=$((end_time_sum - start_time_sum))

hours=$((duration / 3600))
minutes=$(( (duration % 3600) / 60 ))
seconds=$((duration % 60))


echo "Temps de compilation：${hours}:${minutes}:${seconds}"

if [ -f out/arch/arm64/boot/Image.gz ];
then
	echo "***Packing kernel...***"

	cp out/arch/arm64/boot/Image.gz Image.gz 
	
	# Pack Enforcing Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x0 --cmdline "loglevel=4 initcall_debug=n page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=enforcing buildvariant=user" --tags_offset 0x07A00000 --kernel_offset 0x00080000 --ramdisk_offset 0x07c00000 --header_version 1 --os_version 9 --os_patch_level 2019-05-05 --output Kirin710_EMUI9.1-${end_time}.img
	
	# Pack Permissive Kernel
	tools/mkbootimg --kernel out/arch/arm64/boot/Image.gz --base 0x0 --cmdline "loglevel=4 initcall_debug=n page_tracker=on unmovable_isolate1=2:192M,3:224M,4:256M printktimer=0xfff0a000,0x534,0x538 androidboot.selinux=permissive buildvariant=user" --tags_offset 0x07A00000 --kernel_offset 0x00080000 --ramdisk_offset 0x07c00000 --header_version 1 --os_version 9 --os_patch_level 2019-05-05 --output Kirin710_EMUI9.1_PM-${end_time}.img

	echo "***Sucessfully built kernel...***"
	echo " "
	exit 0
else
	echo " "
	echo "***Failed!***"
	exit 0
fi
