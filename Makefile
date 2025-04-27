# Docker image name
DOCKER_USERNAME=issgupat
DOCKER_IMAGE_NAME=snort-docker-sand5g
TAG=latest

.PHONY: build run push clean login 


# ╔════════════════════════════════════════╗
# ║ Docker Image Build, Delete, and Upload ║
# ╚════════════════════════════════════════╝

build:
	@docker build -t $(DOCKER_IMAGE_NAME) ./src/.
	@echo "Docker image $(DOCKER_IMAGE_NAME) built successfully."

delete:
	@docker rmi -f $(DOCKER_IMAGE_NAME)
	@echo "Docker image $(DOCKER_IMAGE_NAME) deleted successfully."

push:
	@docker tag $(DOCKER_IMAGE_NAME) $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME):$(TAG)
	@docker push $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME)
	@echo "Docker image $(DOCKER_USERNAME)/$(DOCKER_IMAGE_NAME) pushed to Docker Hub successfully."

# ╔════════════════╗
# ║ Help Function  ║
# ╚════════════════╝

help:
	@echo "Makefile for managing Docker images."
	@echo ""
	@echo "Targets:"
	@echo "  build         Build the Docker image."
	@echo "  delete        Delete the Docker image."
	@echo "  push          Push the Docker image to Docker Hub."
	@echo "  help                 Show this help message."
	@echo ""
