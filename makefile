export RELEASE_NAME ?= 0.1~dev
export RELEASE ?= 1
export BOOT_TOOLS_BRANCH ?= master

#SPL is too big for RK3328, must use TPL or RK binary
USE_UBOOT_SPL=0
USE_UBOOT_TPL=0


USER := rock64dev
DOCKER_IMAGE_NAME ?= adriangin/rock64-dev
DOCKER_HOSTNAME ?= rock64-dev
DOCKER_TAG ?= x86_64
GIT_CLONE_DEPTH ?= 10


KERNEL_REPO := rock64-linux-kernel
UBOOT_REPO := rock64-u-boot
ATF_REPO := arm-trusted-firmware
RKBIN_REPO := rock64-rkbin
BUILD_ROOT_REPO := rock64-buildroot
LEDE_REPO := rock64-lede

export KERNEL_DIR ?= $(KERNEL_REPO)
export UBOOT_DIR ?= $(UBOOT_REPO)
export ATF_DIR ?= $(ATF_REPO)
export RKBIN_DIR ?= $(RKBIN_REPO)
export BUILD_ROOT_DIR ?= $(BUILD_ROOT_REPO)


KERNEL_DEFCONFIG ?= rockchip_linux_defconfig

REPO_PREFIX := https://github.com/AdrianGin/

REPO_LIST := $(KERNEL_REPO) $(UBOOT_REPO) $(ATF_REPO) $(RKBIN_REPO) $(BUILD_ROOT_REPO) $(LEDE_REPO)


ATF_MAKE ?= make -C $(ATF_DIR)
BL31 ?= $(ATF_DIR)/build/rk3328/release/bl31/bl31.elf

#BL31 ?= $(RKBIN_REPO)/rk33/rk3328_bl31_v1.39.bin

DDR ?= $(RKBIN_REPO)/rk33/rk3328_ddr_333MHz_v1.06.bin
MINILOADER ?= $(RKBIN_REPO)/rk33/rk3328_miniloader_v2.43.bin

#DDR ?= $(RKBIN_REPO)/rk33/rk3328_ddr_333MHz_v1.08.bin
#MINILOADER ?= $(RKBIN_REPO)/rk33/rk3328_miniloader_v2.44.bin

DTB=rk3328-rock64.dtb

OUTPUT_DIR=outputs
OUTPUT_IMAGE=sdcardimage.bin
OUTPUT_IMAGE_TPL=sdcardimage_tpl.bin

LOADER1_IMG = idbloader.img
LOADER2_IMG = u-boot.itb



.PHONY: sync
sync:

	@echo "Updating Git Repos:"
	@for p in  $(REPO_LIST); \
	do \
		if [ -d $$p ]; \
		then \
		echo "$$p exists!"; \
		cd $$p && git pull; cd ..; \
		else \
		echo "$$p does not exist!"; \
		git clone $(REPO_PREFIX)$$p.git --depth=1; \
		fi;\
	done

.PHONY: clean_repos
clean_repos:
	@echo "Removing Git Repos:"
	@for p in  $(REPO_LIST); \
	do \
		if [ -d $$p ]; \
		then \
		echo "Removing $$p"; \
		rm -rf $$p; \
		else \
		echo "Removing $$p"; \
		fi;\
	done	


.PHONY: shell
shell:
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .
	docker run --rm -it -h $(DOCKER_HOSTNAME)  \
               -v $(CURDIR):/home/$(USER) \
		$(DOCKER_IMAGE_NAME):$(DOCKER_TAG)



HOSTCC ?= gcc

CROSS_CC ?= aarch64-linux-gnu-

KERNEL_MAKE ?= make -C $(KERNEL_DIR) \
	EXTRAVERSION=$(KERNEL_EXTRAVERSION) \
	KDEB_PKGVERSION=$(RELEASE_NAME) \
	ARCH=arm64 \
	HOSTCC=$(HOSTCC) \
	CROSS_COMPILE=$(CROSS_CC)

.PHONY: menuconfig		# edit kernel config and save as defconfig
menuconfig:
	$(KERNEL_MAKE) $(KERNEL_DEFCONFIG)
	$(KERNEL_MAKE) menuconfig
	$(KERNEL_MAKE) savedefconfig
	mv $(KERNEL_DIR)/defconfig $(KERNEL_DIR)/arch/arm64/configs/$(KERNEL_DEFCONFIG)


.PHONY: kernel-build		# edit kernel config and save as defconfig
kernel-build:
	$(KERNEL_MAKE) -j$$(nproc) all

UBOOT_OUTPUT_DIR ?= ./tmp/u-boot-rock64
UBOOT_BUILD_DIR ?= $(UBOOT_DIR)/tmp/u-boot-rock64
UBOOT_MAKE ?= make -C $(UBOOT_DIR) KBUILD_OUTPUT=$(UBOOT_OUTPUT_DIR) CROSS_COMPILE=$(CROSS_CC) BL31=$(realpath $(BL31)) V=1
UBOOT_DEFCONFIG ?= rock64-rk3328_defconfig
.PHONY: uboot-menuconfig
uboot-menuconfig:
	$(UBOOT_MAKE) ARCH=arm64 $(UBOOT_DEFCONFIG) menuconfig
	$(UBOOT_MAKE) ARCH=arm64 savedefconfig

