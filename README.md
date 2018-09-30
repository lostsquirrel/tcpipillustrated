# tcpipillustrated

## 初始化基础虚拟机
1. 修改源
```sh
sudo cp /etc/apt/sources.list /etc/apt/sources.list_backup
sudo sed -i "s/us.archive.ubuntu.com/mirrors.ustc.edu.cn/g" /etc/apt/sources.list
sudo apt update
```

2. 安装 `docker` `make`
```sh
bash scripts/docker_install.sh
sudo apt install -y make openvswitch-switch arping
```

3. 关闭更新提示
```sh
sudo sed -i "s/Prompt=lts/Prompt=never/g" /etc/update-manager/release-upgrades
```

## 构建基础镜像

```sh
cd docker/ubuntu
make build
```

## 第一次运行，参照 `setupenv.sh` 逐条执行
```sh
imagename=registry.cn-hangzhou.aliyuncs.com/lisong/ubuntu:16.04-tcpipillustrated

# 创建图中所有的节点，每个一个容器
docker run --privileged=true --net none --name aix --hostname aix -d ${imagename}
docker run --privileged=true --net none --name solaris --hostname solaris -d ${imagename}
docker run --privileged=true --net none --name gemini --hostname gemini -d ${imagename}
docker run --privileged=true --net none --name gateway --hostname gateway -d ${imagename}
docker run --privileged=true --net none --name netb --hostname netb -d ${imagename}
docker run --privileged=true --net none --name sun --hostname sun -d ${imagename}
docker run --privileged=true --net none --name svr4 --hostname svr4 -d ${imagename}
docker run --privileged=true --net none --name bsdi --hostname bsdi -d ${imagename}
docker run --privileged=true --net none --name slip --hostname slip -d ${imagename}


docker ps

# 创建两个网桥，代表两个二层网络

ovs-vsctl add-br net1
ip addr s net1
ip link set net1 up
ip addr s net1

![](https://static001.geekbang.org/resource/image/4c/1e/4c0e633ddc53f3feb98946518c0cf21e.jpg)

# 将所有的节点连接到两个网络
chmod +x ./pipework

sudo ./pipework net1 aix 140.252.1.92/24
sudo ./pipework net1 solaris 140.252.1.32/24
sudo ./pipework net1 gemini 140.252.1.11/24
sudo ./pipework net1 gateway 140.252.1.4/24
sudo ./pipework net1 netb 140.252.1.183/24

sudo ./pipework net2 bsdi 140.252.13.35/27
sudo ./pipework net2 sun 140.252.13.33/27
sudo ./pipework net2 svr4 140.252.13.34/27
# ======================================================================
# 添加从slip到bsdi的p2p网络
# 创建一个peer的两个网卡
sudo ip link add name slipside mtu 1500 type veth peer name bsdiside mtu 1500

## sudo ip link del bsdiside
# 把其中一个塞到slip的网络namespace里面

DOCKERPID1=$(docker inspect '--format={{ .State.Pid }}' slip)
sudo ln -s /proc/${DOCKERPID1}/ns/net /var/run/netns/${DOCKERPID1}
sudo ip link set slipside netns ${DOCKERPID1}

# 把另一个塞到bsdi的网络的namespace里面
DOCKERPID2=$(docker inspect '--format={{ .State.Pid }}' bsdi)
sudo ln -s /proc/${DOCKERPID2}/ns/net /var/run/netns/${DOCKERPID2}
sudo ip link set bsdiside netns ${DOCKERPID2}

# 给slip这面的网卡添加IP地址
docker exec -it slip ip addr add 140.252.13.65/27 dev slipside
docker exec -it slip ip link set slipside up
docker exec -it slip ip addr
# 给bsdi这面的网卡添加IP地址
docker exec -it bsdi ip addr add 140.252.13.66/27 dev bsdiside
docker exec -it bsdi ip link set bsdiside up
docker exec -it bsdi ip addr
# 如果我们仔细分析，p2p网络和下面的二层网络不是同一个网络。
# p2p网络的cidr是140.252.13.64/27，而下面的二层网络的cidr是140.252.13.32/27

# 所以对于slip来讲，对外访问的默认网关是13.66
docker exec -it slip ip route add default via 140.252.13.66 dev slipside
docker exec -it slip ip route

# 而对于 bsdi 来讲，对外访问的默认网关13.33
docker exec -it bsdi ip route add default via 140.252.13.33 dev eth1

# 对于 sun 来讲，要想访问p2p网络，需要添加下面的路由表
docker exec -it sun ip route add 140.252.13.64/27 via 140.252.13.35 dev eth1

# 对于 svr4 来讲，对外访问的默认网关是13.33
docker exec -it svr4 ip route add default via 140.252.13.33 dev eth1

# 对于svr4来讲，要访问p2p网关，需要添加下面的路由表
docker exec -it svr4 ip route add 140.252.13.64/27 via 140.252.13.35 dev eth1

# 这个时候，从slip是可以ping的通下面的所有的节点的。
docker exec -it slip ping -c 4 140.252.13.66
docker exec -it slip ping -c 4 140.252.13.35
docker exec -it slip ping -c 4 140.252.13.33
docker exec -it slip ping -c 4 140.252.13.34

### =====================================================
# 添加从sun到netb的点对点网络
echo "add p2p from sun to netb"
# 创建一个peer的网卡对
sudo ip link add name sunside mtu 1500 type veth peer name netbside mtu 1500

# 一面塞到sun的网络namespace里面
DOCKERPID3=$(docker inspect '--format={{ .State.Pid }}' sun)
sudo ln -s /proc/${DOCKERPID3}/ns/net /var/run/netns/${DOCKERPID3}
sudo ip link set sunside netns ${DOCKERPID3}

# 另一面塞到netb的网络的namespace里面
DOCKERPID4=$(docker inspect '--format={{ .State.Pid }}' netb)
sudo ln -s /proc/${DOCKERPID4}/ns/net /var/run/netns/${DOCKERPID4}
sudo ip link set netbside netns ${DOCKERPID4}


# 给 sun 里面的网卡添加地址
docker exec -it sun ip addr add 140.252.1.29/24 dev sunside
docker exec -it sun ip link set sunside up
docker exec -it sun ip addr

# 在sun里面，对外访问的默认路由是1.4
docker exec -it sun ip route add default via 140.252.1.4 dev sunside

# 在netb里面，对外访问的默认路由是1.4
docker exec -it netb ip route add default via 140.252.1.4 dev eth1

# 在netb里面，p2p这面可以没有IP地址，但是需要配置路由规则，访问到下面的二层网络
docker exec -it netb ip link set netbside up
docker exec -it netb ip route add 140.252.1.29/32 dev netbside
docker exec -it netb ip route add 140.252.13.32/27 via 140.252.1.29 dev netbside
docker exec -it netb ip route add 140.252.13.64/27 via 140.252.1.29 dev netbside

### ==============================================================
# 对于netb，配置arp proxy
# 对于netb来讲，不是一个普通的路由器，因为netb两边是同一个二层网络，所以需要配置arp proxy，将同一个二层网络隔离称为两个。

# 配置proxy_arp为1

docker exec -it netb bash -c "echo 1 > /proc/sys/net/ipv4/conf/eth1/proxy_arp"
docker exec -it netb bash -c "echo 1 > /proc/sys/net/ipv4/conf/netbside/proxy_arp"

# 通过一个脚本proxy-arp脚本设置arp响应
#设置proxy-arp.conf
#eth1 140.252.1.29
#netbside 140.252.1.92
#netbside 140.252.1.32
#netbside 140.252.1.11
#netbside 140.252.1.4

#将配置文件添加到docker里面
docker cp proxy-arp.conf netb:/etc/proxy-arp.conf
docker cp proxy-arp netb:/root/proxy-arp

#在docker里面执行脚本proxy-arp
docker exec -it netb chmod +x /root/proxy-arp
docker exec -it netb /root/proxy-arp start


### ==================================================================
# 配置上面的二层网络里面所有机器的路由

# 在 aix 里面，默认外网访问路由是1.4
docker exec -it aix ip route add default via 140.252.1.4 dev eth1

# 在 aix 里面，可以通过下面的路由访问下面的二层网络
docker exec -it aix ip route add 140.252.13.32/27 via 140.252.1.29 dev eth1
docker exec -it aix ip route add 140.252.13.64/27 via 140.252.1.29 dev eth1

# 同理配置solaris
docker exec -it solaris ip route add default via 140.252.1.4 dev eth1
docker exec -it solaris ip route add 140.252.13.32/27 via 140.252.1.29 dev eth1
docker exec -it solaris ip route add 140.252.13.64/27 via 140.252.1.29 dev eth1


# 同理配置 gemini
docker exec -it gemini ip route add default via 140.252.1.4 dev eth1
docker exec -it gemini ip route add 140.252.13.32/27 via 140.252.1.29 dev eth1
docker exec -it gemini ip route add 140.252.13.64/27 via 140.252.1.29 dev eth1

#通过配置路由可以连接到下面的二层网络
docker exec -it gateway ip route add 140.252.13.32/27 via 140.252.1.29 dev eth1
docker exec -it gateway ip route add 140.252.13.64/27 via 140.252.1.29 dev eth1

# 到此为止，上下的二层网络都能相互访问了

### ======================================================================
# 配置外网访问
# 创建一个peer的网卡对
sudo ip link add name gatewayin mtu 1500 type veth peer name gatewayout mtu 1500

sudo ip addr add 140.252.104.1/24 dev gatewayout
sudo ip link set gatewayout up

#一面塞到gateway的网络的namespace里面
DOCKERPID5=$(docker inspect '--format={{ .State.Pid }}' gateway)
sudo ln -s /proc/${DOCKERPID5}/ns/net /var/run/netns/${DOCKERPID5}
sudo ip link set gatewayin netns ${DOCKERPID5}

# 给gateway里面的网卡添加地址
docker exec -it gateway ip addr add 140.252.104.2/24 dev gatewayin
docker exec -it gateway ip link set gatewayin up

# 在gateway里面，对外访问的默认路由是140.252.104.1/24
docker exec -it gateway ip route add default via 140.252.104.1 dev gatewayin

publiceth=ens3
sudo iptables -t nat -A POSTROUTING -o ${publiceth} -j MASQUERADE
sudo ip route add 140.252.13.32/27 via 140.252.104.2 dev gatewayout
sudo ip route add 140.252.13.64/27 via 140.252.104.2 dev gatewayout
sudo ip route add 140.252.1.0/24 via 140.252.104.2 dev gatewayout
```
