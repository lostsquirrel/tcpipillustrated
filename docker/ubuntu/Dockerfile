FROM ubuntu:16.04
LABEL maintainer="songli1988@126.com"
# 使用国内的源
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

# 安装更新，安装基础工具，清除无用包及无用文件
RUN apt update \
    && apt upgrade -y -o Dpkg::Options::="--force-confold" \
    && apt install -y \
        apt-utils \
        apt-transport-https  \
        iproute2 \
        iputils-arping \
        net-tools \
        tcpdump \
        iputils-ping \
        curl \
        telnet \
        iputils-tracepath \
        tshark \
        openssh-server \
        traceroute \
    && apt autoremove \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo Asia/Shanghai > /etc/timezone \
    && mv /usr/sbin/tcpdump /usr/bin/tcpdump

ENV LC_ALL C.UTF-8

ENTRYPOINT ["tail", "-f", "/dev/null"]
