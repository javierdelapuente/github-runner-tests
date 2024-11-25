#!/bin/bash

set -x
set -euo pipefail

# enable ipv4 forwarding in the host...
sudo sysctl -w net.ipv4.ip_forward=1

# not sure if all of this is necessary, but...
sudo ufw route allow in on  ghbr0
sudo ufw route allow in on ghbr0
sudo ufw route allow out on ghbr0


lxc delete openstack --force || :
lxc network delete ghbr0 || :


# dns.mode to assign to the same bridge. We could have two bridges instead.
lxc network create ghbr0 ipv6.address=none ipv4.address=192.168.20.1/24 ipv4.dhcp.ranges=192.168.20.200-192.168.20.240 ipv4.firewall=false ipv4.nat=true dns.mode=none


# lxc init ubuntu:22.04 openstack --vm -c limits.cpu=8 -c limits.memory=16GiB -d root,size=150GiB --config=user.network-config="$(cat ./openstack-network-config)" --config=user.user-data="$(cat ./openstack-user-data)" 
lxc init ubuntu:22.04 openstack --vm -c limits.cpu=8 -c limits.memory=16GiB -d root,size=150GiB --config=user.network-config="$(cat ./openstack-network-config)" --config=user.user-data="$(cat ./openstack-user-data)" 
lxc config device add openstack eth0 nic nictype=bridged parent=ghbr0 name=eth0 hwaddr=00:14:4F:F8:00:01
lxc config device add openstack eth1 nic nictype=bridged parent=ghbr0 name=eth1 hwaddr=00:14:4F:F8:00:02

# if we want ceph...
# lxc delete openstack --force || :
# lxc storage volume delete default openstack-vol || :
# lxc storage volume create default openstack-vol size=50GiB --type=block
# lxc config device add openstack openstack-vol disk pool=default source=openstack-vol

lxc start openstack

retry -d 5 -t 5 lxc exec openstack -- true
time lxc exec openstack -- cloud-init status --wait

lxc exec openstack -- su --login ubuntu

# ranges:
# openstack metallb:
# 192.168.20.10-192.68.20.29 

# openstack external:
# 192.168.20.30-192.68.20.69 

