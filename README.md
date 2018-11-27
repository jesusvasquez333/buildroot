# Docker image with SLAC buildroot environment

This docker container will reproduce an environment with the SLAC specific buildroot tool used to cross compile kernel modules and packages.

The docker images are published in https://hub.docker.com/r/jesusvasquez333/buildroot/

## How to get the docker image

docker pull jesusvasquez333/buildroot

## How to use the docker image to build packages or kernel modules

From the directory where the source code of your package/module is locate run:

docker run -ti -v ${PWD}:/home/build/ jesusvasquez333/buildroot

By default `make` will be run when the container starts. If you need to run something different, you can start the container with:

docker run -ti -v ${PWD}:/home/build/ jesusvasquez333/buildroot /bin/bash

You will be inside the container with your source code located in `/home/build/`. You can can then run the specific command you need to build your package/module.

