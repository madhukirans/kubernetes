# 
# based off of install/configure instructions at
# main qa wiki
# http://aseng-wiki.us.oracle.com/asengwiki/display/ASQA/Installing+Kubernetes+on+Linux+with+kubeadm
#

if [ -z "$1" ]; then
  echo "No argument supplied, Please pass master or worker i.e. install_docker_k8s.sh master|worker"
  exit 1
fi


if [ "$1" = "master" ] || [ "$1" = "worker" ]; then
  echo "Doing install for K8S $1"
  install_mode="$1"
else
  echo "Only  master or worker are vaild arguments i.e. install_docker_k8s.sh master|worker"
  exit 1
fi

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
# customize these dirs as needed
docker_dir=/scratch/docker
k8s_dir=/scratch/k8s_dir

rm -rf $docker_dir $k8s_dir
mkdir -p $docker_dir $k8s_dir

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
