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

	EXTERNAL_NETWORK_NAME=dev-vlan

	uuid=$(openstack server show spark-ukt0-test --format value -c id)
	floating_ip=$(openstack floating ip create $EXTERNAL_NETWORK_NAME -c floating_ip_address --format value)
	openstack server add floating ip $uuid $floating_ip

	# wait for server to startup
	while ! ping -c 1 -n -w 1 $floating_ip &> /dev/null
	do
		echo "."
	done
fi

server_info=$(openstack server show $NAME --format json)
echo $server_info

ip=$(openstack server show spark-ukt0-test --format value -c addresses | cut -c 6-)
uuid=$(openstack server show spark-ukt0-test --format value -c id)
#ssh $USER@$ip

./create-inventory-from-server.py $uuid > inventory

ansible-playbook -i inventory main.yml

deactivate
