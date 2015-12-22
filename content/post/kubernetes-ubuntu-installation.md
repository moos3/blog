+++
date = "2015-12-22T11:32:51-08:00"
draft = false
title = "kubernetes installation on ubuntu"
author = "Richard Genthner"
comments = true
image = ""
menu = ""
share = true
slug = "kubernetes ubuntu installation"
tags = ["technology", "docker", "kubernetes", "cloud"]

+++

In this article I will show you how to setup kubernetes on ubuntu 14.04 or newer. I recently had to do this for a project.
Below are the steps to complete this with a example pod.

### steps
1. Become Root
```
sudo su -
```

2. Lets get the pre-requisite software packages installed
```
apt-get update
apt-get install ssh
apt-get install docker.io
apt-get install curl
apt-get install git
```

3. Password-less ssh login setup, accept all the default parameters in the prompt of the below command (required for Kubernetes installation)
```
$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
e1:c9:a5:dd:80:ee:cd:f0:c8:11:6c:a5:d4:ba:ff:cc root@vkohli-Latitude-E7440
The key's randomart image is:
+--[ RSA 2048]----+
|          ...    |
|         + o.    |
|        o B.     |
|       + B..+    |
|        S o..    |
|       . *..     |
|        . *.     |
|         .  .o   |
|             .E  |
+-----------------+
```

4. Copy the ssh id_rsa key locally
```
$ ssh-copy-id -i /root/.ssh/id_rsa.pub 127.0.0.1
```

In case this fails you can do it by hand. By doing:
```
$ cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
```

5. Validate the password-less ssh-login
```
$ ssh root@127.0.0.1
root@vkohli-virtual-machine:~$ exit
logout
Connection to 127.0.0.1 closed
```

6. Get the Kubernetes release bundle from the official github repository
```
$ wget https://github.com/GoogleCloudPlatform/kubernetes/releases/download/v1.0.1/kubernetes.tar.gz
```

7. Untar the Kubernetes bundle in the same directory
```
$ tar -xvf kubernetes.tar.gz
```

8. We will build the binaries of Kubernetes code specifically for ubuntu cluster
```
$ cd kubernetes/cluster/ubuntu
```
Execute the following shell script

```
$ ./build.sh
Download flannel release ...
Flannel version is 0.4.0
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                Dload  Upload   Total   Spent    Left  Speed
100   411    0   411    0     0    252      0 --:--:--  0:00:01 --:--:--   252
100 2393k  100 2393k    0     0   204k      0  0:00:11  0:00:11 --:--:--  388k
Download etcd release ...
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   410    0   410    0     0    272      0 --:--:--  0:00:01 --:--:--   272
100 3713k  100 3713k    0     0   286k      0  0:00:12  0:00:12 --:--:--  496k
Download kubernetes release ...
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                Dload  Upload   Total   Spent    Left  Speed
100   396    0   396    0     0    279      0 --:--:--  0:00:01 --:--:--   279
100 97.8M  100 97.8M    0     0   715k      0  0:02:20  0:02:20 --:--:--  501k
~/kubernetes/cluster/ubuntu/kubernetes/server ~/kubernetes/cluster/ubuntu
~/kubernetes/cluster/ubuntu
Done! All your commands locate in ./binaries dir
```

This shell script will download and build the latest version of K8s, etcd and flannel binaries which can be found at following location;
```
$ cd binaries
$ ls
kubectl  master  minion
```

kubectl binary controls the Kubernetes cluster manager and the folder master & minion contains the binaries built for the purpose of configuring K8s master and node respectively.

9. Configure the cluster information by editing only the following parameters of the file `cluster/ubuntu/config-default.sh` in the editor of your choice.
```
$ cd
$ vi kubernetes/cluster/ubuntu/config-default.sh
export nodes="root@127.0.0.1"
export roles="ai"
export NUM_MINIONS=${NUM_MINIONS:-1}
```

Only update the above mentioned information in the file, rest of the configuration will remain as it is. The first variable nodes defines all the cluster nodes, in our case same machine will be configured as master and node so it contains only one entry.The role below “ai” specifies that same machine will act as master, “a” stands for master and “i” stands for node.

