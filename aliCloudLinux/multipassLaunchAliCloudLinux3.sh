#!/bin/bash

multipass launch --name alinux3 \
    --cloud-init cloud-config.yaml \
    https://alinux3.oss-cn-hangzhou.aliyuncs.com/aliyun_3_x64_20G_nocloud_alibase_20250629.qcow2

# multipass shell alinux3
# multipass delete alinux3 && multipass purge
