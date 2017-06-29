#!/bin/bash
# Authou: jyliu
# Date: 2016-11-10

if [ -f ./config.cfg ];then
	. ./config.cfg
fi

BASE_URL=$SRY_SERVER

if [ ! -z "$1" ] && [ ! -z "$2" ];then
	SRY_ADMIN_USER=$1
	SRY_ADMIN_PASSWD=$2
fi

get_token(){
    token=`curl -s -X POST $BASE_URL/v1/login -d '{"userName":"'$SRY_ADMIN_USER'", "password":"'$SRY_ADMIN_PASSWD'"}' | awk -F \" '{print $6}'`
    echo "$token" > /tmp/sry_token_${SRY_ADMIN_USER}
}

token=`cat /tmp/sry_token_${SRY_ADMIN_USER} 2>/dev/null || echo`
if [ -z "$token" ];then
    get_token
fi

curl -s -X GET -H 'Authorization: '$token'' $BASE_URL/v1/aboutme | grep '"code":[[:space:]]*1' &>/dev/null && get_token

echo -n "$token"
