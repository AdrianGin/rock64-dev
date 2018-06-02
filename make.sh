#!/bin/sh

OUT=outputs

[ ! -d ${OUT} ] && mkdir ${OUT}



generate_boot_image() {
	BOOT=${OUT}/boot.img
	rm -rf ${BOOT}

	echo -e "\e[36m Generate Boot image start\e[0m"

	# 32 MB
	mkfs.vfat -n "boot" -S 512 -C ${BOOT} $((32 * 1024))

	mmd -i ${BOOT} ::/extlinux
	mcopy -i ${BOOT} -s extlinux/rk3328.conf ::/extlinux/extlinux.conf
	mcopy -i ${BOOT} -s ${OUT}/Image ::
	mcopy -i ${BOOT} -s ${OUT}/rk3328-rock64.dtb ::

	echo -e "\e[36m Generate Boot image : ${BOOT} success! \e[0m"
}



#make atf
#make uboot-build
make boot.img

generate_boot_image


make sd_card_image
