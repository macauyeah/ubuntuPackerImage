# ubuntuPackerImage
this guide will show you how to install ***packer*** and build an customize ubuntu 22.04 image which could run in ***multipass***.


## tested version
- packer 1.8.7
- qemu 6.2.0
- ubuntu 22.04
- multipass 1.11.0
- docker 23.0.4


## install packer in linux without apt-key
Because ***apt-key*** is deprecated. You cloud try manage the apt sources list.

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
packer build template.pkr.hcl
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

## build image
The local image only support in bare-metal ubuntu server
```bash
packer init template.pkr.hcl
packer build template.pkr.hcl
multipass launch file://$PWD/output-qemu/packer-qemu
# you also can overwrite sources.list by --cloud-init
multipass launch file://$PWD/output-qemu/packer-qemu --cloud-init ubuntumirror.yaml

# rename output file for later use
mv output-qemu/packer-qemu ./docker.img
```

## Notes about current template.pkr.hcl
Current packer template shows that how to install docker with defualt ubuntu image.

From line 48 to 61.
```
  provisioner "file" {
    destination = "/tmp/sources.list"
    source      = "sources.list"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["cp /tmp/sources.list /etc/apt/sources.list"]
    remote_folder   = "/tmp"
  }

  provisioner "shell" {
    scripts = ["install_docker.sh"]
  }
```

It replaces defualt sources.list so that you could change mirror to your specific location. This could help to speedup apt-get update command during docker installing process. But your mirror would be remove during next cloud-init.

From line 63 to 83
```
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = [
      "/usr/bin/apt-get clean",
      "rm -r /etc/netplan/50-cloud-init.yaml /etc/ssh/ssh_host* /etc/sudoers.d/90-cloud-init-users",
      "/usr/bin/truncate --size 0 /etc/machine-id",
      "/usr/bin/gawk -i inplace '/PasswordAuthentication/ { gsub(/yes/, \"no\") }; { print }' /etc/ssh/sshd_config",
      "rm -r /root/.ssh",
      "rm /snap/README",
      "find /usr/share/netplan -name __pycache__ -exec rm -r {} +",
      "rm /var/cache/pollinate/seeded /var/cache/motd-news",
      "rm -r /var/cache/snapd/*",
      "rm -r /var/lib/cloud /var/lib/dbus/machine-id /var/lib/private /var/lib/systemd/timers /var/lib/systemd/timesync /var/lib/systemd/random-seed",
      "rm /var/lib/ubuntu-release-upgrader/release-upgrade-available",
      "rm /var/lib/update-notifier/fsck-at-reboot",
      "find /var/log -type f -exec rm {} +",
      "rm -r /tmp/* /tmp/.*-unix /var/tmp/*",
      "/bin/sync",
      "/sbin/fstrim -v /"]
    remote_folder   = "/tmp"
  }
```

It cleans the image after installation process. I mainly copy it from [https://multipass.run/docs/building-multipass-images-with-packer](https://multipass.run/docs/building-multipass-images-with-packer) but made some changes for ubuntu 22.04 and converted to hcl format. I also remove the step of reseting user/group process because it will delete docker group and the final image will fail.


## Docker cluster
If your multipass running in a bare metal ubuntu server, you also could config static ip by [other guide](https://github.com/macauyeah/VMDockerNotes/blob/main/MultipassStaticIpEN.md). Then you could initialize docker cluster with [initDockerCluster.sh](initDockerCluster.sh).

If your multipass running in windows or mac, you need to install docker when launching a new instance. You may take a look of [initDockerClusterWithoutStaticIp.sh](initDockerClusterWithoutStaticIp.sh). I did not verify the script very time because of network bandwidth.

If your ubuntu server running in hyper-v, you can also expose virtualization to it and you can run mulitpass in it.
```powershell
Set-VMProcessor -VMName YOUR_VM_NAME -ExposeVirtualizationExtensions $true
```
