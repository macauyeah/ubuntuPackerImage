# ubuntuPackerImage

## install packer in linux without apt-key
Because apt-key is deprecated. You cloud try manage the apt sources list.

```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg -o /tmp/hashicorp_gpg.txt
sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg /tmp/hashicorp_gpg.txt
echo  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

sudo apt-get update && sudo apt-get install -y packer

# target emulate qemu
sudo apt-get install -y qemu-system-x86
```

## macOS (other os that is not ubuntu)
If you use macOS, packer is fine, but your multipass does not accept local image;

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

# build image
```
packer build template.json
multipass launch file://$PWD/output-qemu/packer-qemu
```