## Makefile Usage

The Makefile provides a set of commands to simplify the management of Docker images for the Snort-Docker-SAND5G project. Below is an overview of the available commands and their functionality.

### Variables

| Variable                     | Default Value                  | Description                               |
| ---------------------------- | ------------------------------ | ----------------------------------------- |
| `DOCKER_USERNAME`            | `issgupat`                     | Docker Hub username for pushing images.   |
| `DOCKER_IMAGE_NAME`          | `snort-docker-sand5g`          | Name of the main Docker image.            |
| `DOCKER_IMAGE_NAME_MODIFIED` | `snort-docker-sand5g-modified` | Name of the modified Docker image.        |
| `TAG`                        | `latest`                       | Tag for the Docker image.                 |
| `SNORT3_TAG`                 | `3.9.1.0`                      | Snort3 version tag used during the build. |
| `DOCKERFILE`                 | `Dockerfile`                   | Path to the main Dockerfile.              |
| `DOCKERFILE_MODIFIED`        | `Dockerfile-modified`          | Path to the modified Dockerfile.          |

### Commands

| Command                | Description                                                                  |
| ---------------------- | ---------------------------------------------------------------------------- |
| `make build`           | Builds the main Docker image using the specified Dockerfile.                 |
| `make build-modified`  | Builds a modified Docker image based on the main image with updated scripts. |
| `make delete`          | Deletes the main Docker image.                                               |
| `make delete-modified` | Deletes the modified Docker image.                                           |
| `make push`            | Tags and pushes the main Docker image to Docker Hub.                         |
| `make help`            | Displays a list of available commands and their descriptions.                |

### Examples

#### Build the Main Docker Image

```bash
make build
```
