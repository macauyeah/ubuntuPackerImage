#!/bin/bash

multipass launch --name node21 
multipass launch --name node22 
multipass launch --name node23

multipass transfer install_docker.sh node21:.
multipass transfer install_docker.sh node22:.
multipass transfer install_docker.sh node23:.

multipass exec -n node21 -- sudo ./install_docker.sh
multipass exec -n node22 -- sudo ./install_docker.sh
multipass exec -n node23 -- sudo ./install_docker.sh

multipass exec -n node21 -- sudo docker swarm init
multipass exec -n node21 -- sudo docker swarm join-token manager

managerToken=$(multipass exec -n node21 -- sudo docker swarm join-token manager | grep docker)
multipass exec -n node22 -- sudo $managerToken
multipass exec -n node23 -- sudo $managerToken
