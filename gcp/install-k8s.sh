#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh
apt install -y open-iscsi
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.8 --server https://3.142.194.218 --token t2wjqgm7vh98z8jpnxpgrzh6ds7bhvggk7b8s7rvg5gv8trjn2xhd9 --ca-checksum 18d436217e8d87d19667aaeb26a7fe02ca716c4b00ab370b62e853765d9217db --etcd --controlplane --worker