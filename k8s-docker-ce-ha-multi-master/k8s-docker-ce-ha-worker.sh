#!/bin/bash

 ## -- Update Load-balancer, Master-1 Node IP & token details in Shell variable before executing the script -- ##
 export master_ip=10.49.122.155          ## load-balancer(haproxy) IP
 export master_1_ip=10.49.122.55
 export master_token=1234xxxx
 export master_token_hash=sha256:1234xxxx

 ## docker-ce :: worker-x ##
 subscription-manager repos --disable fast-datapath-for-rhel-8-x86_64-rpms  
 subscription-manager repos --enable fast-datapath-for-rhel-8-x86_64-rpms
 systemctl stop firewalld
 systemctl disable firewalld
 sudo sed -i '/ swap / s/^/#/' /etc/fstab
 sudo swapoff -a
 sudo setenforce 0
 sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 sed -i '/subscription-manager/d' /root/k8s-docker-ce-worker.sh
 sudo sed -i 's/reboot now#/#reboot now/g' /root/k8s-docker-ce-worker.sh
 #reboot now#

hostname=$(hostname)
eth0ip=$(hostname -I | awk '{print $1}')
sed -i 's/rhel84/ /g' /etc/hosts
sed -i 's/localhost6 localhost6.localdomain6/localhost6 localhost6.localdomain6\n\n'"$eth0ip"' '"$hostname"'/g' /etc/hosts

 dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
 dnf install docker-ce --nobest -y &
 sleep 120
 yum install -y containerd.io docker-ce-cli docker-compose-plugin yum-utils device-mapper-persistent-data lvm2 iproute-tc net-tools wget sshpass git bash-completion &
 sleep 120
 sudo systemctl start docker && sudo systemctl enable docker
 
VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest|grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo $VER
wget https://github.com/Mirantis/cri-dockerd/releases/download/v${VER}/cri-dockerd-${VER}.amd64.tgz
tar xvf cri-dockerd-${VER}.amd64.tgz
sudo mv cri-dockerd/cri-dockerd /usr/local/bin/
echo ' \ ==== cri-dockerd version :: ==== \ '
cri-dockerd --version
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
# systemctl status cri-docker.socket
# systemctl status docker

cat > /etc/sysctl.d/kubernetes.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

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
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes &
# dnf install -y kubelet-1.24.6-0 kubeadm-1.24.6-0 kubectl-1.24.6-0 cri-tools-1.24.2-0 --disableexcludes=kubernetes &
sleep 120
sudo systemctl enable kubelet && systemctl start kubelet
echo '\ =====  Hello World :)  ===== \ '

echo "kubeadm join $master_ip:6443 --token $master_token --discovery-token-ca-cert-hash $master_token_hash --cri-socket=unix:///run/cri-dockerd.sock"
kubeadm join $master_ip:6443 --token $master_token --discovery-token-ca-cert-hash $master_token_hash --cri-socket=unix:///run/cri-dockerd.sock
## --kubernetes-version 1.24.6

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

echo '\ =====  K8s Cluter Join (Worker) installation Complete :)  ===== \'


