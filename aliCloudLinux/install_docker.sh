#!/bin/bash

# Add the Docker package repository
sudo wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Install the dnf repository compatibility plugin for Alibaba Cloud Linux 3
sudo dnf -y install dnf-plugin-releasever-adapter --repo alinux3-plus
# Install Docker Community Edition, the containerd.io container runtime, and the Docker Buildx and Compose plugins
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
