#!/bin/bash

hostname=x.x.x.x
user=test
password=test

rootdir=/data/registry

echo $hostname
echo $rootdir

mkdir -p /etc/docker/certs.d/$hostname:5000/

scp root@$hostname:/$rootdir/certs/domain.crt /etc/docker/certs.d/$hostname:5000/ca.crt


