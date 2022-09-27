#!/bin/bash

 ## -- Update Master Node IP and Token in Shell variable before executing the script -- ##
 export master_ip=10.49.122.155
 export master_token=1234xxxx
 export master_token_hash=sha256:1234xxxx

 #subscription-manager unregister
 #subscription-manager clean
 #subscription-manager register --username xxxx --password xxxx --force
 #subscription-manager attach --auto
 systemctl stop firewalld
 systemctl disable firewalld
 sudo sed -i '/ swap / s/^/#/' /etc/fstab
 sudo swapoff -a
 sudo setenforce 0
 sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 sed -i '/subscription-manager/d' /root/k8s-worker.sh
 sudo sed -i 's/reboot now#/#reboot now/g' /root/k8s-worker.sh
 #reboot now#

hostname=$(hostname)
eth0ip=$(hostname -I | awk '{print $1}')
sed -i 's/rhel84/ /g' /etc/hosts
sed -i 's/localhost6 localhost6.localdomain6/localhost6 localhost6.localdomain6\n\n'"$eth0ip"' '"$hostname"'/g' /etc/hosts
sudo yum install -y net-tools vim wget sshpass git iproute-tc bridge-utils dpdk ethtool yum-utils bash-completion &
sleep 120

cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

 dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
 #dnf install docker-ce --nobest -y &
 #sleep 120
 yum install -y containerd.io docker-ce-cli yum-utils device-mapper-persistent-data lvm2 iproute-tc &
 sleep 120
 mkdir -p /etc/containerd
 containerd config default > /etc/containerd/config.toml
 systemctl restart containerd && systemctl enable containerd
 #systemctl enable docker && systemctl start docker
 #dnf update -y && dnf install -y containerd.io docker-ce docker-ce-cli yum-utils device-mapper-persistent-data lvm2 &

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
sleep 120
sudo systemctl enable kubelet && systemctl start kubelet
echo '\ =====  Hello World :)  ===== \'

kubeadm join $master_ip:6443 --token $master_token --discovery-token-ca-cert-hash $master_token_hash
echo "kubeadm join $master_ip:6443 --token $master_token --discovery-token-ca-cert-hash $master_token_hash"

 sleep 40
 sshpass -p 'contrail123' scp -o stricthostkeychecking=no -r root@$master_ip:/root/.kube $HOME/
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

