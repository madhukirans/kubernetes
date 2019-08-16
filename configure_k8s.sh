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
#iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

#Enabling feature gates
if [ ! -f /bin/yq ] ; then
    wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64
    mv -f yq_linux_amd64 /bin/yq
    chmod 777 /bin/yq
fi

#cat << EOF > /tmp/config.yaml
#VolumeSnapshotDataSource: true
#KubeletPluginsWatcher: true
#CSINodeInfo: true
#CSIDriverRegistry: true
#BlockVolume: true
#CSIBlockVolume: true
#EOF
#
#cat << EOF > /tmp/kube-apiserver.yaml
#spec:
#  containers:
#  - command:
#    - kube-apiserver
#    - --feature-gates=VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true,BlockVolume=true,CSIBlockVolume=true
#EOF
#
#cat << EOF > /tmp/kube-controller-manager.yaml
#spec:
#  containers:
#  - command:
#    - kube-controller-manager
#    - --feature-gates=VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true,BlockVolume=true,CSIBlockVolume=true
#EOF
#
#cat << EOF > /tmp/kube-scheduler.yaml
#spec:
#  containers:
#  - command:
#    - kube-scheduler
#    - --feature-gates=VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true,BlockVolume=true,CSIBlockVolume=true
#EOF

# run kubeadm init as root
echo Running kubeadm init --pod-network-cidr=10.244.0.0/16
echo " see /tmp/kubeadm-init.out for output"
kubeadm init --pod-network-cidr=10.244.0.0/16 


cp -f /var/lib/kubelet/config.yaml  /var/lib/kubelet/config1.yaml
cp -f /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver1.yaml
cp -f /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-controller-manager1.yaml
cp -f /etc/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/manifests/kube-scheduler1.yaml

cat << EOF >> /var/lib/kubelet/config.yaml
VolumeSnapshotDataSource: true
KubeletPluginsWatcher: true
CSINodeInfo: true
CSIDriverRegistry: true
BlockVolume: true
CSIBlockVolume: true
EOF

cat /etc/kubernetes/manifests/kube-apiserver1.yaml | sed "s#- kube-apiserver#- kube-apiserver\n    - --feature-gates=VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true,BlockVolume=true,CSIBlockVolume=true#" > /etc/kubernetes/manifests/kube-apiserver.yaml
cat /etc/kubernetes/manifests/kube-controller-manager1.yaml | sed "s#- kube-controller-manager#- kube-controller-manager\n    - --feature-gates=VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true,BlockVolume=true,CSIBlockVolume=true#"> /etc/kubernetes/manifests/kube-controller-manager.yaml
cat /etc/kubernetes/manifests/kube-scheduler1.yaml | sed "s#- kube-scheduler#- kube-scheduler\n    - --feature-gates=VolumeSnapshotDataSource=true,KubeletPluginsWatcher=true,CSINodeInfo=true,CSIDriverRegistry=true,BlockVolume=true,CSIBlockVolume=true#"> /etc/kubernetes/manifests/kube-scheduler.yaml

systemctl daemon-reload
systemctl restart kubelet

if [ $? -ne 0 ] ; then
  echo "ERROR: kubeadm init returned non 0"
  chmod a+r  /tmp/kubeadm-init.out
  exit 1
else
  echo; echo "kubeadm init complete" ; echo
  # tail the log to get the "join" token
  tail -6 /tmp/kubeadm-init.out 
fi 

cp /etc/kubernetes/admin.conf /home/seelam/kubeconfig
cp /tmp/kubeadm-init.out /home/seelam/
# chown $real_user:$real_group $KUBECONFIG
# chmod 644 $KUBECONFIG
chown seelam:seelam -R /home/seelam

echo Created KUBECONFIG at /home/seelam/kubeconfig

echo "VolumeSnapshotDataSource: true" >> /var/lib/kubelet/config.yaml
echo "KubeletPluginsWatcher: true" >> /var/lib/kubelet/config.yaml
echo "CSINodeInfo: true" >> /var/lib/kubelet/config.yaml
echo "CSIDriverRegistry: true" >> /var/lib/kubelet/config.yaml
echo "BlockVolume: true" >> /var/lib/kubelet/config.yaml
echo "CSIBlockVolume: true" >> /var/lib/kubelet/config.yaml

export KUBECONFIG=/home/seelam/kubeconfig
kubectl create clusterrolebinding my-cluster-admin-binding1 --clusterrole=cluster-admin
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl create -f https://k8s.io/examples/admin/dns/busybox.yaml
kubectl get nodes
kubectl get pods

echo
echo
echo "Kubernetes is now configured."
echo "DONE."