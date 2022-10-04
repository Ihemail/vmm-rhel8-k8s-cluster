# vmm-rhel8-k8s-crio-ha-cluster

# VMM K8s HA Cluster(crio, multi-master) - Multi Node Deployment via Shell Script

Note: Multiple node Shell Scripts are customized to run in RHEL8 console(preferably) bash shell. 

1. Load single/Multi Node JCNR/k8s topology file in vmm pod and start the topology:

    Multi node K8s Cluster(2 x Master and 1 x Worker node):
    ```ruby
    podxx-vmm:~ $ vmm config vmm-jcnr-4-ha.cfg -g vmm-default
    podxx-vmm:~ $ vmm start
    ```
    ```ruby
    podxx-vmm:~> vmm ip
    vm_rhel84_0 10.49.122.155              ## Load-balancer
    vm_rhel84_1 10.49.122.55               ## Master-1
    vm_rhel84_2 10.49.122.56               ## Master-2
    vm_rhel84_3 10.49.122.57               ## Worker-1
    vmx_1 10.49.122.45
    vmx_1_MPC0 10.49.122.101
    vm_openwrt_1 10.49.122.35
    ```

2. All the necessary scripts(*.sh) for all 4 nodes vm_rhel84_0,1,2,3(with crio as container runtime) are avaiable under this folder.

3. If you need to change the server hostname then modofy the '/etc/hostname' file and reboot the server via conosle:
   [login: root/contrail123]
  
    ```ruby
    [root@rhel84 ~]# cat /etc/hostname
    rhel85
    [root@rhel84 ~]# reboot
    ```

4. Prepare the load-banacer for kubernetes api endpoint load sharing:
   Transfer shell script 'k8s-crio-load-balance.sh' to 'vm_rhel84_0'(load-balancer) node and execute after adding load-balancer & master_ip details
  
    update the load-balancer's eth0 IP address as "master_ip" and master-1,2 ip details:
    ```ruby
    [root@rhel85 ~]# vi k8s-crio-load-balance.sh
    #!/bin/bash

     ## -- Update Load-balancer and Master Nodes IP details in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155          ## [ eth0 ] load-balancer's(haproxy) IP
     export master_1_ip=10.49.122.55
     export master_2_ip=10.49.122.56
     
     . . .
    [root@rhel85 ~]# sh k8s-crio-load-balance.sh
    ```

5. Prepare the master-1 node:
   Transfer shell script 'k8s-crio-ha-master-1.sh' to 'vm_rhel84_1'(master-1) node and execute after adding master_ip details
    
    update the load-balancer's eth0 IP address as "master_ip":
    ```ruby
    [root@rhel85 ~]# vi k8s-crio-ha-master-1.sh
    #!/bin/bash

     ## -- Update load-balancer IP as Master IP in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155          ## load-balancer(haproxy) IP
     
     . . .
    [root@rhel85 ~]# sh k8s-crio-ha-master-1.sh
    ```

6. Prepare the master-2 node:
   Transfer shell script 'k8s-crio-ha-master-2.sh' to 'vm_rhel84_2'(master-2) node and execute after adding load-balancer & master_1_ip details
  
    update the load-balancer's eth0 IP address as "master_ip", master-1 ip & token details:
    ```ruby
    [root@rhel85 ~]# vi k8s-crio-ha-master-2.sh
    #!/bin/bash

     ## -- Update Load-balancer, Master-1 Node IP & token details in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155          ## load-balancer(haproxy) IP
     export master_1_ip=10.49.122.55 
     export master_token=1234xxxx
     export master_token_hash=sha256:1234xxxx
     export cert_key=1234xxxx

     . . .
    [root@rhel85 ~]# sh k8s-crio-ha-master-2.sh
    ```

7. Prepare the Worker-x node/s:
   Transfer shell script 'k8s-crio-ha-worker.sh' to 'vm_rhel84_3'(worker-1) node and execute after adding load-balancer & master_1_ip details
  
    update the load-balancer's eth0 IP address as "master_ip", master-1 ip & token details:
    ```ruby
    [root@rhel85 ~]# vi k8s-crio-ha-worker.sh
    #!/bin/bash
    
     ## -- Update Load-balancer, Master-1 Node IP & token details in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155          ## load-balancer(haproxy) IP
     export master_1_ip=10.49.122.55
     export master_token=1234xxxx
     export master_token_hash=sha256:1234xxxx
     
    . . .
    [root@rhel85 ~]# sh k8s-crio-ha-worker.sh
    ```

8. Verify the K8s HA Cluster is up and pods are running properly in both Master & Worker nodes:

    @Master-1 node:
    ```ruby
    [root@rhel84-master-1 ~]# kubectl get nodes -o wide
    NAME              STATUS   ROLES                  AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
    rhel84-master-1   Ready    control-plane,master   11m     v1.25.2   10.49.122.55    <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.24.2
    rhel85-master-2   Ready    control-plane,master   2m8s    v1.25.2   10.49.122.56    <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.24.2
    rhel86-worker     Ready    worker                 3m13s   v1.25.2   10.49.122.57    <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.24.2
    [root@rhel84-master-1 ~]# kubectl get pods -A
    NAMESPACE     NAME                                       READY   STATUS    RESTARTS        AGE
    kube-system   calico-kube-controllers-58dbc876ff-hm9cc   1/1     Running   0               11m
    kube-system   calico-node-2mznf                          1/1     Running   0               11m
    kube-system   calico-node-bc8sc                          1/1     Running   0               3m38s
    kube-system   calico-node-m9dpk                          1/1     Running   0               2m33s
    kube-system   coredns-565d847f94-64zqh                   1/1     Running   0               12m
    kube-system   coredns-565d847f94-frbth                   1/1     Running   0               12m
    kube-system   etcd-rhel84-master-1                       1/1     Running   0               12m
    kube-system   etcd-rhel85-master-2                       1/1     Running   0               2m29s
    kube-system   kube-apiserver-rhel84-master-1             1/1     Running   0               12m
    kube-system   kube-apiserver-rhel85-master-2             1/1     Running   0               2m33s
    kube-system   kube-controller-manager-rhel84-master-1    1/1     Running   1 (2m19s ago)   12m
    kube-system   kube-controller-manager-rhel85-master-2    1/1     Running   0               2m32s
    kube-system   kube-proxy-49mrr                           1/1     Running   0               12m
    kube-system   kube-proxy-jthpq                           1/1     Running   0               2m33s
    kube-system   kube-proxy-vpzmn                           1/1     Running   0               3m38s
    kube-system   kube-scheduler-rhel84-master-1             1/1     Running   1 (2m17s ago)   12m
    kube-system   kube-scheduler-rhel85-master-2             1/1     Running   0               2m32s
    ```
  
    @Worker node:
    ```ruby
    [root@rhel86-worker ~]# kubectl get nodes -o wide
    NAME              STATUS   ROLES                  AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
    rhel84-master-1   Ready    control-plane,master   3h4m   v1.25.2   10.51.131.174   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.24.2
    rhel85-master-2   Ready    control-plane,master   174m   v1.25.2   10.51.128.104   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.24.2
    rhel86-worker     Ready    worker                 175m   v1.25.2   10.51.151.76    <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   cri-o://1.24.2
    [root@rhel86-worker ~]#
    ```
  
6. Close all Terminal app window once work is complete.
