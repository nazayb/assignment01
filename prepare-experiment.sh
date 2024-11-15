#! /bin/bash


if ! command -v qemu &> /dev/null; then
    echo "Installing modules..."
    sudo apt update && sudo apt install -y qemu qemu-kvm libvirt-daemon-system genisoimage virtinst
fi

if [[ ! -e ./jammy-server-cloudimg-amd64.img ]]; then
  wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
fi

sudo kvm-ok

# Install Docker
sudo apt-get install -y docker.io

sudo systemctl start docker

sudo systemctl enable docker

sudo docker build -t benchmark .

# Configure Cloud-Init (medium.com)

# Configure everything for KVM
cat >kvm-instance/meta-data <<EOF
local-hostname: kvm-instance
EOF

# Create SSH-Keys
ssh-keygen -t rsa -f ~/.ssh/id_rsa_kvm-instance -N ""

# Read Public key into Environment variable
export PUB_KEY=$(cat ~/.ssh/id_rsa_kvm-instance.pub)

# Create User-Data
cat >kvm-instance/user-data <<EOF
#cloud-config

users:
    -name: ubuntu
    ssh-authorized-keys:
        - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash

runcmd:
    -echo "AllowUsers ubuntu" >> /etc/ssh/ssh_config
    -restart ssh
EOF

# Create Image containing just declared user data
sudo genisoimage -output kvm-instance/cidata.iso -v cidata -j -r kvm-instance/user-data kvm-instance/meta-data

sudo virt-install \
    --name=ubuntu2204_kvm \
    --memory=2048 \
    -vcpus=1 \
    --disk path=kvm-instance-ubuntu2204.img,format=qcow2 \
    --disk path=kvm-instance/cidata.iso,device=cdrom \
    --import \
    --os-variant=ubuntu22.04 \
    --network=default \
    --graphics=none \
    --noautoconsole


# Configure everything for QEMU
cat >qemu-instance/meta-data <<EOF
local-hostname: qemu-instance
EOF

# Create SSH-Keys
ssh-keygen -t rsa -f ~/.ssh/id_rsa_qemu-instance -N ""

# Read Public key into Environment variable
export PUB_KEY=$(cat ~/.ssh/id_rsa_qemu-instance.pub)

# Create User-Data
cat >qemu-instance/user-data <<EOF
#cloud-config

users:
    -name: ubuntu
    ssh-authorized-keys:
        - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash

runcmd:
    -echo "AllowUsers ubuntu" >> /etc/ssh/ssh_config
    -restart ssh
EOF

# Create Image containing just declared user data
sudo genisoimage -output qemu-instance/cidata.iso -v cidata -j -r qemu-instance/user-data qemu-instance/meta-data

sudo virt-install \
    --name=ubuntu2204_qemu \
    --memory=2048 \
    -vcpus=1 \
    --disk path=qemu-instance-ubuntu2204.img,format=qcow2 \
    --disk path=qemu-instance/cidata.iso,device=cdrom \
    --import \
    --os-variant=ubuntu22.04 \
    --network=default \
    --graphics=none \
    --noautoconsole
