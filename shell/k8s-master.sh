#!/bin/bash

 subscription-manager unregister
 subscription-manager clean
 subscription-manager register --username xxxx --password xxxx --force
 subscription-manager attach --auto
 systemctl stop firewalld
 systemctl disable firewalld
 sudo sed -i '/ swap / s/^/#/' /etc/fstab
 sudo swapoff -a
 sudo setenforce 0
 sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 sed -i '/subscription-manager/d' /root/k8s-master.sh
 sudo sed -i 's/reboot now#/#reboot now/g' /root/k8s-master.sh
 #reboot now#

hostname=$(hostname)
eth0ip=$(hostname -I | awk '{print $1}')
sed -i 's/rhel84/ /g' /etc/hosts
sed -i 's/localhost6 localhost6.localdomain6/localhost6 localhost6.localdomain6\n\n'"$eth0ip"' '"$hostname"'/g' /etc/hosts
sudo yum install -y net-tools vim iproute-tc wget sshpass git vim net-tools bridge-utils dpdk ethtool yum-utils bash-completion &
sleep 120

cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

 dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
 dnf install docker-ce --nobest -y &
 sleep 120
 yum install -y containerd.io docker-ce-cli yum-utils device-mapper-persistent-data lvm2 iproute-tc &
 sleep 300
 mkdir -p /etc/containerd
 containerd config default > /etc/containerd/config.toml
 systemctl restart containerd
 systemctl enable containerd
 systemctl enable --now docker
 #dnf update -y && dnf install -y containerd.io docker-ce docker-ce-cli yum-utils device-mapper-persistent-data lvm2 &

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
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$eth0ip
#--kubernetes-version stable-1.25
echo "kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address=$eth0ip"
sleep 30
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo '\ =====  Execute kubeadm cmd to Join this Kubernetes Cluter ::  ===== \'
kubeadm token create --print-join-command

 sleep 10
 kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
 #kubectl config set-context --namespace=kube-system --current
 kubectl taint nodes --all node-role.kubernetes.io/master-
 kubectl taint nodes --all node-role.kubernetes.io/control-plane-
 #kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
 kubectl get pods -A -o wide

echo "\ =====  API Server :: eth0 :: ($eth0ip)  ===== \ "
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo 'alias ku=kubectl' >> ~/.bashrc

echo '\ =====  K8s Cluter(Master) installation Complete :)  ===== \'

