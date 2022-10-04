#!/bin/bash

 ## -- Update Load-balancer and Master Nodes IP details in Shell variable before executing the script -- ##
 export master_ip=10.49.122.155          ## [ eth0 ] load-balancer(haproxy) IP
 export master_1_ip=10.49.122.55
 export master_2_ip=10.49.122.56
 
 ## docker-crio :: load-balancer ##
 subscription-manager repos --disable fast-datapath-for-rhel-8-x86_64-rpms  
 subscription-manager repos --enable fast-datapath-for-rhel-8-x86_64-rpms
 systemctl stop firewalld
 systemctl disable firewalld
 sudo sed -i '/ swap / s/^/#/' /etc/fstab
 sudo swapoff -a
 sudo setenforce 0
 sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 sed -i '/subscription-manager/d' /root/k8s-crio-load-balance.sh

hostname=$(hostname)
eth0ip=$(hostname -I | awk '{print $1}')
sed -i 's/rhel84/ /g' /etc/hosts
sed -i 's/localhost6 localhost6.localdomain6/localhost6 localhost6.localdomain6\n\n'"$eth0ip"' '"$hostname"'/g' /etc/hosts

 sudo dnf install -y yum-utils iproute-tc net-tools wget sshpass git bash-completion haproxy &
 sleep 90

sudo cat >> /etc/haproxy/haproxy.cfg <<EOF

frontend kubernetes-frontend
    bind $master_ip:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    option tcp-check
    balance roundrobin
    server kmaster1 $master_1_ip:6443 check fall 3 rise 2
    server kmaster2 $master_2_ip:6443 check fall 3 rise 2

EOF
sudo systemctl restart haproxy && sudo systemctl enable haproxy 

echo '\ =====  Hello World :)  ===== \'
echo '\ =====  K8s Cluter - Load-Balancer installation Complete :)  ===== \'


