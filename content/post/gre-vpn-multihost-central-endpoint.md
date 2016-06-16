+++
date = "2016-06-16T15:01:46-04:00"
draft = false
title = "GRE VPN with Multi-endpoints to single server"
author = "Richard Genthner"
comments = true
image = ""
menu = ""
share = true
slug = "gre-vpn-multihost-central-server"
tags = ["vpn", "linode","networking"]
+++

So this is a continuation of the article I wrote yesterday about AWS VPC VPN's with GRE. So in that article we discussed how to connect to machines point to point. Well what happens when the boss says hey lets does this for 20 machines. Well that solution will not work correctly. So lets get right into it.

First you will need to use some minor changes in syntax for this to work. Lets look at our tunnel setup command. In the last article it looked like this:

```
ip tunnel add gre-client local <ip> remote <ip> ttl 255
```

Its going to change to the following version:

```
ip tunnel add gre-client local <ip> key <string of numbers>
```

So you will see that we are not specifiing a remote endpoint this time or a ttl. You will see we have replaced the ttl with key. key is very important, its basically a authentication method. Next we will use the `ip neigh` command. This will allow us to tell the machine where to find the next machine in the subnet. It should look like this 

```
ip neigh add 10.10.0.1 lladdr <remote_host_ip> dev gre-vpn
```

So in the neighbor command you will replace the `<remote_host_ip>` with the address from the frist version remote endpoint address.

So all together it will look like this with three hosts

**Host A**

```
ip tunnel add gre-vpn local 192.168.10.232 key 123
ip link set gre-vpn up
ip addr add 10.10.0.1/26 broadcast 10.10.0.63 dev gre-vpn
ip neigh add 10.10.0.2 lladdr 192.168.19.24 dev gre-vpn
```

**Host B**

```
ip tunnel add gre-vpn local 192.168.19.24 key 123
ip link set gre-vpn up
ip addr add 10.10.0.2/26 broadcast 10.10.0.63 dev gre-vpn
ip neigh add 10.10.0.1 lladdr 192.168.10.232 dev gre-vpn
```

**Host C**

```
ip tunnel add gre-vpn local 192.168.29.23 key 123
ip link set gre-vpn up
ip addr add 10.10.0.3/26 broadcast 10.10.0.63 dev gre-vpn
ip neigh add 10.10.0.1 lladdr 192.168.10.232 dev gre-vpn
```

So now all three machine's should be able to talk to each other over the vpn. If you try to ping and can't ping a machine then you most likely have ufw on and just need to edit the `/etc/ufw/before.rules` file and put this in.

```
# Allow GRE protocol for VPN
-A ufw-before-input -p 47 -j ACCEPT
-A ufw-before-output -p 47 -j ACCEPT
```

This set of rules needs to happen before this set in the file:

```
# drop INVALID packets (logs these in loglevel medium and higher)
-A ufw-before-input -m conntrack --ctstate INVALID -j ufw-logging-deny
-A ufw-before-input -m conntrack --ctstate INVALID -j DROP
```

Once you have made you changes then disable ufw and then re-enable it. Then your pinging should pick up and work. 

If your like me and your Host A is also running the vpn to aws then you will want to add this line on all the hosts that you want to be able to ping in aws.

```
ip route add 172.16.0.0/16 via 10.10.0.1
```

Thats all you should need to all a unlimited number of gre tunnels to your vpn gateway box. Happy Vpn'ing.

