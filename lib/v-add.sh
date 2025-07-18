#!/bin/bash

vm_name=$1
iso_path=$2
disk_size=${3:-"20G"}
username=${4:-"ubuntu"}
password=${5:-"ubuntu"}
password_hash=$(mkpasswd --method=SHA-512 "$password")

# Check if vm_name argument is missing
if [ -z "$vm_name" ]; then
    echo "VM name is not provided. Exiting..."
    exit 1
fi

# Check ISO file
if [ -z "$iso_path" ]; then
  echo "ISO file is not provided. Exiting..."
  exit 1
else
  if [ ! -f "$iso_path" ]; then
      echo "File does not exist."
      exit 1
  fi
fi

mkdir -p disks
disk_name="$vm_name.qcow2"
disk_path="./disks/$disk_name"

if ! qemu-img create -f qcow2 "$disk_path" "$disk_size"; then
  echo "Failed to create disk image. It may already exist. Exiting..."
  exit 1
fi

vm_id=$(uuidgen)
mkdir "./$vm_id"
# Trap to clean up the directory when the script exits
trap "echo 'Cleaning up...'; rm -rf ./$vm_id" EXIT


cat <<EOF > "./$vm_id/user-data"
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: $vm_name
    username: $username
    password: $password_hash
  ssh:
    install-server: true
    allow-pw: true
  storage:
    layout:
      name: lvm
    bootloader: grub-pc
  locale: en_US
  keyboard:
    layout: us
  apt:
    geoip: true
  interactive-sections: []
  packages:
    - vim
    - git
  network:
    version: 2
    ethernets:
      ens3:
        dhcp4: true
        dhcp6: false
        optional: true
  late-commands:
    - curtin in-target --target=/target -- shutdown -h now
EOF


cat <<EOF > "./$vm_id/meta-data"
instance-id: $vm_name
local-hostname: $vm_name
EOF


echo "Creating iso file based on default seed data..."
cloud-localds "./$vm_id/seed.iso" "./$vm_id/user-data" "./$vm_id/meta-data"

# kernel and initrd is needed for auto-install procces
mnt_dir="./$vm_id/mnt"
sudo mkdir -p "$mnt_dir"
sudo mount -o loop "$iso_path" "$mnt_dir" || {
  echo "Failed to mount ISO file. Exiting..."
  exit 1
}
cp "$mnt_dir/casper/vmlinuz" "./$vm_id/kernel"
cp "$mnt_dir/casper/initrd" "./$vm_id/initrd.img"
sudo umount "$mnt_dir"

read -p "Do you want to proceed with the installation? [y/N]: " choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
  echo "Running the VM with pre-seeded installation..."
else
  echo "Installation aborted; You can run it later."
  exit 1
fi

sudo qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 2 \
  -cpu host \
  -kernel "./$vm_id/kernel" \
  -initrd "./$vm_id/initrd.img" \
  -cdrom "$iso_path" \
  -drive file="$disk_path",format=qcow2 \
  -drive file="./$vm_id/seed.iso",format=raw \
  -boot order=cdn \
  -netdev user,id=net0 \
  -device e1000,netdev=net0 \
  -append "autoinstall ds=nocloud" || {
    rm "$disk_path"
  }