.PHONY: uboot-build
uboot-build: atf
	$(UBOOT_MAKE) CROSS_COMPILE=$(CROSS_CC) -j$$(nproc) u-boot.itb BL31=$(realpath $(BL31))
	$(UBOOT_MAKE) -j$$(nproc) all 
	$(UBOOT_MAKE) -j$$(nproc) u-boot.itb

ifeq (1,$(USE_UBOOT_SPL))
	$(UBOOT_BUILD_DIR)/tools/mkimage -n rk3328 -T rksd -d $(UBOOT_BUILD_DIR)/spl/u-boot-spl.bin  uboot_idbloader.img
else ifeq (1,$(USE_UBOOT_TPL))
	$(UBOOT_BUILD_DIR)/tools/mkimage -n rk3328 -T rksd -d $(UBOOT_BUILD_DIR)/tpl/u-boot-tpl.bin  uboot_idbloader.img
	#cat $(UBOOT_BUILD_DIR)/spl/u-boot-spl.bin >> uboot_idbloader.img
else
	$(UBOOT_BUILD_DIR)/tools/mkimage -n rk3328 -T rksd -d $(DDR) $(OUTPUT_DIR)/idbloader.img
	cat $(MINILOADER) >> $(OUTPUT_DIR)/idbloader.img
endif

	$(RKBIN_DIR)/tools/loaderimage --pack --uboot $(UBOOT_BUILD_DIR)/u-boot.bin $(OUTPUT_DIR)/u-boot.img 0x200000
	(cd $(RKBIN_DIR)/tools && ./trust_merger RK3328TRUST.ini --verbose)
	cp $(RKBIN_DIR)/tools/trust.img $(OUTPUT_DIR)/trust.img



.PHONY: boot.img
boot.img:
	cp $(KERNEL_DIR)/arch/arm64/boot/Image $(OUTPUT_DIR)
	cp $(KERNEL_DIR)/arch/arm64/boot/dts/rockchip/$(DTB) $(OUTPUT_DIR)
	


.PHONY: sd_card_image
sd_card_image:
	rm -f $(OUTPUT_DIR)/$(OUTPUT_IMAGE)
	dd if=/dev/zero of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) bs=1M count=0 seek=128
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) mklabel gpt
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) unit s mkpart loader1 64 8063
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) unit s mkpart loader2 16384 24575
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) unit s mkpart atf 24576 32767
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) unit s mkpart boot 32768 98303
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) unit s mkpart root 98304 100%
	parted -s $(OUTPUT_DIR)/$(OUTPUT_IMAGE) set 4 boot on

ifeq (1,$(USE_UBOOT_TPL))
	#dd if=uboot_idbloader.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=64 conv=notrunc
	#dd if=$(UBOOT_BUILD_DIR)/u-boot.itb of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=512


	rm $(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) -f
	#dd if=$(UBOOT_OUTPUT_DIR)/$(LOADER1_IMG) of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=64 conv=notrunc
	dd if=uboot_idbloader.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=64 conv=notrunc	
	#dd if=$(UBOOT_DIR)/u-boot.itb of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=512 conv=notrunc
else
	dd if=$(OUTPUT_DIR)/idbloader.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=64 conv=notrunc
	dd if=$(OUTPUT_DIR)/u-boot.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=16384 conv=notrunc
	dd if=$(OUTPUT_DIR)/trust.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=24576 conv=notrunc
	dd if=$(OUTPUT_DIR)/boot.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=32768 conv=notrunc
	dd if=$(BUILD_ROOT_DIR)/output/images/rootfs.ext4 of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=98304 conv=notrunc
endif
	


ROOT_CONFIG_MAKE ?= make -C $(BUILD_ROOT_REPO) \
	HOSTCC=$(HOSTCC) \
	CROSS_COMPILE=$(CROSS_CC)

.PHONY: root-config
root-config:
	$(ROOT_CONFIG_MAKE) rockchip_rk3328_minimal_config
	$(ROOT_CONFIG_MAKE) menuconfig


.PHONY: build-root
build-root: 
	$(ROOT_CONFIG_MAKE)

.PHONY: atf
atf:
	$(ATF_MAKE) CROSS_COMPILE=$(CROSS_CC) M0_CROSS_COMPILE=arm-linux-gnueabi- -j$$(nproc) PLAT=rk3328 bl31 DEBUG=1
	$(ATF_MAKE) CROSS_COMPILE=$(CROSS_CC) M0_CROSS_COMPILE=arm-linux-gnueabi- -j$$(nproc) PLAT=rk3328 bl31 LOG_LEVEL=LOG_LEVEL_INFO

	ln -rfs $(ATF_DIR)/build/rk3328/release/bl31.bin $(RKBIN_DIR)/rk33/bl31.bin
	ln -rfs $(ATF_DIR)/build/rk3328/release/bl31/bl31.elf $(RKBIN_DIR)/rk33/bl31.elf



.PHONY: clean
clean:
	rm $(OUTPUT_DIR)/*
	$(UBOOT_MAKE) clean



#include Makefile.kernel.mk
