#!/bin/bash
set -e
#
# run with "sudo sh ./this_script.sh"
source common.sh

export PATH=$PATH:/usr/sbin:/sbin
kubeadm reset --force
rm -rf /var/lib/etcd/*
setenforce 0

firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10250,30000-32767}/tcp
firewall-cmd --reload
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

#Enabling feature gates
#if [ ! -f /bin/yq ] ; then
#    wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64
#    mv -f yq_linux_amd64 /bin/yq
#    chmod 777 /bin/yq
#fi

# run kubeadm init as root
echo Running kubeadm init --config kubeadm-config.yaml
#kubeadm init --pod-network-cidr=10.244.0.0/16
kubeadm init --config kubeadm-config.yaml

cat << EOF >> /var/lib/kubelet/config.yaml
VolumeSnapshotDataSource: true
KubeletPluginsWatcher: true
CSINodeInfo: true
CSIDriverRegistry: true
BlockVolume: true
CSIBlockVolume: true
ExpandCSIVolumes: true
ExpandPersistentVolumes: true
ExpandInUsePersistentVolumes: true
EOF

echo Created KUBECONFIG at /etc/kubernetes/admin.conf

sleep 20

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl create clusterrolebinding my-cluster-admin-binding --clusterrole=cluster-admin
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl create -f https://k8s.io/examples/admin/dns/busybox.yaml
kubectl get nodes
kubectl get pods

curl -L https://git.io/get_helm.sh | bash

echo "Sometimes reboot is necessary for helm deployment :( "
helm init --force-upgrade
helm init -i https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts

echo "On node execute the follwoing commands"
echo "ip link delete cni0"
echo "ip link delete flannel.1"

echo
echo
echo "Kubernetes is now configured."
echo "DONE."