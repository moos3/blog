+++
date = "2015-11-22T19:03:28-08:00"
draft = false
title = "django and docker"
comments = true
image = ""
menu = ""
share = true
slug = "django-and-docker"
tags = ["infrastructure", "docker", "containers"]
+++

This guide shows you how to setup a Django Application and development environment using Docker and Postgres.

#### 1. Install the Docker Toolbox
The first step is to install the [docker toolbox](https://docs.docker.com/installation/).

On this page, find your platform and run the installation. On a Mac, you'll be installing Docker, Docker Compose, and Docker Machine. Docker Machine will use a Linux Virtual Machine to actually run Docker.

#### 2. Docker Quickstart Terminal (Mac)
If you're using a Mac, you will want to start working with Docker by opening the Docker Quickstart Terminal. This will ensure that your environment is setup properly. Since Docker is actually running in a VM.

#### 3. Get familiar with Docker
For our Django app we are goign to build a custom Django image. There is a lot to learn about Docker images in the future, so you should definitely read up on them when your ready.

For this demo, you will want to create a directory to store all your files. I've created a directory called ~/build/django-docker. You can do this with:
```
mkdir -p ~/build/django-docker
```
and go to this directory
```
cd ~/build/django-docker
```
Now create a file in this directory called Dockerfile
```
vim Dockerfile
```
Add the following to the Dockerfile:
```
FROM python:2.7
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
RUN pip install -r requirements.txt
ADD . /code/
```

#### 4. Create your requirements.txt file
The requirements.txt file contains the python modules necessary to run your application. In this case when need to install Django and psycopg2 (postgres + python). The Dockerfile we created in the previous setup will install these required modules.
```
touch requirements.txt
```
And open this file to edit. Add the following:
```
django
psycopg2
```

#### 5. Create your docker-compose.yml file
```
touch docker-compose.yml
```

And open this file to edit. Add the following:
```
db:
  image: postgres
web:
  build: .
  command: python manage.py runserver 0.0.0.0:8000
  volumes:
    - .:/code
  ports:
    - "8000:8000"
  links:
    - db
```

#### 6. Create your Django project
You'll need to use the docker-compose run command to start your django project. Of course, if you've already got a project started this setup can be skipped. You might still find this helpful to read through.

In your docker-compose.yml file, we have specified the command we want to run as python manage.py runserver 0.0.0.0:8000. This is the command that will be run when we bring up our web container using docker-compose up. But before we can get to that point, we actually need a django project. To do this we will need to run a command against our web service using docker-compose run
```
docker-compose run web django-admin.py startproject exampleproject .
```

You may already be familiar with djangos startproject command, but when using Docker we will have to run this command inside the of our container. Once you run this command you can run ls -l and take a look at the file that were created in your current directory. You will see that your project was created and manage.py was added, but both are owned by root. This is because the container runs as root. You'll want to change the ownership by running sudo chown -R $USER:$USER .

#### 7. Configure Django to connect to the Database
Django's database settings are in the settings.py file located in your primary app directory ```examplepoject/settings.py``` Go ahead and open this file to edit.

Search for DATABASES and ensure the configuration looks like this:
```
DATABASE = {
  'default': {
    'ENGINE': 'django.db.backends.postgresql_psycopg2',
    'NAME': 'postgres',
    'USER': 'postgres',
    'HOST': 'db',
    'PORT': 5342
  }
}
```
Notice the hostname. If you look back at your docker-compose file, this is the name of the database service we'are creating. When we link the database container to the web container, we are able to access the container using the name of the service as the hostname.

#### 8. Run docker-compose up
At this point we're ready to take a look at our empty application. Run docker-compose up to start the django server.
```
docker-compose up
```
If you're on a Mac you'll need to grab the ip of your Docker virtual machine by running:
```
docker-machine ip default
```
otherwise you can use localhost. In my case the ip is 192.168.99.100. So open a browser and visit http://192.168.99.100:8000. Again if you look at the docker-compose file under the ports directive we are forwarding port 8000 from our container to port 8000 on our machine running docker.

#### 9. Add data persistence
For development, you may want to add a presistent data container. Whenever you start a new container from an image, you are starting completely fresh. That means when you start a new postgres container, it doesn't start with any data. You'll have to run migrations again, and you will have lost any data you my have added to some other container. This may seem odd at first, but in the end it's essential to the portability of containers. So in theory, we can create a data only container that will be mounted onto our postgres container.

To do this, lets first create an image called pg_data. To do this we will need to create another Dockerfile. I normally create a directory called docker to manage my docker-related files. So this is what I'l do, but you can put the file wherever you'd like:
```
mkdir -p docker/dockerfiles/pg_data
```
And then edit the file:
```
cd docker/dockerfiles/pg_data
vim Dockerfile
```
Add the following to the Dockerfile
```
FROM busybox
VOLUME /var/lib/postgresql
CMD ["true"]
```
Now save the file and go ahead and create the image:
```
docker build -t pg_data .
```
Finally, navigate back to the root directory of this app, and edit the docker-compose.yml file. Add the following to mount our data only container.
```
web:
  build: .
  command: python manage.py runserver 0.0.0.0:8000
  volumes:
    - .:/code
  ports:
    - "8000:8000"
  links:
    - db
db:
  image: postgres
  volumes_from:
    - pg_data
pg_data:
  image: pg_data
```
You'll see we added a pg_data service and we're mounting a data volume from pg_Data onto our db container. So now, as you develop and create data, as long as you mount this data only container to your future postgres containers you will have persistent data.

#### 10. Running tests
Running test is fairly straight forward. You can run a basic test using the docker-compose run command.
```
docker-compose run web python manage.py test
```
But what if you want to automate the test? I was recently inspired to automate a test in my deployment script. So when running my deployment script, I would first spin up a docker container, run tests, and if the tests pass I can continue with the deployment. Otherwise, we stop and fix the issues.

I create a test script:
```
#!/bin/bash
python manage.py test --noinput 2> /var/log/test.log 1> /dev/null

if [ $? -ne 0];then
  cat /var/log/test.log
  exit 1
fi
```
And then in my deployment script I added the following:
```
docker-compose run --rm web ./bin/test.sh

if [ $? -ne 0 ];then
  echo "Tests did not pass! Fix them!"
  exit 1
fi
```
The --rm flag removes teh containers immediately after they stop.
