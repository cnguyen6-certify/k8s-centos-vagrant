#!/bin/bash

# Optionally build an image called el7kube. You need to run this only once.
if [ "$1" = "-b" ]; then
  cd baseimage
  vagrant up; vagrant package default; vagrant box add --force --name el7kube package.box
  rm -rf package.box
  vagrant destroy -f
  cd ..
fi

# This will tear down and spin up instances
cd demo
vagrant destroy -f; vagrant up

# This will extract the join token from the controller so that it can be used on the workers.
# This is so that the workers no how to connect to the controller.
export JOIN_TOKEN=$(vagrant ssh centos-master -c 'sudo kubeadm  token list | grep "init" | cut -d " " -f 1| xargs echo -n')

# This will use the token we extracted earlier, and join the workers to the controller
for HOST in $(vagrant ssh-config | grep "^Host" | sed -e "s/^Host //g" | grep -v "centos-master")
do
  vagrant ssh -c "sudo kubeadm join --token=$(echo -n $JOIN_TOKEN) 192.168.33.10:6443" $HOST
done

# This will make it known to the user what needs to be done to use the cluster from kubectl
cat <<EOF
source this line in any shell where you want to control this cluster

    export KUBECONFIG="$(pwd)/admin.conf"
EOF

# Use the cluster for the remainder of the script. There are a few more things to be done.
export KUBECONFIG="$(pwd)/admin.conf"

# Switch the kube-proxy pod to use userspace networking.
# This makes sure all the proxies work correctly.
kubectl -n kube-system get ds -l 'k8s-app=kube-proxy' -o json \
    | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
    | kubectl apply -f - && kubectl -n kube-system delete pods -l 'k8s-app=kube-proxy'

# Enable nginx ingress controller
kubectl apply -f https://rawgit.com/kubernetes/ingress/master/examples/deployment/nginx/kubeadm/nginx-ingress-controller.yaml

cd ..

# kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

kubectl apply -f kube-dashboard-rbac.yaml
