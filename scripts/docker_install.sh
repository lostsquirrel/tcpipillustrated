#!/bin/bash
SOURCE_BASE_URL=https://mirrors.aliyun.com/docker-ce/linux/ubuntu/dists
UBUNTU_DISTRIB_CODENAME=$(lsb_release -a | grep Codename | awk '{print $2}')
USER=$(whoami)
DOCKER_VERSION=${DOCKER_VERSION:-17.12.1}
DOCKER_PACKAGE=docker-ce_${DOCKER_VERSION}~ce-0~ubuntu_amd64.deb
DOCKER_DEB=$UBUNTU_DISTRIB_CODENAME_$DOCKER_PACKAGE
sudo apt-get install libltdl7
if [ ! -f $DOCKER_PACKAGE ]
then
    echo 'file is not exist, start to download'
    wget $SOURCE_BASE_URL/$UBUNTU_DISTRIB_CODENAME/pool/stable/amd64/$DOCKER_PACKAGE
fi

sudo dpkg -i $DOCKER_PACKAGE
sudo apt install -f
sudo usermod -aG docker $USER
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
exit
