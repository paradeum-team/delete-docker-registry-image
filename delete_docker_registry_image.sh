#!/bin/bash
# Function: clean registry image
# Author: jyliu
# Date: 2017-6-22

set -e
export REGISTRY_DATA_DIR=${REGISTRY_DATA_DIR:-/data/registry/docker/registry/v2}

HARBOR_URL=${1:-192.168.1.214}
registry_name=${2:-dataman_registry_1}
repo_name=$3
pre_tag=$4


if [ -z "$registry_name" ] || [ -z "$repo_name" ] || [ -z "$pre_tag" ];then
	echo "Usage: $0 <HARBOR_URL> <registry_name> <repo_name> <pre_tag>" && exit 1 
fi

tags=`curl -s -X GET "$HARBOR_URL/api/repositories/tags?repo_name=$repo_name" -H  "accept: application/json"|jq '.[]|select(startswith("'"$pre_tag"'"))'|tr -d \"`

if [ -z "$tags" ];then
	echo "There is no matching ${HARBOR_URL}/${repo_name}:$pre_tag* "
	exit 1
fi

echo "stop $registry_name"
docker stop $registry_name

for tag in $tags
do
	./delete_docker_registry_image.py --image ${repo_name}:$tag
done

echo "start $registry_name"
docker start $registry_name
