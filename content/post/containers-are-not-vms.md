+++
author = "Richard Genthner"
comments = true
date = "2015-07-18T23:53:49-04:00"
draft = false
image = ""
menu = ""
share = true
slug = "containers-are-not-vms"
tags = ["infrastructure", "docker", "containers"]
title = "Containers are not VMs"

+++

So lately I have been digging deeper and deeper into containers and there
usefulness. It seems that a lot of people blur the line between VM's and
Containers. I think its important that we define the two here before we get to
invested in this article.

##### VM Concepts
A VM per its name is a Virtual Machine, so this by default is Read/Write
enabled. Where your changes aren't lost in reboots or host shutdowns. This is
great for things where your not using source control. And your machine isn't
defined as Code!.

##### LXC Containers
Now lxc containers are read/write or even read only containers. This have the
same issue as VM's and that is they arent defined by code. They have act like
VM's or act in the ideaism's of Docker containers if you wish. This dont have
a hypervisor, cgroups can be a nightmare to get working depending on our OS
they my or not work.

##### Docker Containers
Now Docker containers are defined as Code, but they are read only. So you can't
use them as a vm and except your changes to stick unless you define it in the
code that makes the container. These typically only host one service, or one
task. Such as a Web Server or a Database server. Their cgroups work out of the
box.

##### Container Concepts
So the ideaism behind containers is this you have a service say nginx and your
going to host your website. 99% of the time your not going to need to increase
the number of nginx servers but the services that run php, ruby,etc. So you
would a nginx docker container, a php-fpm container set and haproxy. Your nginx
container would point to the HAProxy container which in turn points to the
php-fpm containers that you would scale based on demand. This is called one
service or one task containerism.

So now that we have that cleared up. At work we are making the move to
containers and really considering docker over lxc. We have a lot of old school
thought of we need to make a quick fix just ssh to the containers and make the
fix. This is all good as long as you make sure the change is done at the
container code level before its forgotten. So that the next build of the
container has those changes. Moving to Infrastructure as Code from
a Infrastructure with 500 physical machines is a hard concept for a lot of
people to get behind. It requires a whole different train of thought. You have
to forget the idea of oh I can just ssh to there and do what I need. This is
called system drift. Your system configuration management tool should be the
only thing making changes. This is what I call Infrastructure as Pseudo Code.

So how do we avoid drift in machines, or never having a machine at its
originally state ? Well this is where containers come in to play. You have the
host machine that is completely bare nothing more than what it needs to do its
job configured. Only services that should be installed are sshd, iscsi for
storage and nfs also for storage. Along with your container service of choice.
You only connect to the host when you want to get a container setup and
running.

So you probably wondering what about a development environment. Local
development is how it should be done. Your developers should be able to have
access to resources to stand up a small production environment on their
machines. This eliminates the need to have a VM in production for developers to
work from. Since our Infrastructure is code now, the developer can just do
something simple like using a docker compose file to stand up a web, cache,
search and db all in a few minutes.

This is a new way of thinking and it takes a lot of time to get people to see
that this style is how the industry is moving and to understand it. This is
a change that will not happen over night. If you grab some of your senior
developers and show them the process and how they can finally have a replica
environment that our clients have, this is priceless to them. Now they can
truly debug and aren't tied to a vpn connection or a local network connection.
