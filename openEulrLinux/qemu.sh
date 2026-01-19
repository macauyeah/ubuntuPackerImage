#!/bin/bash

# stop qemu-img after first run
qemu-img create -f qcow2 -F qcow2 -b openEuler-24.03-LTS-SP3-x86_64.qcow2 vm_disk.qcow2

# not support seed image

qemu-system-x86_64  \
  -cpu host -machine type=q35,accel=kvm -m 2048 \
  -nographic \
  -netdev id=net00,type=user,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net00 \
  -drive if=virtio,format=qcow2,file=vm_disk.qcow2

# login info:   root:openEuler12#$
