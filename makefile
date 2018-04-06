export RELEASE_NAME ?= 0.1~dev
export RELEASE ?= 1
export BOOT_TOOLS_BRANCH ?= master


USER := rock64dev
DOCKER_IMAGE_NAME ?= adriangin/rock64-dev
DOCKER_HOSTNAME ?= rock64-dev
DOCKER_TAG ?= x86_64
GIT_CLONE_DEPTH ?= 10


KERNEL_REPO := rock64-linux-kernel
UBOOT_REPO := rock64-u-boot

export KERNEL_DIR ?= $(KERNEL_REPO)
export UBOOT_DIR ?= $(UBOOT_REPO)

KERNEL_DEFCONFIG ?= rockchip_linux_defconfig

REPO_PREFIX := https://github.com/AdrianGin/

REPO_LIST := $(KERNEL_REPO) $(UBOOT_REPO)

.PHONY: sync
sync:

	@echo "Updating Git Repos:"
	@for p in  $(REPO_LIST); \
	do \
		if [ -d $$p ]; \
		then \
		echo "$$p exists!"; \
		cd $$p; git pull; \
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
KERNEL_MAKE ?= make -C $(KERNEL_DIR) \
	EXTRAVERSION=$(KERNEL_EXTRAVERSION) \
	KDEB_PKGVERSION=$(RELEASE_NAME) \
	ARCH=arm64 \
	HOSTCC=$(HOSTCC) \
	CROSS_COMPILE=aarch64-linux-gnu-

.PHONY: menuconfig		# edit kernel config and save as defconfig
menuconfig:
	$(KERNEL_MAKE) $(KERNEL_DEFCONFIG)
	$(KERNEL_MAKE) HOSTCC=$(HOSTCC) menuconfig
	$(KERNEL_MAKE) savedefconfig
	mv $(KERNEL_DIR)/defconfig $(KERNEL_DIR)/arch/arm64/configs/$(KERNEL_DEFCONFIG)


.PHONY: kernel-build		# edit kernel config and save as defconfig
kernel-build:
	$(KERNEL_MAKE) HOSTCC=$(HOSTCC) $(KERNEL_DEFCONFIG) -j$$(nproc) V=0 all



#include Makefile.kernel.mk