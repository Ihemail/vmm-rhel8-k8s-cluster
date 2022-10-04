# vmm-rhel8-k8s-crio-ha-cluster

# VMM K8s HA Cluster(crio, multi-master) - Multi Node Deployment via Shell Script

Note: Multiple node Shell Scripts are customized to run in RHEL8 console(preferably) bash shell. 

1. Load single/Multi Node JCNR/k8s topology file in vmm pod and start the topology:

    Single node K8s Cluster(Master only):
    ```ruby
    podxx-vmm:~ $ vmm config vmm-jcnr-1.cfg -g vmm-default
    podxx-vmm:~ $ vmm start
    ```
    Multi node K8s Cluster(Master and Worker node):
    ```ruby
    podxx-vmm:~ $ vmm config vmm-jcnr-2.cfg -g vmm-default
    podxx-vmm:~ $ vmm start
    ```
    ```ruby
    podxx-vmm:~> vmm ip
    vm_rhel84_1 10.49.122.155
    vmx_1 10.49.122.45
    vmx_1_MPC0 10.49.122.101
    vm_openwrt_1 10.49.122.35
    ```

2. All the necessary scripts (for both default contained & docker-ce container runtime) are avaiable under folder shell.

3. If you need to change the server hostname then modofy the '/etc/hostname' file and reboot the server via conosle:
   [login: root/contrail123]
  
    ```ruby
    [root@rhel84 ~]# cat /etc/hostname
    rhel85
    [root@rhel84 ~]# reboot
    ```

4. Transfer the shell script 'k8s-master.sh' or 'k8s-docker-ce-master.sh' or 'k8s-crio-master.sh' to 'vm_rhel84_1'(master) node and execute:
  
    containerd as k8s container runtime:
    ```ruby
    [root@rhel85 ~]# sh k8s-master.sh
    ```
    docker-ce as k8s container runtime:
    ```ruby
    [root@rhel85 ~]# sh k8s-docker-ce-master.sh
    ```
    cri-o as k8s container runtime:
    ```ruby
    [root@rhel85 ~]# sh k8s-crio-master.sh
    ```

5. For Worker node/s transfer the shell script 'k8s-worker.sh' or 'k8s-docker-ce-worker.sh' or 'k8s-crio-worker.sh' to 'vm_rhel84_x'(worker) node and execute after adding master IP & token details:
  
    containerd as k8s container runtime:
    ```ruby
    [root@rhel85 ~]# vi k8s-worker.sh
    #!/bin/bash
    
     ## -- Update Master Node IP and Token in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155
     export master_token=1234xxxx
     export master_token_hash=sha256:1234xxxx
     
    . . .
    [root@rhel85 ~]# sh k8s-worker.sh
    ```
    docker-ce as k8s container runtime:
    ```ruby
    [root@rhel85 ~]# vi k8s-docker-ce-worker.sh
    #!/bin/bash
    
     ## -- Update Master Node IP and Token in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155
     export master_token=1234xxxx
     export master_token_hash=sha256:1234xxxx
     
    . . .
    [root@rhel85 ~]# sh k8s-docker-ce-worker.sh
    ```
    cri-o as k8s container runtime:
    ```ruby
    [root@rhel85 ~]# vi k8s-crio-worker.sh
    #!/bin/bash
    
     ## -- Update Master Node IP and Token in Shell variable before executing the script -- ##
     export master_ip=10.49.122.155
     export master_token=1234xxxx
     export master_token_hash=sha256:1234xxxx
     
    . . .
    [root@rhel85 ~]# sh k8s-crio-worker.sh
    ```

5. Verify the K8s Cluster is up and pods are running properly in both Master & Worker nodes:

    @Master node:
    ```ruby
    [root@rhel84 ~]# kubectl get nodes -owide
    NAME            STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
    rhel84          Ready    control-plane,master   26m   v1.25.2   10.49.122.155   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   docker://20.10.18
    rhel85          Ready    worker                 62s   v1.25.2   10.53.59.47     <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   docker://20.10.18
    [root@rhel84 ~]# kubectl get pods -A
    NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
    kube-system   calico-kube-controllers-58dbc876ff-8blbk   1/1     Running   0          54m
    kube-system   calico-node-7mp6f                          1/1     Running   0          29m
    kube-system   calico-node-8zrr4                          1/1     Running   0          54m
    kube-system   coredns-565d847f94-fmmsg                   1/1     Running   0          54m
    kube-system   coredns-565d847f94-q2fz6                   1/1     Running   0          54m
    kube-system   etcd-rhel84                                1/1     Running   0          54m
    kube-system   kube-apiserver-rhel84                      1/1     Running   0          54m
    kube-system   kube-controller-manager-rhel84             1/1     Running   0          54m
    kube-system   kube-proxy-kfh5f                           1/1     Running   0          29m
    kube-system   kube-proxy-nhchf                           1/1     Running   0          54m
    kube-system   kube-scheduler-rhel84                      1/1     Running   0          54m
    [root@rhel84 ~]#
    ```
  
    @Worker node:
    ```ruby
    [root@rhel85 ~]# kubectl get node -o wide
    NAME            STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                               KERNEL-VERSION          CONTAINER-RUNTIME
    rhel84          Ready    control-plane,master   57m   v1.25.2   10.49.122.155   <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   docker://20.10.18
    rhel85          Ready    worker                 31m   v1.25.2   10.53.59.47     <none>        Red Hat Enterprise Linux 8.4 (Ootpa)   4.18.0-305.el8.x86_64   docker://20.10.18
    [root@rhel85 ~]#
    ```
  
6. Close all Terminal app window once work is complete.
