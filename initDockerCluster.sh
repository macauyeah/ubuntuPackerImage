#!/bin/bash

macAddress1="52:54:00:4b:ab:21"
macAddress2="52:54:00:4b:ab:22"
macAddress3="52:54:00:4b:ab:23"
ip1="10.13.31.21"
ip2="10.13.31.22"
ip3="10.13.31.23"
tmpNetplanFile="tmp-10-custom.yaml"
nodeName1="node21"
nodeName2="node22"
nodeName3="node23"

# assume that you already built os image with packer build template.json, and rename the output as docker.img
multipass launch file://$PWD/docker.img --name $nodeName1 --network name=localbr,mode=manual,mac="$macAddress1" --cloud-init cloud-config.yaml
multipass launch file://$PWD/docker.img --name $nodeName2 --network name=localbr,mode=manual,mac="$macAddress2" --cloud-init cloud-config.yaml
multipass launch file://$PWD/docker.img --name $nodeName3 --network name=localbr,mode=manual,mac="$macAddress3" --cloud-init cloud-config.yaml

cat << EOF > $tmpNetplanFile
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "$macAddress1"
            addresses: [$ip1/24]
EOF
multipass transfer $tmpNetplanFile $nodeName1:.
multipass exec -n $nodeName1 -- sudo bash -c "sudo cp $tmpNetplanFile /etc/netplan/10-custom.yaml"

cat << EOF > $tmpNetplanFile
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "$macAddress2"
            addresses: [$ip2/24]
EOF
multipass transfer $tmpNetplanFile $nodeName2:.
multipass exec -n $nodeName2 -- sudo bash -c "sudo cp $tmpNetplanFile /etc/netplan/10-custom.yaml"

cat << EOF > $tmpNetplanFile
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "$macAddress3"
            addresses: [$ip3/24]
EOF
multipass transfer $tmpNetplanFile $nodeName3:.
multipass exec -n $nodeName3 -- sudo bash -c "sudo cp $tmpNetplanFile /etc/netplan/10-custom.yaml"

rm $tmpNetplanFile

multipass exec -n $nodeName1 -- sudo netplan apply
multipass exec -n $nodeName2 -- sudo netplan apply
multipass exec -n $nodeName3 -- sudo netplan apply

multipass exec -n $nodeName1 -- sudo docker swarm init --advertise-addr $ip1
multipass exec -n $nodeName1 -- sudo docker swarm join-token manager

managerToken=$(multipass exec -n $nodeName1 -- sudo docker swarm join-token manager -q)
multipass exec -n $nodeName2 -- sudo docker swarm join --token $managerToken $ip1:2377
multipass exec -n $nodeName3 -- sudo docker swarm join --token $managerToken $ip1:2377

# for port forwarding
echo force update known_hosts public key of $ip1
sudo ssh-keygen -R $ip1
echo port forwarding to $ip1
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -L 0.0.0.0:8080:$ip1:8080 ubuntu@$ip1