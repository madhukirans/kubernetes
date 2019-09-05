# install docker and kubernetes

The following script works in rhel 7, centos 7 and oel7.
Make sure yum install work as expected before starting the install.
You may have to register using subscription-manager incase of RHEL.

### Execute the following scripts using `root` user
### To install Docker.ce 1.18
```bash install-docekr.sh```

### To install Kubernetes 1.14
```bash install_k8s.sh```

### To configure k8s
```bash configure_k8s.sh```

Note: 
* configure_k8s.sh reset k8s and confugures using kubeadm
* This script having hardcoded values like 'seelam' '/home/seelam'. You need to replace before executing.    
