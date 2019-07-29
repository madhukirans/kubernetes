#!/bin/sh
#
# run with "sudo sh ./this_script.sh"

source ./common.sh

# check that docker is installed, and the version is what we expect
docker version > /tmp/version.out
ver=`grep Version: /tmp/version.out | head -1 | awk '{print $2}'`
if [ "$ver" != "$docker_version" ] ; then
  echo "Docker version not correct, or not installed properly"
  echo "expected $docker_version got $ver in output" 
  cat /tmp/version.out
  exit 1
fi

yum erase -y kubelet kubeadm kubectl
rm -rf /etc/kubernetes/*

### install kubernetes packages
# generate the yum repo config
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


setenforce 0
cat << EOF > /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

modprobe br_netfilter
sysctl --system
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

setenforce 0

firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252,10250,30000-32767}/tcp
firewall-cmd --reload

# install kube* packages
yum makecache fast
yum install -y kubelet-1.15.0-0.x86_64 kubeadm-1.15.0-0.x86_64 kubectl-1.15.0-0.x86_64
#kubernetes-cni-0.5.1-0.x86_64
kubeadm config images pull

# change the cgroup-driver to match what docker is using
cgroup=`docker info 2>&1 | egrep Cgroup | awk '{print $NF}'`
[ "$cgroup" == "" ] && echo "cgroup not detected!" && exit 1

#cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf | sed "s#KUBELET_KUBECONFIG_ARGS=.*#KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --allow-privileged=true\"#"> /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf.out
#cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf.out | sed "s#\$KUBELET_NETWORK_ARGS##"> /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf.out1
#diff  /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf  /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf.out1
#mv  /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf.out  /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

# enable and start service
systemctl enable kubelet && systemctl start kubelet

echo "Next Set of instructions are ONLY for K8S Master host".
export PATH=$PATH:/usr/sbin:/sbin

# if [ "$install_mode" = "worker" ]; then
  # echo "Please run kubeadm join --token <tokenName> <MasterIP>:<MasterPort>"
  # echo "For e.g. kubeadm join --token fda095.911fc5811f6711f6 10.232.144.18:6443"
  # echo "If you used the same script to install master, The above info can be found at $k8s_dir/kubeadm-init.out on the master host"
  # exit 1
# else
  # echo "This is a master install. Continuing to run kubeadm init .."
# fi



