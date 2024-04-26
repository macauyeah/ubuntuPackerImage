#!/bin/bash
sudo snap install multipass lxd
sudo snap connect multipass:lxd lxd

sudo snap stop multipass.multipassd
sudo apt-get update && sudo apt-get install network-manager -y

sudo cp /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf "/usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf.$(date +%Y%m%d_%H%M%S)"

sudo cat << EOF > /tmp/10-globally-managed-devices.conf
[keyfile]
unmanaged-devices=*,except:type:wifi,except:type:gsm,except:type:cdma,except:type:bridge
EOF
sudo cp /tmp/10-globally-managed-devices.conf /usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf

sudo systemctl reload NetworkManager.service 
sudo nmcli connection add type bridge con-name localbr ifname localbr \
    ipv4.method manual ipv4.addresses 10.13.31.1/24

sudo snap start multipass.multipassd
echo "wait multipass to start up"
sleep 5m

multipass set local.driver=lxd
echo "wait multipass to get ready"
sleep 5m

multipass launch --name test1 --network name=localbr,mode=manual,mac="52:54:00:4b:ab:cd"
multipass exec -n test1 -- sudo bash -c 'cat << EOF > /etc/netplan/10-custom.yaml
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: no
            match:
                macaddress: "52:54:00:4b:ab:cd"
            addresses: [10.13.31.13/24]
EOF'
multipass exec -n test1 -- sudo chmod go-r /etc/netplan/10-custom.yaml
multipass exec -n test1 -- sudo netplan apply
multipass info test1
multipass delete test1 && multipass purge
