#!/bin/bash

# stop qemu-img after first run
#qemu-img create -f qcow2 -F qcow2 -b AnolisOS-8.10-x86_64-ANCK.qcow2 vm8.10.qcow2

# not support seed image

qemu-system-x86_64  \
  -cpu host -machine type=q35,accel=kvm -m 2048 \
  -nographic \
  -netdev id=net00,type=user,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net00 \
  -drive if=virtio,format=qcow2,file=vm8.10.qcow2

# login info:   anuser:anolisos
# Welcome to 5.10.0-136.12.0.86.oe2203sp1.x86_64
# kernel-5.10.0-136.108.0.188.oe2203sp1.x86_64
