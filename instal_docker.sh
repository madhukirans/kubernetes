#!/bin/sh
#
# run with "sudo sh ./this_script.sh"


source common.sh


yum install -y device-mapper-persistent-data lvm2 yum-utils

yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

yum makecache fast

cat > /tmp/dockerk8senv  <<EOF
export PATH=\$PATH:/sbin:/usr/sbin
pod_network_cidr="10.244.0.0/16"

k8s_dir=$k8s_dir

## grab my IP address to pass into  kubeadm init, and to add to no_proxy vars
# assume ipv4 and eth0

export HOST_DNS_IP=$(host `hostname` | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
export HOST_FQNAME=$(hostname -f)
export KUBECONFIG=\$k8s_dir/admin.conf
EOF

# source the script we just generated
. /tmp/dockerk8senv


# update the script to add command completion
cat >> /tmp/dockerk8senv <<EOF
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
EOF

cp /tmp/dockerk8senv $k8s_dir


# we are going to just uninstall any docker-engine that is installed
yum -y erase yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine docker-engine-selinux 
# now install the docker-ce at our specified version
yum -y  install docker-ce-$docker_version

# edit /etc/sysconfig/docker to add custom OPTIONS
#cat /etc/sysconfig/docker | sed "s#^OPTIONS=.*#OPTIONS='--selinux-enabled --group=docker -g $docker_dir'#g" > /tmp/docker.out
#diff /etc/sysconfig/docker /tmp/docker.out
#mv /tmp/docker.out /etc/sysconfig/docker

cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Add the regular user to the 'docker' group
usermod -aG docker $real_user

# enable and start docker service we just installed and configured
systemctl enable docker && systemctl start docker


echo
echo
echo "Docker is now configured."
echo "DONE."

