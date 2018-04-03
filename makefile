DOCKER_USR := adriangin
DOCKER_IMAGE_NAME := rock64-dev
DOCKER_TAG := x86_64

shell:
	docker build -t $(DOCKER_USR)/$(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .
	docker run --rm -it -h $(DOCKER_IMAGE_NAME) $(DOCKER_USR)/$(DOCKER_IMAGE_NAME):$(DOCKER_TAG)
