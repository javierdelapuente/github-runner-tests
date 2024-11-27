#!/bin/bash

set -x
set -euo pipefail

lxc delete github-runners --force || :

lxc init ubuntu:22.04 github-runners --vm -c limits.cpu=4 -c limits.memory=6GiB -d root,size=60GiB  --config=user.user-data="$(cat ./github-runners-user-data)" --config=user.network-config="$(cat ./github-runners-network-config)"


# lxc network set ghbr0 bridge.mtu=1400


lxc config device add github-runners eth0 nic nictype=bridged parent=ghbr0 name=eth0 hwaddr=00:14:4F:F8:00:03
lxc start github-runners

retry -d 5 -t 5 lxc exec github-runners -- true
lxc exec github-runners -- cloud-init status --wait
lxc config device add github-runners localdisk disk readonly=false source=/home/jpuente/github path=/home/ubuntu/github


# lxc exec github-runners -- su --login ubuntu

