#!/bin/bash
# Make the prompt tell you the user, returncode, and path
# This helps avoid running commands in the wrong places.
cp /vagrant/prompt.sh /etc/profile.d/

# Kubernetes has it's own repo powered by google's cloud
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
sslverify=0
EOF

# SELinux is nice, but it doesn't work well with containers
setenforce 0

# These are all the tools we'll be needing to run Kubernetes
yum install -y docker kubelet kubeadm kubectl kubernetes-cni net-tools

# Firewall should be killed and docker and kubelet should be servicified.
systemctl enable  docker            && systemctl start docker
systemctl enable  kubelet           && systemctl start kubelet
systemctl disable firewalld.service && systemctl stop  firewalld.service

# If we have DNS names, we don't have to worry about these.
# Otherwise we should make sure name resolution works.
echo "#Begin
192.168.33.10  centos-master
192.168.33.11  centos-worker1
192.168.33.12  centos-worker2
#End" >> /etc/hosts

# NETWORK args should be removed from the default
# Also CGROUPS should be configured to systemd as that's where docker runs
cat <<EOF > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--kubeconfig=/etc/kubernetes/kubelet.conf --require-kubeconfig=true"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd"
ExecStart=
#ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_SYSTEM_PODS_ARGS \$KUBELET_NETWORK_ARGS \$KUBELET_DNS_ARGS \$KUBELET_AUTHZ_ARGS \$KUBELET_CGROUP_ARGS \$KUBELET_EXTRA_ARGS
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_SYSTEM_PODS_ARGS \$KUBELET_DNS_ARGS \$KUBELET_AUTHZ_ARGS \$KUBELET_CGROUP_ARGS \$KUBELET_EXTRA_ARGS
EOF

chmod aug-x /etc/systemd/system/kubelet.service
chmod aug-x /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

for CERTFILE in $(ls -1 /vagrant/*.pem)
do
  echo "" >> /etc/pki/tls/certs/ca-bundle.crt
  cat $CERTFILE >> /etc/pki/tls/certs/ca-bundle.crt
done
