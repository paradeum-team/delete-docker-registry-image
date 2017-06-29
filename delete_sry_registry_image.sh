#!/bin/bash
# Function: clean registry image
# Author: jyliu
# Date: 2017-6-22

#set -e
export REGISTRY_DATA_DIR=${REGISTRY_DATA_DIR:-/data/sryregistry/docker/registry/v2}

usage(){
	echo "Usage: $0 -l|--sryurl <url> -u|--sryuser <username> -p|--srypasswd <passwd> -n|--registryname <registryname> -s|--namespace <namespace> -i|--imagename <imagename> -t|--pretag <pretag>" >&2
}

ARGS=`getopt -a -o l:u:p:n:s:i:t:h:: -l sryurl:,sryuser:,srypasswd:,registryname:,namespace:,imagename:,pretag:,help -- "$@"`

if [ $? != 0 ] ; then usage ; exit 1 ; fi  

eval set -- "${ARGS}"

while true ; do
    case "$1" in
        -l|--sryurl) SRY_URL=$2 ; shift 2 ;;
        -u|--sryuser) SRY_USER=$2 ; shift 2 ;;
        -p|--srypasswd) SRY_PASSWD=$2 ; shift 2 ;;
        -n|--registryname) REGISTRY_NAME=$2 ; shift 2 ;;
        -s|--namespace) NAMESPACE=$2 ; shift 2 ;;
        -i|--imagename) IMAGENAME=$2 ; shift 2 ;;
        -t|--pretag) PRE_TAG=$2 ; shift 2 ;;
	-h|--help) usage ; exit 0  ;;
        --) shift ; break ; ;;
        *) usage ; exit 1; ;;
    esac
done


if [ -z "$SRY_URL" ] || [ -z "$SRY_USER" ] || [ -z "$SRY_PASSWD" ] || [ -z "$REGISTRY_NAME" ] || [ -z "$NAMESPACE" ] || [ -z "$IMAGENAME" ] || [ -z "$PRE_TAG" ];then
	usage && exit 1
fi

export SRY_SERVER=$SRY_URL
token=`./get_token.sh $SRY_USER $SRY_PASSWD`

select_namespace=${NAMESPACE#*/}

tags=`curl -s -X GET -H "Authorization: $token" "${SRY_URL}/v1/tags?namespace=${select_namespace}&image=${IMAGENAME}"|jq '.data[].Tag|select(startswith("'"$PRE_TAG"'"))'|tr -d \"`

if [ -z "$tags" ];then
	echo "There is no matching ${SRY_URL}/${NAMESPACE}/${IMAGENAME}:$PRE_TAG* "
	exit 1
fi

echo "$tags"

json_tags='{"tags":[ '
for tag in $tags;do
	json_tags+='"'"$tag"'",'
done
json_tags=`echo $json_tags|sed 's/,$//'`
json_tags="${json_tags} ]}"

ret=`curl -s -X PATCH -H "Authorization: $token" "${SRY_URL}/v1/tags/${select_namespace}/${IMAGENAME}/delete" -d "${json_tags}"`

code=`echo $ret|jq '.code'`
if [ "$code" -ne 0 ];then
	echo "$ret"
	exit 1
fi

echo "stop $REGISTRY_NAME"
docker stop $REGISTRY_NAME

for tag in $tags
do
	./delete_docker_registry_image.py --image ${NAMESPACE}/${IMAGENAME}:$tag -u
done

echo "start $REGISTRY_NAME"
docker start $REGISTRY_NAME
