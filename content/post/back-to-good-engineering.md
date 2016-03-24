+++
date = "2016-03-12T19:49:29-05:00"
draft = false
title = "back to good engineering"
author = "Richard Genthner"
comments = true
image = ""
menu = ""
share = true
slug = "good-engineer"
tags = ["engineer","chef","work"]
+++

### New Employment
To begin lets talk about my new employment. I'm working for a startup in St Paul. We are doing some really cool stuff with chef and vagrant on my team to manage
all of our infrastructure as we migrate from [linode](https://www.linode.com) to [Amazon AWS](https://aws.amazon.com).

### Good Engineering
So any company that is starting up these dates are all about the microservices. Piece of advice don't do microservices from the get go. Focus on just getting the application near prefect first then you can do a refactor break it down. Design your front seperate from your backend. So your main application should just be a api and then give that information to the designers and js developers. This is extremely important if you plan on doing a mobile application at somepoint. This will keep the functionality the same between the web ui and the mobile ui.

### Automation
When it comes your infrastucture automate everything from the begining. This helps scale but make sure that you write in such away that you not locked into a vendor. You should make the vendor pieces just be part of the abstract layer. This will help you launch your infra in aws, digitalocean or any other place. This will also help you create mockup environments for your developers to have mini labs on their local machines.


Heres to a good future and automating the world!
