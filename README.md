# ubuntuPackerImage
this guide will show you how to install ***packer*** and build an customize ubuntu 24.04 image which could run in ***multipass***.

## tested version
- packer 1.12.0
- qemu 8.2.2
- ubuntu 24.04
- multipass 1.14.1
- docker 28.0.4

# multipass
in ubuntu server
```bash
sudo snap install multipass
```

# packer
## install packer at ubuntu 24.04 with brew
```bash
sudo apt-get install build-essential
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# add homebrew to path
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew tap hashicorp/tap
brew install hashicorp/tap/packer
sudo apt-get install -y qemu-system-x86
```

## build image with packer, run with multipass
The packer generated image (local customize image) is also a cloud image. But only multipass running in ubuntu server will accept the local customize image.
```bash
packer init template.pkr.hcl
packer build template.pkr.hcl
multipass launch file://$PWD/output-autogenerated_1/packer-autogenerated_1
# you also can overwrite sources.list by --cloud-init
multipass launch file://$PWD/output-autogenerated_1/packer-autogenerated_1 --cloud-init cloud-config.yaml
```
Multipass requires ubuntu server that support virtualization cpu. I tested in bare-metal ubuntu server. I also tested with ubuntu server VM hosted in windows 10 hyper-v with ExposeVirtualizationExtensions. That means VM in VM still works.

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
    inline          = ["cp /tmp/sources.list /etc/apt/sources.list.d/ubuntu.sources"]
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

It cleans the image after installation process. I mainly copy it from [https://multipass.run/docs/building-multipass-images-with-packer](https://multipass.run/docs/building-multipass-images-with-packer) but made some changes for ubuntu 24.04 and converted to hcl format. I also remove the step of reseting user/group process because it will delete docker group and the final image will fail.

# Other topic
The original goal of my study is to automatically deploy a docker cluster with multipass. But bad luck, many limitation if you don't run multipass in ubuntu server.

## Docker cluster
If your multipass running in ubuntu server, you also could config static ip.

This is the script to install multipass and config static ip interface [setupMultipassWithFixIP.sh](setupMultipassWithFixIP.sh). The details will be explained in [other guide](https://github.com/macauyeah/VMDockerNotes/blob/main/MultipassStaticIpEN.md). 

If you successful build the image, config multipass with static ip, then you could initialize docker cluster with [initDockerCluster.sh](initDockerCluster.sh).

If your multipass running in windows or mac, you need to install docker when launching a new instance. You may take a look of [initDockerClusterWithoutStaticIp.sh](initDockerClusterWithoutStaticIp.sh). I did not verify the script every update because of network bandwidth.

If your ubuntu server running in windows hyper-v, you can also expose virtualization to it and you can run mulitpass in it. Shutdown the vm and type following command with administrator.
```powershell
Set-VMProcessor -VMName YOUR_VM_NAME -ExposeVirtualizationExtensions $true
```

## Packer in macOS
If you use macOS, packer is fine, but your multipass does not accept local image;

Instead, I use lima for testing packer output image
```
brew tap hashicorp/tap
brew install hashicorp/tap/packer
brew install qemu
packer build template.pkr.hcl

brew install lima
# if path variable not update, logout and login again

# update ABSOLUTE_PATH_TO_YOU_IMAGE in lima-packer-docker.yaml
limactl create --name packer-docker lima-packer-docker.yaml
limactl start packer-docker
limactl shell packer-docker
```


docker node update --availability drain node21
docker node update --availability active node21
docker node demote node21
