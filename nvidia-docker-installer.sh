#!/bin/bash

set -o errexit
set -o pipefail
set -u

set -x

apt-get update
apt-get install --yes gcc

cd /tmp
wget https://s3.amazonaws.com/chappiebot/packages/cuda/NVIDIA-Linux-x86_64-390.12.run
chmod +x NVIDIA-Linux-x86_64-390.12.run
/tmp/NVIDIA-Linux-x86_64-390.12.run --accept-license --ui=none

nvidia-smi -pm 1
nvidia-smi -acp 0
nvidia-smi --auto-boost-default=0
nvidia-smi --auto-boost-permission=0
nvidia-smi -ac 2505,875

/sbin/modprobe nvidia-uvm

if [ "$?" -eq 0 ]; then
  # Find out the major device number used by the nvidia-uvm driver
  D=`grep nvidia-uvm /proc/devices | awk '{print $1}'`
  mknod -m 666 /dev/nvidia-uvm c $D 0
else
  echo "Unable to modprobe nvidia-uvm"
fi

# Install docker-ce, nvidia-docker2
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Add nvidia docker repo
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/debian8/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

# Get docker-ce, nvidia-docker2
apt-get update
apt-get install -y nvidia-docker2

tee /etc/docker/daemon.json <<EOF
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
pkill -SIGHUP dockerd
systemctl restart kubelet
