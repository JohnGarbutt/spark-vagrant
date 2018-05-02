#!/bin/bash

virtualenv .venv-create
source .venv-create/bin/activate
pip install -U pip
pip install python-openstackclient

set -eux

NAME="spark-ukt0-test"
FLAVOR=${FLAVOR:-"4x16"}
IMAGE_NAME=${IMAGE_NAME:-"CentOS7"}
USER="centos"
KEYPAIR_NAME=${KEYPAIR_NAME:-mine}
NETWORK_NAME=${NETWORK_NAME:-test}

export OS_CLOUD=${OS_CLOUD:-"hphi"}

if ! openstack server show $NAME >/dev/null 2>&1; then
	openstack server create \
		--image $IMAGE_NAME \
		--flavor $FLAVOR \
		--key-name $KEYPAIR_NAME \
		--network $NETWORK_NAME \
		--wait \
		$NAME
fi

server_info=$(openstack server show $NAME --format json)
echo $server_info

deactivate
