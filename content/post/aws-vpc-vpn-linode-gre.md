+++
date = "2016-06-15T15:11:09-04:00"
draft = true
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

```bash
#!/bin/bash
#
# Setup VPN between Debian Linux and VPC G/W.
#   How to use : ./this_script.sh Generic.txt
# Required packages: racoon ipsec-tools quagga

PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

exitMessage() {
    echo "$@" >&2
    exit 1
}

[ `id -u` = 0 ] || exitMessage "Set user to root."


#
# Opetion
#

CONF=$1
[ -z "$CONF" -o ! -r "$CONF" ] && exitMessage "Input VPC+VPN Generic config."

#########
#
# Config
#

INTERFACE="eth0"
BGP_ID='6500' # Set this to your unique ID
VPC_SUBNET="172.16.0.0/16" # Set this to your Subnet
QUAGGA_PASSWORD="SetSecurePassword"  # Set this a Password thats secure



### DONT TOUCH ###
CUSTOMER_SUBNET=`LANG=C ip addr show dev $INTERFACE \
              | grep -m1 "inet " | sed -e 's/^.*inet \([\.0-9\/]\+\) .*/\1/g'`
CUSTOMER_ADDR=`echo "$CUSTOMER_SUBNET" | cut -d/ -f1`
HOSTNAME=`hostname`

### Log locations
RACOON_LOG="/var/log/racoon/racoon.log"
BGPD_LOG="/var/log/quagga/bgpd.log"

#########
#
# Generic Config Values
#

CONNECTION_ID=`cat $CONF | grep "Your VPN Connection ID" | awk '{print $6}'`

T1_OUT_CUSTOMER_GW=`cat $CONF | grep -m1 "\- Customer Gateway"        | tail -1 | awk '{print $5}'`
T1_OUT_VPC_GW=`     cat $CONF | grep -m1 "\- Virtual Private Gateway" | tail -1 | awk '{print $6}'`
T1_IN_CUSTOMER_GW=` cat $CONF | grep -m2 "\- Customer Gateway"        | tail -1 | awk '{print $5}'`
T1_IN_VPC_GW=`      cat $CONF | grep -m2 "\- Virtual Private Gateway" | tail -1 | awk '{print $6}'`
T1_PSK=`            cat $CONF | grep -m1 "\- Pre-Shared Key"          | tail -1 | awk '{print $5}'`
T1_ASN=`            cat $CONF | grep -m1 "Private *Gateway ASN"       | tail -1 | awk '{print $7}'`
T1_NEIGHBOR_ADDR=`  cat $CONF | grep -m1 "Neighbor IP Address"        | tail -1 | awk '{print $6}'`

T2_OUT_CUSTOMER_GW=`cat $CONF | grep -m4 "\- Customer Gateway"        | tail -1 | awk '{print $5}'`
T2_OUT_VPC_GW=`     cat $CONF | grep -m3 "\- Virtual Private Gateway" | tail -1 | awk '{print $6}'`
T2_IN_CUSTOMER_GW=` cat $CONF | grep -m5 "\- Customer Gateway"        | tail -1 | awk '{print $5}'`
T2_IN_VPC_GW=`      cat $CONF | grep -m4 "\- Virtual Private Gateway" | tail -1 | awk '{print $6}'`
T2_PSK=`            cat $CONF | grep -m2 "\- Pre-Shared Key"          | tail -1 | awk '{print $5}'`
T2_ASN=`            cat $CONF | grep -m2 "Private *Gateway ASN"       | tail -1 | awk '{print $7}'`
T2_NEIGHBOR_ADDR=`  cat $CONF | grep -m2 "Neighbor IP Address"        | tail -1 | awk '{print $6}'`

VALUES="T1_OUT_CUSTOMER_GW T1_OUT_VPC_GW T1_IN_CUSTOMER_GW T1_IN_VPC_GW"
VALUES+=" T1_PSK T1_ASN T1_NEIGHBOR_ADDR"
VALUES+=" T2_OUT_CUSTOMER_GW T2_OUT_VPC_GW T2_IN_CUSTOMER_GW T2_IN_VPC_GW"
VALUES+=" T2_PSK T2_ASN T2_NEIGHBOR_ADDR"
for v in $VALUES
do
	[ -z `eval 'echo $'$v` ] && exitMessage "Colud not found $v from $CONF."
done

#########
#
# Package
#

apt-get -y install racoon ipsec-tools quagga

#########
#
# sysctl
#

cat << EOT > /etc/sysctl.d/vpn.conf
net.ipv4.ip_forward = 1

# prevent the panic of client, when switching vpn route.
net.ipv4.conf.all.send_redirects	= 0
net.ipv4.conf.default.send_redirects	= 0
net.ipv4.conf.eth0.send_redirects	= 0
net.ipv4.conf.lo.send_redirects		= 0

net.ipv4.conf.all.accept_redirects	= 0
net.ipv4.conf.default.accept_redirects	= 0
net.ipv4.conf.eth0.accept_redirects	= 0
net.ipv4.conf.lo.accept_redirects	= 0
EOT

service procps restart

#
# Create Config File
#

## Pre-Shared Key ##

cat << EOT > /etc/racoon/aws-vpc-psk.txt
$T1_OUT_VPC_GW $T1_PSK
$T2_OUT_VPC_GW $T2_PSK
EOT

chmod 600 /etc/racoon/aws-vpc-psk.txt

#
# Racoon
#

mkdir /var/log/racoon

cat << EOT > /etc/racoon/racoon.conf
log notify;
path pre_shared_key "/etc/racoon/aws-vpc-psk.txt";

remote $T1_OUT_VPC_GW {
	exchange_mode main;
	lifetime time 28800 seconds;
    dpd_delay = 10;
    dpd_retry = 3;
	proposal {
		encryption_algorithm aes128;
		hash_algorithm sha1;
		authentication_method pre_shared_key;
		dh_group 2;
	}
	generate_policy off;
}

remote $T2_OUT_VPC_GW {
	exchange_mode main;
	lifetime time 28800 seconds;
    dpd_delay = 10;
    dpd_retry = 3;
	proposal {
		encryption_algorithm aes128;
		hash_algorithm sha1;
		authentication_method pre_shared_key;
		dh_group 2;
	}
	generate_policy off;
}

sainfo address $T1_IN_CUSTOMER_GW any address $T1_IN_VPC_GW any {
	pfs_group 2;
	lifetime time 3600 seconds;
	encryption_algorithm aes128;
	authentication_algorithm hmac_sha1;
	compression_algorithm deflate;
}

sainfo address $T2_IN_CUSTOMER_GW any address $T2_IN_VPC_GW any {
	pfs_group 2;
	lifetime time 3600 seconds;
	encryption_algorithm aes128;
	authentication_algorithm hmac_sha1;
	compression_algorithm deflate;
}
EOT

#
# Setkey
#

cat << EOT > /etc/ipsec-tools.d/vpc.conf
#!/usr/sbin/setkey -f

flush;
spdflush;

# Tunnel1 Transfer Net
spdadd $T1_IN_CUSTOMER_GW $T1_IN_VPC_GW any -P out ipsec esp/tunnel/$CUSTOMER_ADDR-$T1_OUT_VPC_GW/require;
spdadd $T1_IN_VPC_GW $T1_IN_CUSTOMER_GW any -P in  ipsec esp/tunnel/$T1_OUT_VPC_GW-$CUSTOMER_ADDR/require;

# Tunnel1 VPC right (debug only)
#spdadd $T1_IN_CUSTOMER_GW $VPC_SUBNET   any -P out ipsec esp/tunnel/$CUSTOMER_ADDR-$T1_OUT_VPC_GW/require;
#spdadd $VPC_SUBNET $T1_IN_CUSTOMER_GW   any -P in  ipsec esp/tunnel/$T1_OUT_VPC_GW-$CUSTOMER_ADDR/require;

# Tunnel2 Transfer Net
spdadd $T2_IN_CUSTOMER_GW $T2_IN_VPC_GW any -P out ipsec esp/tunnel/$CUSTOMER_ADDR-$T2_OUT_VPC_GW/require;
spdadd $T2_IN_VPC_GW $T2_IN_CUSTOMER_GW any -P in  ipsec esp/tunnel/$T2_OUT_VPC_GW-$CUSTOMER_ADDR/require;

# Tunnel2 VPC right (debug only)
spdadd $T2_IN_CUSTOMER_GW $VPC_SUBNET   any -P out ipsec esp/tunnel/$CUSTOMER_ADDR-$T2_OUT_VPC_GW/require;
spdadd $VPC_SUBNET $T2_IN_CUSTOMER_GW   any -P in  ipsec esp/tunnel/$T2_OUT_VPC_GW-$CUSTOMER_ADDR/require;
EOT

#
# bgpd
#

cat << EOT > /etc/quagga/bgpd.conf
hostname $HOSTNAME
password $QUAGGA_PASSWORD
enable password $QUAGGA_PASSWORD
!
log file $BGPD_LOG
!debug bgp events
!debug bgp zebra
debug bgp updates
!
router bgp $BGP_ID
bgp router-id $CUSTOMER_ADDR
network $T1_IN_CUSTOMER_GW
network $T2_IN_CUSTOMER_GW
! Routing for VPC to CUSTOMER (see Route Tables on VPC Console)
! if CustomerVPN forward using NAT, this is unnecessary.
network $CUSTOMER_SUBNET
!
! aws tunnel #1 neighbor
neighbor $T1_NEIGHBOR_ADDR remote-as $T1_ASN
! aws tunnel #2 neighbor
neighbor $T2_NEIGHBOR_ADDR remote-as $T2_ASN
!
line vty
EOT

#
# zebra config
#

cat << EOT > /etc/quagga/zebra.conf
hostname $HOSTNAME
password $QUAGGA_PASSWORD
enable password $QUAGGA_PASSWORD
!
! list interfaces
interface $INTERFACE
interface lo
!
line vty
EOT

#
# Racoon log
#

sed -i "s|RACOON_ARGS.*$|RACOON_ARGS='-l $RACOON_LOG'|g" /etc/default/racoon

cat << EOT > /etc/logrotate.d/racoon
$RACOON_LOG {
	rotate 10
	daily
	compress
	missingok
	notifempty
	copytruncate
}
EOT


#
# Enable zebra and bgpd
#

sed -i 's/zebra=no/zebra=yes/' /etc/quagga/daemons
sed -i 's/bgpd=no/bgpd=yes/'   /etc/quagga/daemons

#
# Create Static Tunnel Addr
#

ip addr add $T1_IN_CUSTOMER_GW dev $INTERFACE
ip addr add $T2_IN_CUSTOMER_GW dev $INTERFACE

#
# Restart Services
#

service racoon restart
service setkey restart
service quagga restart
```