10. Now, we will be starting the cluster with the following command;
```
$ cd kubernetes/cluster
$ KUBERNETES_PROVIDER=ubuntu ./kube-up.sh
Starting cluster using provider: ubuntu
... calling verify-prereqs
... calling kube-up
FLANNEL_NET
172.16.0.0/16
Deploying master and minion on machine 127.0.0.1

config-default.sh                                                                                100% 2904     2.8KB/s   00:00
util.sh                                                                                          100%   13KB  13.4KB/s   00:00
flanneld.conf                                                                                    100%  569     0.6KB/s   00:00
kube-controller-manager.conf                                                                     100%  746     0.7KB/s   00:00
kube-apiserver.conf                                                                              100%  676     0.7KB/s   00:00
etcd.conf                                                                                        100%  576     0.6KB/s   00:00
kube-scheduler.conf                                                                              100%  676     0.7KB/s   00:00
kube-apiserver                                                                                   100% 2358     2.3KB/s   00:00
kube-controller-manager                                                                          100% 2672     2.6KB/s   00:00
etcd                                                                                             100% 2073     2.0KB/s   00:00
flanneld                                                                                         100% 2159     2.1KB/s   00:00
kube-scheduler                                                                                   100% 2360     2.3KB/s   00:00
reconfDocker.sh                                                                                  100% 1493     1.5KB/s   00:00
kube-proxy.conf                                                                                  100%  648     0.6KB/s   00:00
flanneld.conf                                                                                    100%  569     0.6KB/s   00:00
kubelet.conf                                                                                     100%  634     0.6KB/s   00:00
etcd.conf                                                                                        100%  576     0.6KB/s   00:00
kube-proxy                                                                                       100% 2230     2.2KB/s   00:00
etcd                                                                                             100% 2073     2.0KB/s   00:00
flanneld                                                                                         100% 2159     2.1KB/s   00:00
kubelet                                                                                          100% 2162     2.1KB/s   00:00
kube-apiserver                                                                                   100%   34MB  33.7MB/s   00:00
kube-controller-manager                                                                          100%   26MB  26.2MB/s   00:00
etcdctl                                                                                          100% 6041KB   5.9MB/s   00:00
etcd                                                                                             100% 6494KB   6.3MB/s   00:00
flanneld                                                                                         100% 8695KB   8.5MB/s   00:00
kube-scheduler                                                                                   100%   17MB  17.0MB/s   00:00
kube-proxy                                                                                       100%   17MB  16.8MB/s   00:00
etcdctl                                                                                          100% 6041KB   5.9MB/s   00:00
etcd                                                                                             100% 6494KB   6.3MB/s   00:00
flanneld                                                                                         100% 8695KB   8.5MB/s   00:00
kubelet                                                                                          100%   33MB  33.2MB/s   00:01
[sudo] password to copy files and start node:
etcd start/running, process 1125
Connection to 127.0.0.1 closed.
Validating master
Validating root@127.0.0.1

Kubernetes cluster is running.  The master is running at:

  http://127.0.0.1

FLANNEL_NET
172.16.0.0/16
Using master 127.0.0.1
Wrote config for ubuntu to /home/root/.kube/config
... calling validate-cluster

Waiting for 1 ready nodes. 0 ready nodes, 0 registered. Retrying.
Found 1 nodes.
        NAME        LABELS                             STATUS
1       127.0.0.1   kubernetes.io/hostname=127.0.0.1   Ready
Validate output:
NAME                 STATUS    MESSAGE   ERROR
scheduler            Healthy   ok        nil
etcd-0               Healthy   {"action":"get","node":{"dir":true,"nodes":[{"key":"/registry","dir":true,"modifiedIndex":3,"createdIndex":3},{"key":"/coreos.com","dir":true,"modifiedIndex":16,"createdIndex":16}]}}
                     nil
controller-manager   Healthy   ok        nil
Cluster validation succeeded
Done, listing cluster services:

Kubernetes master is running at http://127.0.0.1:8080
```


See Part 2 for setting up the server for starting up on reboot.
