#!/bin/bash

set -x
set -euo pipefail

RISK=beta
RAM_MEMORY=40GiB
ROOT_DISK_SIZE=500GiB
CEPH_DISK_SIZE=500GiB

export RISK

# enable ipv4 forwarding in the host...
sudo sysctl -w net.ipv4.ip_forward=1

# not sure if all of this is necessary, but...
sudo ufw route allow in on  ghbr0
sudo ufw route allow in on ghbr0
sudo ufw route allow out on ghbr0

lxc delete openstack --force || :
lxc network delete ghbr0 || :

# dns.mode to assign to the same bridge. We could have two bridges instead.
lxc network create ghbr0 ipv6.address=none ipv4.address=192.168.20.1/24 ipv4.dhcp.ranges=192.168.20.200-192.168.20.240 ipv4.firewall=false ipv4.nat=false dns.mode=none || :


lxc init ubuntu:24.04 openstack --vm -c limits.cpu=12 -c limits.memory=${RAM_MEMORY} -d root,size=${ROOT_DISK_SIZE} --config=user.network-config="$(cat ./openstack-network-config)" --config=user.user-data="$(cat ./openstack-user-data | envsubst '$RISK' )"
lxc config device add openstack eth0 nic nictype=bridged parent=ghbr0 name=eth0 hwaddr=00:14:4F:F8:00:01
lxc config device add openstack eth1 nic nictype=bridged parent=ghbr0 name=eth1 hwaddr=00:14:4F:F8:00:02

# This is for ceph. There have to be a lxcpool storage defined.
# Otherwise, comment the next lines and in the openstack-user-data the microceph_config and remove the role storage on boostrap.
lxc storage volume delete lxcpool ceph-vol || :
lxc storage volume create lxcpool ceph-vol size=${CEPH_DISK_SIZE} --type=block
lxc config device add openstack ceph-vol disk pool=lxcpool source=ceph-vol


echo "Starting at $(date)"
lxc start openstack
# Besides at start, sometimes we get a websocket: close, not sure why.
time retry -d 5 -t 5 lxc exec openstack -- cloud-init status --wait

lxc exec openstack -- sudo -u ubuntu sunbeam openrc
lxc exec openstack -- sudo -u ubuntu cat /home/ubuntu/demo-openrc
lxc exec openstack -- sudo -u ubuntu sunbeam dashboard-url

# lxc exec openstack -- su --login ubuntu
