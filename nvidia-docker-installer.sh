# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/sh


# p2.xlarge
# 00f0	10de102d	4b	        84000000	      100000000c	               0	        8200000c	               0	               0	               0	         1000000	       400000000	               0	         2000000	               0	               0	               0	nvidia
# This is pretty annoying.... note this is installed onto the host

apt-get update
apt-get install --yes gcc

cd /tmp
wget https://s3.amazonaws.com/chappiebot/packages/cuda/NVIDIA-Linux-x86_64-390.12.run
chmod +x NVIDIA-Linux-x86_64-390.12.run
/tmp/NVIDIA-Linux-x86_64-390.12.run --accept-license --ui=none --silent --no-drm --no-install-compat32-libs

nvidia-smi -pm 1
nvidia-smi -acp 0
nvidia-smi --auto-boost-default=0
nvidia-smi --auto-boost-permission=0
nvidia-smi -ac 2505,875

nvidia-smi
nvidia-modprobe -c0 -u

# Install docker-ce, nvidia-docker2
# apt-get update
# apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Add nvidia docker repo
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list

apt-get update && sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common
     
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -

apt-key fingerprint 0EBFCD88

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"

# Get docker-ce, nvidia-docker2
apt-get update
sed -i 's/^ExecStart=\/usr\/bin\/dockerd -H fd:\/\/.*$/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ -s=overlay2/' /lib/systemd/system/docker.service
apt-get install -y docker-ce
# apt-get install -y nvidia-docker2=2.0.3+docker17.03.2-1 nvidia-container-runtime=2.0.0+docker17.03.2-1

# systemctl daemon-reload
# apt-get install -y nvidia-docker2
# tee /etc/docker/daemon.json <<EOF
# {
#     "default-runtime": "nvidia",
#     "runtimes": {
#         "nvidia": {
#             "path": "/usr/bin/nvidia-container-runtime",
#             "runtimeArgs": []
#         }
#     }
# }
# EOF
# pkill -SIGHUP dockerd
# systemctl restart kubelet
