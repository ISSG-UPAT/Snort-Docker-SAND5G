# Docker image name
DOCKER_USERNAME?=issgupat
DOCKER_IMAGE_NAME?=snort-docker-sand5g
DOCKER_IMAGE_NAME_MODIFIED?=snort-docker-sand5g-modified
TAG?=latest
SNORT3_TAG ?= 3.9.1.0
DOCKERFILE ?= Dockerfile
DOCKERFILE_MODIFIED ?= Dockerfile-modified


.PHONY: build build-modified delete delete-modified push help


# ╔════════════════════════════════════════╗
# ║ Docker Image Build, Delete, and Upload ║
# ╚════════════════════════════════════════╝

build:
	docker build \
		--build-arg SNORT3_TAG=$(SNORT3_TAG) \
		-t $(DOCKER_IMAGE_NAME) \
		-f ./src/$(DOCKERFILE) ./src
	@echo "Docker image $(DOCKER_IMAGE_NAME)  built successfully."

# Build new image based on the previous one with updated scripts
build-modified:
	docker build \
		--build-arg BASE_IMAGE=$(DOCKER_IMAGE_NAME) \
		-t $(DOCKER_IMAGE_NAME_MODIFIED) \
		-f ./src/$(DOCKERFILE_MODIFIED) ./src


delete:
	@docker rmi -f $(DOCKER_IMAGE_NAME)
	@echo "Docker image $(DOCKER_IMAGE_NAME) deleted successfully."

delete-modified:
	@docker rmi -f $(DOCKER_IMAGE_NAME_MODIFIED)
	@echo "Docker image $(DOCKER_IMAGE_NAME_MODIFIED) deleted successfully."

push:
	@docker tag $(DOCKER_IMAGE_NAME) $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(TAG)
	@docker push $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME)
	@echo "Docker image $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME) pushed to Docker Hub successfully."

# ╔════════════════╗
# ║ Help Function  ║
# ╚════════════════╝

help:
	@echo "Makefile commands:"
	@echo "  build                - Build the Docker image."
	@echo "  build-modified       - Build a modified Docker image based on the previous one."
	@echo "  delete               - Delete the Docker image."
	@echo "  delete-modified      - Delete the modified Docker image."
	@echo "  push                 - Push the Docker image to Docker Hub."