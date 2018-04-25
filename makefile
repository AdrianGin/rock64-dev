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

export KERNEL_DIR ?= $(KERNEL_REPO)
export UBOOT_DIR ?= $(UBOOT_REPO)
export ATF_DIR ?= $(ATF_REPO)
export RKBIN_DIR ?= $(RKBIN_REPO)

KERNEL_DEFCONFIG ?= rockchip_linux_defconfig

REPO_PREFIX := https://github.com/AdrianGin/

REPO_LIST := $(KERNEL_REPO) $(UBOOT_REPO) $(ATF_REPO) $(RKBIN_REPO)


ATF_MAKE ?= make -C $(ATF_DIR)
BL31 ?= $(ATF_DIR)/build/rk3328/release/bl31/bl31.elf
DDR ?= $(RKBIN_REPO)/rk33/rk3328_ddr_333MHz_v1.06.bin
MINILOADER ?= $(RKBIN_REPO)/rk33/rk3328_miniloader_v2.43.bin

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




#HOSTCC ?= aarch64-linux-gnu-gcc
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
	$(KERNEL_MAKE) HOSTCC=$(HOSTCC) menuconfig
	$(KERNEL_MAKE) savedefconfig
	mv $(KERNEL_DIR)/defconfig $(KERNEL_DIR)/arch/arm64/configs/$(KERNEL_DEFCONFIG)


.PHONY: kernel-build		# edit kernel config and save as defconfig
kernel-build:
	$(KERNEL_MAKE) HOSTCC=$(HOSTCC) $(KERNEL_DEFCONFIG) -j$$(nproc) V=0 all

UBOOT_MAKE ?= make -C $(UBOOT_DIR)
UBOOT_DEFCONFIG ?= rock64-rk3328_defconfig
.PHONY: uboot-menuconfig
uboot-menuconfig:
	$(UBOOT_MAKE) CROSS_COMPILE=$(CROSS_CC) $(UBOOT_DEFCONFIG) menuconfig

.PHONY: uboot-build
uboot-build: atf
	$(UBOOT_MAKE) CROSS_COMPILE=$(CROSS_CC) -j$$(nproc) u-boot.itb BL31=$(realpath $(BL31))
	$(UBOOT_MAKE) CROSS_COMPILE=$(CROSS_CC) -j$$(nproc) all 

ifeq (1,$(USE_UBOOT_SPL))
	$(UBOOT_DIR)/tools/mkimage -n rk3288 -T rksd -d $(UBOOT_DIR)/spl/u-boot-spl.bin  uboot_idbloader.img
else ifeq (1,$(USE_UBOOT_TPL))
	$(UBOOT_DIR)/tools/mkimage -n rk3288 -T rksd -d $(UBOOT_DIR)/tpl/u-boot-tpl.bin  uboot_idbloader.img
	cat $(UBOOT_DIR)/spl/u-boot-spl.bin >> uboot_idbloader.img
else
	$(UBOOT_DIR)/tools/mkimage -n rk3288 -T rksd -d $(DDR) mini_idbloader.img
	cat $(MINILOADER) >> mini_idbloader.img
endif

	$(RKBIN_DIR)/tools/loaderimage --pack --uboot $(UBOOT_DIR)/u-boot-dtb.bin uboot.img
	cp $(ATF_DIR)/build/rk3328/release/bl31.bin $(RKBIN_DIR)/rk33
	$(RKBIN_DIR)/tools/trust_merger rkbin/tools/RK3328TRUST.ini


OUTPUT_DIR=outputs
OUTPUT_IMAGE=sdcardimage.bin
OUTPUT_IMAGE_TPL=sdcardimage_tpl.bin

.PHONY: sd_card_image
sd_card_image: atf uboot-build
ifeq (1,$(USE_UBOOT_TPL))
	dd if=uboot_idbloader.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=64
	dd if=$(UBOOT_DIR)/u-boot.itb of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE_TPL) seek=$$((512-64))
else
	dd if=mini_idbloader.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=64
	dd if=uboot.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=16384
	dd if=$(RKBIN_DIR)/img/rk3328/trust.img of=$(OUTPUT_DIR)/$(OUTPUT_IMAGE) seek=24576
endif

.PHONY: atf
atf:
	$(ATF_MAKE) realclean
	$(ATF_MAKE) CROSS_COMPILE=$(CROSS_CC) -j$$(nproc) PLAT=rk3328 bl31


#include Makefile.kernel.mk
