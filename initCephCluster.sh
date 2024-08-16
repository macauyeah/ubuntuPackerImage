#!/bin/bash

# echo every command
set -o xtrace
# exit when error
set -e
# Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero return value.
set -o pipefail

nodeName=("node21" "node22" "node23")
macAddress=("52:54:00:4b:ab:21" "52:54:00:4b:ab:22" "52:54:00:4b:ab:23")
ip=("10.13.31.21" "10.13.31.22" "10.13.31.23")

tmpNetplanFile="tmp-10-custom.yaml"

for ((i=0 ; i < 3 ; i++)) ; do
    multipass launch 22.04 --name ${nodeName[i]} --cpus 2 -m 4G --network name=localbr,mode=manual,mac="${macAddress[i]}" --cloud-init cloud-config.yaml
    cat << EOF > $tmpNetplanFile
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "${macAddress[i]}"
            addresses: [${ip[i]}/24]
EOF
    multipass transfer $tmpNetplanFile ${nodeName[i]}:.
    multipass exec -n ${nodeName[i]} -- sudo bash -c "sudo cp $tmpNetplanFile /etc/netplan/10-custom.yaml"
    multipass exec -n ${nodeName[i]} -- sudo chmod go-rxw /etc/netplan/10-custom.yaml
    multipass exec -n ${nodeName[i]} -- sudo netplan apply
done
rm $tmpNetplanFile

multipass exec -n ${nodeName[0]} -- sudo apt install -y cephadm
# https://quay.ceph.io/repository/ceph-ci/ceph?tab=tags&tag=master
# ? docker image pull quay.ceph.io/ceph-ci/ceph:master
multipass exec -n ${nodeName[0]} -- sudo docker image pull quay.io/ceph/ceph:v17
multipass exec -n ${nodeName[0]} -- sudo docker image pull quay.io/ceph/ceph-grafana:9.4.7
multipass exec -n ${nodeName[0]} -- sudo docker image pull quay.io/prometheus/prometheus:v17
multipass exec -n ${nodeName[0]} -- sudo docker image pull quay.io/prometheus/alertmanager:v0.25.0
multipass exec -n ${nodeName[0]} -- sudo docker image pull quay.io/prometheus/node-exporter:v1.5.0

multipass exec -n ${nodeName[0]} -- sudo cephadm bootstrap --mon-ip ${ip[0]}

# This is a development version of cephadm.
# For information regarding the latest stable release:
#     https://docs.ceph.com/docs/pacific/cephadm/install
# Verifying podman|docker is present...
# Verifying lvm2 is present...
# Verifying time synchronization is in place...
# Unit systemd-timesyncd.service is enabled and running
# Repeating the final host check...
# docker (/usr/bin/docker) is present
# systemctl is present
# lvcreate is present
# Unit systemd-timesyncd.service is enabled and running
# Host looks OK
# Cluster fsid: 7286a7ea-5b82-11ef-8f1d-71f225c9586b
# Verifying IP 10.13.31.21 port 3300 ...
# Verifying IP 10.13.31.21 port 6789 ...
# Mon IP `10.13.31.21` is in CIDR network `10.13.31.0/24`
# - internal network (--cluster-network) has not been provided, OSD replication will default to the public_network
# Pulling container image quay.ceph.io/ceph-ci/ceph:master...
# Non-zero exit code 1 from /usr/bin/docker pull quay.ceph.io/ceph-ci/ceph:master
# /usr/bin/docker: stderr Error response from daemon: manifest for quay.ceph.io/ceph-ci/ceph:master not found: manifest unknown: manifest unknown


cephPub=$(multipass exec -n ${nodeName[0]} -- cat /etc/ceph/ceph.pub)
echo "$cephPub" | multipass exec -n ${nodeName[1]} -- sudo tee -a /root/.ssh/authorized_keys
echo "$cephPub" | multipass exec -n ${nodeName[2]} -- sudo tee -a /root/.ssh/authorized_keys

multipass exec -n ${nodeName[1]} -- sudo apt-get install docker.io
multipass exec -n ${nodeName[2]} -- sudo apt-get install docker.io

# for port forwarding
echo force update known_hosts public key of ${ip[0]}
sudo ssh-keygen -R ${ip[0]}
echo port forwarding to ${ip[0]}
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -L 0.0.0.0:8443:${ip[0]}:8443 ubuntu@${ip[0]}