To run this script you are going to want to make sure you have copied your generic configuration text file to the machine your going to set up as your AWS VPC VPC gateway. Then edit this script and set the following Varaiables 

```bash
INTERFACE="eth0"
BGP_ID='6500' # Set this to your unique ID
VPC_SUBNET="172.16.0.0/16" # Set this to your Subnet
QUAGGA_PASSWORD="SetSecurePassword"  # Set this a Password thats secure

```

Once you have those set run the script like such ```./vpnsetup.sh aws-configuration.txt``` Sit back and wait for it to parse and run. To check if it came up look at the following logs /var/log/quagga/bgp.log and if its successful you should see output like so:

```
2016/06/15 17:13:45 BGP: BGPd 0.99.22.4 starting: vty@2605, bgp@<all>:179
2016/06/15 17:13:54 BGP: 169.254.44.233 send UPDATE 169.254.44.40/30
2016/06/15 17:13:54 BGP: 169.254.44.233 send UPDATE *************/24
2016/06/15 17:13:54 BGP: 169.254.44.233 send UPDATE 169.254.44.232/30
2016/06/15 17:13:54 BGP: 169.254.44.233 rcvd UPDATE w/ attr: nexthop 169.254.44.233, origin i, metric 200, path 7224
2016/06/15 17:13:54 BGP: 169.254.44.233 rcvd 172.16.0.0/16
2016/06/15 17:13:56 BGP: 169.254.44.41 send UPDATE 169.254.44.40/30
2016/06/15 17:13:56 BGP: 169.254.44.41 send UPDATE *************/24
2016/06/15 17:13:56 BGP: 169.254.44.41 send UPDATE 169.254.44.232/30
2016/06/15 17:13:56 BGP: 169.254.44.41 send UPDATE 172.16.0.0/16
2016/06/15 17:13:56 BGP: 169.254.44.41 rcvd UPDATE w/ attr: nexthop 169.254.44.41, origin i, metric 200, path 7224
2016/06/15 17:13:56 BGP: 169.254.44.41 rcvd 172.16.0.0/16
2016/06/15 17:14:24 BGP: 169.254.44.233 rcvd UPDATE w/ attr: nexthop 169.254.44.233, origin i, metric 200, path 7224
2016/06/15 17:14:24 BGP: 169.254.44.233 rcvd 172.16.0.0/16...duplicate ignored
2016/06/15 17:14:26 BGP: 169.254.44.41 rcvd UPDATE w/ attr: nexthop 169.254.44.41, origin i, metric 100, path 7224
2016/06/15 17:14:26 BGP: 169.254.44.41 rcvd 172.16.0.0/16
2016/06/15 17:14:26 BGP: 169.254.44.41 send UPDATE 172.16.0.0/16 -- unreachable
2016/06/15 17:14:54 BGP: 169.254.44.233 send UPDATE 172.16.0.0/16
```

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