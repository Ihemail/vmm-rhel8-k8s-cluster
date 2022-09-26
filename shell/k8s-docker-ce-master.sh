#!/bin/bash

 ## docker-ce :: ##
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
 sed -i '/subscription-manager/d' /root/k8s-master.sh
 sudo sed -i 's/reboot now#/#reboot now/g' /root/k8s-master.sh
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
echo '\ ==== cri-dockerd version :: ==== \'
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
sleep 120
sudo systemctl enable kubelet && systemctl start kubelet

sudo kubeadm config images pull --cri-socket /run/cri-dockerd.sock &
sleep 60
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket /run/cri-dockerd.sock

 sleep 30  
 mkdir -p $HOME/.kube
 sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
 sudo chown $(id -u):$(id -g) $HOME/.kube/config
 echo '****** cat /var/lib/kubelet/kubeadm-flags.env  ******'
 sudo cat /var/lib/kubelet/kubeadm-flags.env
 
echo '\ =====  Execute kubeadm cmd to Join this Kubernetes Cluter ::  ===== \'
kubeadm token create --print-join-command

 kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
 #kubectl config set-context --namespace=kube-system --current
 kubectl taint nodes --all node-role.kubernetes.io/master-
 kubectl taint nodes --all node-role.kubernetes.io/control-plane-
 #kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
 kubectl label node $hostname node-role.kubernetes.io/master=
 kubectl get node -A -o wide
 kubectl get node --show-labels
 sleep 30 
 kubectl get pods -A -o wide
 
echo "\ =====  API Server :: eth0 :: ($eth0ip)  ===== \ "
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo 'alias ku=kubectl' >> ~/.bashrc
echo '\ =====  K8s Cluter(Master) installation Complete :)  ===== \'


