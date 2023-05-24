#!/bin/bash

# assume that you already built os image with packer build template.json, and rename the output as docker.img
multipass launch file://$PWD/docker.img --name node21 --network name=localbr,mode=manual,mac="52:54:00:4b:ab:21"
multipass launch file://$PWD/docker.img --name node22 --network name=localbr,mode=manual,mac="52:54:00:4b:ab:22"
multipass launch file://$PWD/docker.img --name node23 --network name=localbr,mode=manual,mac="52:54:00:4b:ab:23"

multipass exec -n node21 -- sudo bash -c 'cat << EOF > /etc/netplan/10-custom.yaml
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "52:54:00:4b:ab:21"
            addresses: [10.13.31.21/24]
EOF'

multipass exec -n node22 -- sudo bash -c 'cat << EOF > /etc/netplan/10-custom.yaml
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "52:54:00:4b:ab:22"
            addresses: [10.13.31.22/24]
EOF'

multipass exec -n node23 -- sudo bash -c 'cat << EOF > /etc/netplan/10-custom.yaml
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "52:54:00:4b:ab:23"
            addresses: [10.13.31.23/24]
EOF'

multipass exec -n node21 -- sudo netplan apply
multipass exec -n node22 -- sudo netplan apply
multipass exec -n node23 -- sudo netplan apply

multipass exec -n node21 -- sudo docker swarm init --advertise-addr 10.13.31.21
multipass exec -n node21 -- sudo docker swarm join-token manager

managerToken=$(multipass exec -n node21 -- sudo docker swarm join-token manager -q)
multipass exec -n node22 -- sudo docker swarm join --token $managerToken 10.13.31.21:2377
multipass exec -n node23 -- sudo docker swarm join --token $managerToken 10.13.31.21:2377

# for port forwarding
echo force update known_hosts public key of 10.13.31.21
sudo ssh-keygen -R 10.13.31.21
echo port forwarding to 10.13.31.21
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -L 0.0.0.0:8080:10.13.31.21:8080 ubuntu@10.13.31.21
