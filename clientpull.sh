#!/bin/bash

#eg.
hostname=x.x.x.x

docker login $hostname:5000
#enter user and password


imgname=$hostname:5000/allen/mongo-replication:3.2


docker pull $imgname

