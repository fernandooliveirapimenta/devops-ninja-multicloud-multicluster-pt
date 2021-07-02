#!/bin/bash
curl https://releases.rancher.com/install-docker/19.03.sh | sh
apt install -y open-iscsi
docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.8 --server https://18.116.67.159 --token xl95r8k6psbn47s4lmnkpr79dlsdbtf88fzs4txzx52kb6xrfphn55 --ca-checksum 0bb5e3982246774d5a30de589ee9a9e25c02d5719995eb57787a447970c6c740 --etcd --controlplane --worker