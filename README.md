# ubuntuPackerImage

If you use macOS, your multipass will not accept local image;

Please read the following article to test the packer image with qemu.
https://powersj.io/posts/ubuntu-qemu-cli/


```
brew tap hashicorp/tap
brew install hashicorp/tap/packer
brew install qemu
packer build template.json
cp output-qemu/packer-qemu packer-qemu.img

# generate seed.img by https://powersj.io/posts/ubuntu-qemu-cli/

# run image with seed.img and packer-qemu.img
qemu-system-x86_64  \
  -m 2G \
  -nographic \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive if=virtio,format=qcow2,file=packer-qemu.img \
  -drive if=virtio,format=raw,file=seed.img
```