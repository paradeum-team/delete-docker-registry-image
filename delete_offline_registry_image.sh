#!/bin/bash
export REGISTRY_DATA_DIR=/data/offline-registry_data/docker/registry/v2

imagename=$1

if [ -z "$imagename" ];then
	echo "Usage: $0 <imagename>"
	exit 1
fi
./delete_docker_registry_image.py --image $1
