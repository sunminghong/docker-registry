#!/bin/bash

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



