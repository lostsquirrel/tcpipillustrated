SHELL=/bin/bash

REGISTRY=registry.cn-hangzhou.aliyuncs.com
UBUNTU_VERSION=16.04
CUSTOM_VERSION=tcpipillustrated
REGISTRY_NAMESPACE=lisong
PROJECT_NAME=ubuntu

IMAGE_TAG=$(UBUNTU_VERSION)-$(CUSTOM_VERSION)
IMAGE=$(REGISTRY)/$(REGISTRY_NAMESPACE)/$(PROJECT_NAME)
VERSIONED_IMAGE=$(IMAGE):$(IMAGE_TAG)


build:
	docker build --no-cache -t $(VERSIONED_IMAGE) .

test:
	docker run --rm  $(VERSIONED_IMAGE)
# Push to registry. 推送到远程仓库
push:
	docker push $(VERSIONED_IMAGE)

# 拉取远程镜像
pull:
	docker pull $(VERSIONED_IMAGE)
