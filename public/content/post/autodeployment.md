+++
author = "Richard Genthner"
comments = true
date = "2015-07-13T17:06:44-04:00"
draft = false
image = ""
menu = ""
share = true
slug = "autodeployment-using-rabbitmq"
tags = ["rabbitmq", "ci","deployment"]
title = "Auto Deployment using PHP and rabbitmq"

+++
So for work for the past 3 weeks we took part of the 18F BPA contest for the US Government. I was tasked with building a docker setup that when [codeship](http://codeship.com) completed testing and building that it would automatically updated containers local code.
So I did this with a rabbitmq server using exchange queues. So the way this worked is this codeship would build the code, run all the test, push the update to a production branch. The way codeships webhook system works is this, it hits the end point every step. So this means we have
to listen for a status of success in order to make our nodes update. The webhook end in codeship points to a url for the site. Which checks the API key for the arbeider end point, codeship project id and for the message. This was a quick and dirty way to do it with out getting super complex.
Once the security stuff passes then we pop a json object in the rabbitmq exchange. The object looks like this
```
{
  "worker-api":"lknas0d9ni1ipnd0icqnd1",
  "git-command":"update"
}
```
As you can see in this object we pass along the worker api key. Every node will check this key, if it matches whats on their end then they will execute the git-command. In the case of our project we just run a update.sh script on the docker container, that checks the code out and makes sure the branch is correct.
I know your saying well your sending that in plain text. Yes I'm aware, if I was actually doing this in a production environment, that object would have been SHA-256 encrypted and the rabbitmq exchange would have encrypted also. Since this was just a proof of concept we choose to do it quickly. As we originally only had
one week to do this in.

The flow of the application is this:
![Image of the Workflow](/images/workers-diagram.png)

As you can see its extremely simple. It can be extended to do a lot more, such as sending singals to services to all nodes, or individal nodes. I'm hoping in my next revision that I will be able to get moving these to classes instead of random structured functions. Please contribute back to it and feel free to use it as a base for what you need in your environment. 
