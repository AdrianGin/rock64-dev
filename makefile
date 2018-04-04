export RELEASE_NAME ?= 0.1~dev
export RELEASE ?= 1
export BOOT_TOOLS_BRANCH ?= master
export KERNEL_DIR ?= rock64-linux-kernel
export UBOOT_DIR ?= u-boot

USER := rock64dev
DOCKER_IMAGE_NAME ?= adriangin/rock64-dev
DOCKER_HOSTNAME ?= rock64-dev
DOCKER_TAG ?= x86_64
GIT_CLONE_DEPTH ?= 10


KERNEL_REPO := rock64-linux-kernel
UBOOT_REPO := rock64-u-boot

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



#include Makefile.kernel.mk