#!/usr/bin/env bash

set -e

warning=`cat << EOF
 WARNING:  this script is intended for a clean re-imaged machine
 if you have been using docker and/or k8s already on your machine
 then you should back up your Docker and K8s configs and run clean_docker_k8s.sh
EOF
`
echo 
echo $warning |sed "s#RTN#\\n#g"| fold -s -80
echo 
read -p "Continue (y/n)?" CONT
if [ "$CONT" = "y" ]; then
  echo "Continuing...";
else
  echo "Aborting...";
  exit 1
fi

set -e
set -- "" "${@:2}"
if [ "$1" = "" ] ; then
  export real_user=`who am i | awk '{print $1}'`
else
  export real_user=$1
fi
echo Regular user = ${real_user:?}
export real_group=`groups $real_user | awk '{print $3}'`
echo Regular user group = ${real_group:?}
export real_user_home=`eval echo "~$real_user"`
echo Regular user home = ${real_user_home:?}
set +e

# generate a shell script to append to users .bashrc 
# so that proxy variables, etc are set on login
ip_addr=$(host `hostname` | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')



os=""
rhel_out=`egrep "Red Hat Enterprise Linux Server release 7.(5|6|7|8)" /etc/redhat-release`
centos_out=`egrep "CentOS Linux release 7.(5|6|7|8)" /etc/redhat-release`

if [ "$rhel_out" != "" ] ; then
   os=redhat
fi

if [ "$centos_out" != "" ] ; then
   os=centos
fi

echo Operating system $os : `cat /etc/redhat-release`