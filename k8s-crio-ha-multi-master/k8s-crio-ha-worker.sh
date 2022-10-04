#!/bin/bash

 ## -- Update Load-balancer, Master-1 Node IP & token details in Shell variable before executing the script -- ##
 export master_ip=10.49.122.155          ## load-balancer(haproxy) IP
 export master_1_ip=10.49.122.55
 export master_token=1234xxxx
 export master_token_hash=sha256:1234xxxx

 ## docker-crio :: worker-x ##
 subscription-manager repos --disable fast-datapath-for-rhel-8-x86_64-rpms  
 subscription-manager repos --enable fast-datapath-for-rhel-8-x86_64-rpms
 systemctl stop firewalld
 systemctl disable firewalld
 sudo sed -i '/ swap / s/^/#/' /etc/fstab
 sudo swapoff -a
 sudo setenforce 0
 sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 sed -i '/subscription-manager/d' /root/k8s-crio-ha-worker.sh
 sudo sed -i 's/reboot now#/#reboot now/g' /root/k8s-crio-ha-worker.sh
 #reboot now#

hostname=$(hostname)
eth0ip=$(hostname -I | awk '{print $1}')
sed -i 's/rhel84/ /g' /etc/hosts
sed -i 's/localhost6 localhost6.localdomain6/localhost6 localhost6.localdomain6\n\n'"$eth0ip"' '"$hostname"'/g' /etc/hosts

 sudo dnf install -y yum-utils device-mapper-persistent-data lvm2 iproute-tc net-tools wget sshpass git bash-completion &
 sleep 90

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

export VERSION=1.24
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
sudo dnf install -y cri-o &
sleep 120
sudo systemctl enable crio && sudo systemctl start cri-o

sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo setenforce 0
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes &
sleep 120

#echo 'KUBELET_EXTRA_ARGS="--container-runtime=remote --container-runtime-endpoint=unix:///run/crio/crio.sock"' > /etc/sysconfig/kubelet
sudo systemctl enable kubelet && systemctl restart kubelet
echo '\ =====  Hello World :)  ===== \'

kubeadm join $master_ip:6443 --token $master_token --discovery-token-ca-cert-hash $master_token_hash --cri-socket=unix:///run/crio/crio.sock
echo "kubeadm join $master_ip:6443 --token $master_token --discovery-token-ca-cert-hash $master_token_hash --cri-socket=unix:///run/crio/crio.sock"

 sleep 40
 sshpass -p 'contrail123' scp -o stricthostkeychecking=no -r root@$master_1_ip:/root/.kube $HOME/
 kubectl label node $hostname node-role.kubernetes.io/worker=
 curl -sS https://webinstall.dev/k9s | bash
 export PATH="/root/.local/bin:$PATH"
 kubectl get node -A -o wide
 kubectl get node --show-labels
 sleep 30
 kubectl get pods -A -o wide

echo "source <(kubectl completion bash)" >> ~/.bashrc
echo 'alias ku=kubectl' >> ~/.bashrc
echo 'alias k=k9s' >> ~/.bashrc

echo '\ =====  K8s Cluter Join(Worker) installation Complete :)  ===== \'


