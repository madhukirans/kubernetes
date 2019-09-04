#!/bin/bash
set -e
#
# run with "sudo sh ./this_script.sh"


source common.sh

#yum update -y
yum install -y device-mapper-persistent-data lvm2 yum-utils dos2unix unzip ed net-tools bind-utils

yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

yum makecache fast

useradd docker
usermod -aG sudo docker

cat > /tmp/dockerk8senv  <<EOF
export PATH=\$PATH:/sbin:/usr/sbin
pod_network_cidr="10.244.0.0/16"
## grab my IP address to pass into  kubeadm init, and to add to no_proxy vars
# assume ipv4 and eth0
export HOST_DNS_IP=$(host `hostname` | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
export HOST_FQNAME=$(hostname -f)
EOF

# source the script we just generated
. /tmp/dockerk8senv


# we are going to just uninstall any docker-engine that is installed
yum remove -y docker docker-ce docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine docker-engine-selinux


#if [ "$os" = "centos" ] ; then
    docker_version="18.09.6"
    # now install the docker-ce at our specified version
    yum install -y docker-ce-cli-$docker_version docker-ce-$docker_version
#elif [ "$os" = "redhat" ] ; then
#    yum install -y docker
#else
#    echo "Invalid OS version. OS should be RedHat 7.5 or more (or) centos 7.5 or more"
#    exit -1
#fi
usermod -aG docker seelam

cat /usr/lib/systemd/system/docker.service | sed "s#^Type=notify#Type=notify\nMountFlags=shared#g" > /tmp/docker.out
diff /usr/lib/systemd/system/docker.service /tmp/docker.out
mv -f /tmp/docker.out /usr/lib/systemd/system/docker.service


# enable and start docker service we just installed and configured
systemctl daemon-reload
systemctl enable docker && systemctl start docker

echo
echo
echo "Docker is now configured."
echo "DONE."

