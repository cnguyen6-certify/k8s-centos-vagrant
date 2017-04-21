#!/bin/bash

setenforce 0
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

export IP=192.168.33.10
kubeadm init --apiserver-advertise-address $IP --pod-network-cidr 10.244.0.0/16
cp /etc/kubernetes/admin.conf /vagrant

# This configures kubectl for all future commands within the script
export KUBECONFIG="/etc/kubernetes/admin.conf"

# Weavenet is a great way to network containers.
# It can survive a few kinds of network partitions.
kubectl apply  -f https://git.io/weave-kube

# Weavescope is a live documentation of connections between containers or services
# It helps describe how a federation of microservices works
kubectl apply  -f https://cloud.weave.works/launch/k8s/weavescope.yaml

# Kubernetes Dashboard is a good way to describe individual elements in a system
kubectl create -f https://rawgit.com/kubernetes/dashboard/master/src/deploy/kubernetes-dashboard.yaml

# Heapster improves Dashboard by adding some metrics reporting
export INFLUXDB=https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb
kubectl create -f $INFLUXDB/grafana-deployment.yaml
kubectl create -f $INFLUXDB/grafana-service.yaml
kubectl create -f $INFLUXDB/heapster-deployment.yaml
kubectl create -f $INFLUXDB/heapster-service.yaml
kubectl create -f $INFLUXDB/influxdb-deployment.yaml
kubectl create -f $INFLUXDB/influxdb-service.yaml
