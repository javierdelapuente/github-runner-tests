#!/bin/bash

set -x
set -euo pipefail

. .secrets
lxc delete github-runners --force || :

lxc init ubuntu:22.04 github-runners --vm -c limits.cpu=6 -c limits.memory=12GiB -d root,size=100GiB  --config=user.user-data="$(cat ./github-runners-user-data  | envsubst '$TOKEN')"
# it may be necessary to adjust the mtu in the bridge.
# lxc network set lxdbr0 bridge.mtu=1400
lxc start github-runners

retry -d 5 -t 5 lxc exec github-runners -- true
lxc exec github-runners -- cloud-init status --wait
lxc config device add github-runners localdisk disk readonly=false source=/home/jpuente/github path=/home/ubuntu/github

# lxc exec github-runners -- su --login ubuntu

