+++
date = "2016-06-15T15:11:09-04:00"
draft = false
title = "aws vpc vpn linode gre"
author = "Richard Genthner"
comments = true
image = ""
menu = ""
share = true
slug = "aws-vpc-vpn-linode-gre"
tags = ["aws", "vpn", "linode","networking"]
+++

So we have started to migrate from [Linode](https://www.linode.com) to [Amazon Aws](https://aws.amazon.com) at work. We are using a specialized AWS VPC design to make our infrastructure faster and strong then we could at linode. Also more secure. One of the major issues had to overcome is the lack of being able to directly connect aws to linode and linode to aws. So with some magic and special sauce we was able to come up with the following solution.

__RACOON + QUAGGA + GRE TUNNELS == FTW__

So first you if your on linode you will need to make sure you do the following steps that will not be covered by this tutorial. One is get on the generic kernel and not the custom linode kernels. Second you will need to make sure you setup your VPC VPN configuration. I suggest you follow the following tutorial by [Medium AWS VPC VPN with BGP](https://medium.com/@silasthomas/aws-vpc-ipsec-site-to-site-vpn-using-a-ubiquiti-edgemax-edgerouter-with-bgp-routing-37abafb950f3#.o1n31p7em) It's important that you follow the steps and download the generic configuration. You will need this later on in the tutorial. I am also assuming that you have multiple machines in Linode and they are debian/ubuntu based. You will want to spin up a box that will be labeled as your AWS gateway. 

#### Racoon Setup
You will need to install racoon first. Using ```apt-get install ipsec-tools racoon``` if your runing RHEL based or BSD based you will need to google how to install racoon and ipsec-tools. 

#### Quagga Setup
You will need to install quagga first. Using ```apt-get install quagga``` if your running RHEL based or BSD based you will need to google how to install quagga. 

### Configuration of Racoon and Quagga
Lucky enough I have written a script to make this a lot easy for you :) The following script will generate the racoon and quagga configuration for you.

{{< gist moos3 36c5bfc36e084e8c4ca18f44eb6f8292 >}}

To run this script you are going to want to make sure you have copied your generic configuration text file to the machine your going to set up as your AWS VPC VPC gateway. Then edit this script and set the following Varaiables 

{{< gist moos3 bffb716f8add396fb6400868b77e754b >}}

Once you have those set run the script like such ```./vpnsetup.sh aws-configuration.txt``` Sit back and wait for it to parse and run. To check if it came up look at the following logs /var/log/quagga/bgp.log and if its successful you should see output like so:

{{< gist moos3 6bd0956e53d19479607825b8984eff35 >}}

If you have a node in your VPC you should be able to ping it from this box. Now you have successfully setup BGP and IPSEC on linux :) If you dont see this in your logs, then check the following things your BGP_ID vaule, or that your ipsec has come up. Use this command to check your racoon ```racoonctl show-sa ipsec```


###GRE setup and configuration
So the second part of this is to make other nodes talk to the AWS nodes from inside of linode. We will use GRE for this. First thing is to edit `/etc/modules` and insert ip_gre in the file so the kenerl will load it up. Next you are going to want to pick a subnet size that will fit what your trying to do. I would stick with something not bigger than a /26. For this example we are going to use 10.10.0.0/26 for our GRE network. So in this example we will use two boxes to get started. I recommend that you use the following for box A (aws vpn gateway box)

Remote needs to be set to the ip address of the box on the other end. Local is the local ip of box your adding the tunnel to.

AWS vpn gateway box:

```
ip tunnel add gre-client mode gre remote 192.168.1.34 local 192.168.0.24 ttl 255
ip link set gre-client up
ip link set gre-client multicast on
ip addr add 10.10.0.1/26 broadcast 10.10.0.63 dev gre-client
```

Client box that needs to connect to aws:

```
ip tunnel add gre-vpn remote 192.168.0.24 local 192.168.1.34 ttl 255
ip link set gre-vpn up
ip link set gre-vpn multicast on
ip addr add 10.10.0.2/27 broadcast 10.10.0.63 dev gre-vpn
```

Next you will need to add route on the client side that tells it how to route traffic for your aws network to the aws vpn gateway.

```
ip route add 172.16.0.0/16 via 10.10.0.1
```

Then on the AWS vpn gateway box we will need to update iptables with a SNAT rule. That will look like this 

```
iptables -t nat -A POSTROUTING --src 10.10.0.0/26 --dst 172.16.0.0/16 -j SNAT --to-source 169.254.44.42
```
The important part here is that the dst is set to your aws vpc network and that to-source is the box which is running the bgp service. You can find this ip address in the logs for quagga looking for Zebra rcvd command.

```
2016/06/15 17:13:37 BGP: Zebra rcvd: interface eth0 address add 169.254.44.234/30
2016/06/15 17:13:37 BGP: Zebra rcvd: interface eth0 address add 169.254.44.42/30
```

Now you should be able to ping or traceroute to your AWS nodes in the vpc. If you can do this then your golden. Some things you might try if this doesn't work. One add the following iptables rule in `iptables -A FORWARD -j LOG` and this will log all the forwarded traffic. Two make sure that forwarding is on in sysctl.conf on both the gateway and client.


Happy BGP'ing and GRE routing around a limitation on Linode. You could use this in many applications not just linode. Also a good read on GRE see [GRE Tutorial](http://bjornruud.net/2011/02/gre-tunnel-with-multicast-support.html).
