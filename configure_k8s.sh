#!/bin/sh

export PATH=$PATH:/usr/sbin:/sbin
kubeadm reset --force
rm -rf /var/lib/etcd/*
setenforce 0

firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10250,30000-32767}/tcp
firewall-cmd --reload


cat <<EOF > /tmp/kubernetes.config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kubernetesVersion: v1.15.0
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    "feture-gates": "VolumeSnapshotDataSource=true KubeletPluginsWatcher=true CSINodeInfo=true CSIDriverRegistry=true BlockVolume=true CSIBlockVolume=true"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.15.0
networking:
  podSubnet: "10.244.0.0/16"
EOF

# run kubeadm init as root
echo Running kubeadm init --pod-network-cidr=10.244.0.0/16 
#--config=/tmp/kubernetes.config.yaml
#--skip-preflight-checks --apiserver-advertise-address=$HOST_DNS_IP --apiserver-cert-extra-sans=$HOST_FQNAME,$HOST_DNS_IP

iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
echo " see /tmp/kubeadm-init.out for output"
kubeadm init --pod-network-cidr=10.244.0.0/16 
#--config=/tmp/kubernetes.config.yaml

#--skip-preflight-checks --apiserver-advertise-address=$HOST_DNS_IP --apiserver-cert-extra-sans=$HOST_FQNAME,$HOST_DNS_IP > /tmp/kubeadm-init.out 2>&1
if [ $? -ne 0 ] ; then
  echo "ERROR: kubeadm init returned non 0"
  chmod a+r  /tmp/kubeadm-init.out
  exit 1
else
  echo; echo "kubeadm init complete" ; echo
  # tail the log to get the "join" token
  tail -6 /tmp/kubeadm-init.out 
fi 

cp /etc/kubernetes/admin.conf  $k8s_dir
cp /tmp/kubeadm-init.out $k8s_dir
# chown $real_user:$real_group $KUBECONFIG
# chmod 644 $KUBECONFIG
chmod -R 755 $k8s_dir
echo Created KUBECONFIG at $k8s_dir/admin.conf
chmod -R 755 $k8s_dir

export KUBECONFIG=$k8s_dir/admin.conf
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl create -f https://k8s.io/examples/admin/dns/busybox.yaml
kubectl get nodes
kubectl get pods

echo
echo
echo "Kubernetes is now configured."
echo "DONE."