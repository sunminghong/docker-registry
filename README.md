###［干货］
这是我最后将registry 私有仓库配置成功后总结的一键安装脚本，基本上修改下开头的几个参数就可以了，毕竟不是所有人都要做docker运维的，希望对有缘人有些帮助。
系统环境：
centos 7.0
docker 1.9

1、首先修改 /etc/pki/tls/openssl.cnf 配置，在该文件中找到 [ v3_ca ]
，在它下面添加如下内容：
```bash
...
[ v3_ca ]
# Extensions for a typical CA
subjectAltName = IP:192.168.1.211
```
再次重启 docker，解决 "x509: cannot validate certificate for 192.168.1.211 because it doesn't contain any IP SANs" bugs。

2、安装docker private registry 私有仓库

```bash
#!/bin/bash
#install.sh
#docker 仓库服务器ip
hostname=x.x.x.x

#docker pull/push 时用的user和password；pull／push 前先docker login hostname:5000
user=test
password=test

#docker仓库的certs配置文件存放位置
#rootdir=$(pwd)
rootdir=/data/registry

#docker仓库数据库存放位置
#set the registry data folder/directory
registrydir=$rootdir/registry

cd $rootdir

echo $hostname
echo $rootdir
echo $registrydir

mkdir $registrydir


#docker registry:2 需要用ssl方式，我们小企业没有申请商用ca证书，采用自己生成ca证书的方式。certification files (*.key, *.crt)
mkdir -p certs && openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key\
  -x509 -days 365 -out certs/domain.crt


mkdir -p /etc/docker/certs.d/$hostname:5000/

#将证书公钥放到docker的证书文件夹
cp certs/domain.crt /etc/docker/certs.d/$hostname:5000/ca.crt

#生成登录验证用户
mkdir auth
docker run --entrypoint htpasswd registry:2 -Bbn $user $password > auth/htpasswd

#现删除掉已经运行registry（如果没有无所谓）
docker rm -f registry

#启动一个docker registry 容器，提供私有仓库服务，over
docker run -d -p 5000:5000 --restart=always --name registry \
  -v $rootdir/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v $rootdir/certs:/certs \
  -v $registrydir:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2

```

3、客户端初次使用

```bash
#!/bin/bash

hostname=x.x.x.x
user=test
password=test

rootdir=/data/registry

echo $hostname
echo $rootdir

mkdir -p /etc/docker/certs.d/$hostname:5000/
#导入服务器端的证书
scp root@$hostname:/$rootdir/certs/domain.crt /etc/docker/certs.d/$hostname:5000/ca.crt

```

4、docker pull/docker push
```bash
docker login $hostname:5000
#enter user and password


docker tag 5e3f  hostname:5000/allen/mongo-replication:3.2  
docker push hostname:5000/allen/mongo-replication:3.2

...
docker pull hostname:5000/allen/mongo-replication:3.2

```

###缘起
拥抱大数据，首先得有能支撑的大数据的基础软件工具，如分布式数据库、hadoop、scala、spark等等一系列的软件、框架，而在这之前首先要选择这些基础架构软件的部署方式，既然我现在是“从零学习大数据技术”，当然要必须考虑到一些实际工作因素，最终我选择了docker 容器部署技术，主要原因有三：
1. 大数据生态圈的软件非常庞杂，软件依赖、版本交叉等就会很复杂，docker提供了高效的容器隔离；我们开发就要用到golang、python、ruby、js、php、java等等多种语言环境和相关的支持库，各个环境、版本的管理、分发将会越来越复杂，docker容器从根源上避免了这些问题，每个服务/功能都自己部署一个容器，互不干扰，一切都安静了。
1. 从零学习，自然就会测试很多的软件工具，安装、配置、删除等相当平凡，如何最少影响当前的系统环境？当然是容器技术嘛！
3. 开发阶段我们都是在一组零时的较低成本的机器上进行配置、学习、开发，一旦可投入生产环境了就必须进行在生产服务器上进行部署。如果用传统的一个一个软件的方式安装，那个痛苦不敢想象！软件迁移部署是docker的最重要的应用场景。
。。。

当我们决心拥抱docker技术的时候，痛苦也即将开始——等！由于我们的主要业务在国内，那么我们的服务器就在墙内，所以docker pull将是一个“等”体验。我们通常都是在每台机器上输入一条docker pull命令后就去干别的。每当此时我就感谢华罗庚教授的“统筹方法”（不懂？小学语文课是怎么学的？）。更痛苦的是多台机器都要做同样的操作？如何避免？google上有很多文档，有介绍用aliyun mirrors服务的，有介绍daocloud加速器的，但是当我一一试过之后才发现然并卵——我们现在用的ucloud服务器，反正我都没有搞成功！

当时我有些骑虎难下了，你造吗？碰了一次又一次南墙。但我没有半途而废，于是我就想到了自己写Dockerfile，然后自己架设 一个局域网内的私有docker镜像仓库。于是又开始google，又试了多个文档，白天碰完南墙，晚上接着碰，终于搞定。在最后，我总结成了一个bash脚本提交到了github上，备忘、也希望可以给有缘人以帮助，毕竟我们是要用docker来提升工作效率，而不是做docker运维。


