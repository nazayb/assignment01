#!/bin/bash

# Function to check if a command was successful
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Install QEMU and related packages
echo "Installing QEMU and related packages..."
sudo apt update && sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager
check_command "QEMU installation"

# Download Ubuntu cloud image
if [[ ! -e ./jammy-server-cloudimg-amd64.img ]]; then
    echo "Downloading Ubuntu cloud image..."
    wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
    check_command "Ubuntu cloud image download"
fi

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker.io
check_command "Docker installation"
sudo systemctl start docker
sudo systemctl enable docker

# Create Dockerfile
echo "Creating Dockerfile..."
cat << EOF > Dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y sysbench
COPY benchmark.sh /benchmark.sh
RUN chmod +x /benchmark.sh
CMD ["/benchmark.sh"]
EOF

# Build Docker image
echo "Building Docker image..."
sudo docker build -t benchmark .
check_command "Docker image build"

# Generate SSH key pair
echo "Generating SSH key pair..."
ssh-keygen -t rsa -b 2048 -f id_rsa -N ""
check_command "SSH key generation"

# Configure Cloud-Init for KVM
echo "Configuring Cloud-Init for KVM..."
mkdir -p kvm-instance
cat << EOF > kvm-instance/meta-data
instance-id: kvm-instance
local-hostname: kvm-instance
EOF

cat << EOF > kvm-instance/user-data
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $(cat id_rsa.pub)
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
EOF

# Create Cloud-Init ISO for KVM
sudo genisoimage -output kvm-instance/cidata.iso -volid cidata -joliet -rock kvm-instance/user-data kvm-instance/meta-data
check_command "KVM Cloud-Init ISO creation"

# Create and start KVM instance
echo "Creating and starting KVM instance..."
sudo virt-install \
    --name=ubuntu2204_kvm \
    --memory=2048 \
    --vcpus=2 \
    --disk path=./jammy-server-cloudimg-amd64.img,format=qcow2 \
    --disk path=kvm-instance/cidata.iso,device=cdrom \
    --import \
    --os-variant=ubuntu22.04 \
    --network bridge=virbr0 \
    --graphics=none \
    --noautoconsole
check_command "KVM instance creation"

# Configure Cloud-Init for QEMU
echo "Configuring Cloud-Init for QEMU..."
mkdir -p qemu-instance
cat << EOF > qemu-instance/meta-data
instance-id: qemu-instance
local-hostname: qemu-instance
EOF

cat << EOF > qemu-instance/user-data
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $(cat id_rsa.pub)
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
EOF

# Create Cloud-Init ISO for QEMU
sudo genisoimage -output qemu-instance/cidata.iso -volid cidata -joliet -rock qemu-instance/user-data qemu-instance/meta-data
check_command "QEMU Cloud-Init ISO creation"

# Create and start QEMU instance
echo "Creating and starting QEMU instance..."
qemu-img create -f qcow2 qemu-instance-ubuntu2204.img 10G
qemu-system-x86_64 \
    -name ubuntu2204_qemu \
    -m 2048 \
    -smp 2 \
    -drive file=./jammy-server-cloudimg-amd64.img,format=qcow2 \
    -drive file=qemu-instance/cidata.iso,format=raw \
    -net nic -net user,hostfwd=tcp::2222-:22 \
    -nographic &
check_command "QEMU instance creation"

# Copy benchmark script to VMs
echo "Copying benchmark script to VMs..."
scp -i id_rsa -o StrictHostKeyChecking=no benchmark.sh ubuntu@localhost:/home/ubuntu/
scp -i id_rsa -P 2222 -o StrictHostKeyChecking=no benchmark.sh ubuntu@localhost:/home/ubuntu/

# Set up cron job
echo "Setting up cron job..."
(crontab -l 2>/dev/null; echo "*/30 * * * * /home/ubuntu/execute-experiments.sh") | crontab -

echo "Preparation complete. VMs and Docker are ready for benchmarking."
