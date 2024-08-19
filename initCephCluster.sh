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
multipass exec -n ${nodeName[0]} -- sudo cephadm bootstrap --mon-ip ${ip[0]} > fileContianDefaultDashboardAdminPassword.txt

cephPub=$(multipass exec -n ${nodeName[0]} -- cat /etc/ceph/ceph.pub)
echo "$cephPub" | multipass exec -n ${nodeName[1]} -- sudo tee -a /root/.ssh/authorized_keys
echo "$cephPub" | multipass exec -n ${nodeName[2]} -- sudo tee -a /root/.ssh/authorized_keys

multipass exec -n ${nodeName[1]} -- sudo apt-get install -y docker.io
multipass exec -n ${nodeName[2]} -- sudo apt-get install -y docker.io
multipass exec -n ${nodeName[0]} -- sudo cephadm shell -- ceph orch host add ${nodeName[1]} ${ip[1]} _admin
multipass exec -n ${nodeName[0]} -- sudo cephadm shell -- ceph orch host add ${nodeName[2]} ${ip[2]} _admin
multipass exec -n ${nodeName[0]} -- sudo cephadm shell -- ceph orch host ls --detail

multipass transfer fileContianDefaultDashboardAdminPassword.txt ${nodeName[0]}:./
rm fileContianDefaultDashboardAdminPassword.txt

echo force update known_hosts public key of ${ip[0]}
sudo ssh-keygen -R ${ip[0]}
echo port forwarding to ${ip[0]}
localMachinePublicIp=$(hostname -I | cut -d' ' -f1)
# hardcode local machine ipv4 public ip if above command not work well
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -L $localMachinePublicIp:8443:${ip[0]}:8443 ubuntu@${ip[0]}

# cat fileContianDefaultDashboardAdminPassword.txt in node21 if you need dashboard login;
