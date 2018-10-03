# docker-lb-wordpress
1. [for-development](#for-dev)

2. [for-production](#for-production)

## for-development
### 1. Clone Repository

make sure your "**GIT**" command already installed and using "**git clone**" to download this repository

**Clone this repository "git clone":**
```bash
$ git clone https://github.com/Busthomi/docker-lb-wordpress.git
$ cd docker-lb-wordpress/
```

This repository has few file, if we want to using on development we can using **docker-compose.yml**
Code below are containing **MYSQL** and **WORDPRESS** with original file from wordpress image repository.

How to run this config?
- Make sure you are in repository folder and you can see **docker-compose.yml** file
```bash
cd docker-lb-wordpress/
ls
```
- Run docker compose command to get mysql and wordpress images then automatically run the images
this command to running docker compose with detach running container
```bash
docker-compose up -d
```
- Make sure application can run and check with this command
```bash
docker ps 
```

If your Container already Running you can check the website with on your browser.
```
http://localhost/
```
You can see you container are running with detail expose port and which images version

YML file using mysql image version 5.7, expose standard port 3306 and we can using custom environtment.
In here we already configure for MYSQL Root Password, Create Database, Create New User and User Password.

```bash
version: '3.3'

services:
   db:
     image: mysql:5.7
     ports:
       - "3306:3306"
     volumes:
       - db_data:/var/lib/mysql
     restart: always
     environment:
       MYSQL_ROOT_PASSWORD: secret
       MYSQL_DATABASE: wordpress
       MYSQL_USER: wordpress
       MYSQL_PASSWORD: secret

   wordpress:
     depends_on:
       - db
     image: wordpress:latest
     ports:
       - "80:80"
     restart: always
     environment:
       WORDPRESS_DB_HOST: db:3306
       WORDPRESS_DB_USER: root
       WORDPRESS_DB_PASSWORD: secret
volumes:
    db_data:
```

## for-production

Using nginx for Load Balancer and traffic will be forwarding to upstream URL.
If we are using **docker-compose.yml** on above it is not fit for scale so we need more container to handle huge process.
In this part we are using **NGINX** as a locabalancer. So, nginx can forward the traffic to the upstream server, because we try to handle the traffic with Multiple Upstream Server. 

- First of all we need to build nginx load balancer images with below code, but before it we need to make sure our nginx config **www.conf**.
```bash
docker build -t lb:1.0.0
```
build nginx loadbalancer with name **lb** following the version **1.0.0**. You can build with your own name and version.
In this part we are using **php:7.1.22-fpm** images to handle our LoadBalancer and if you want to running PHP with this images it's already installed inside this images. Dockerfile will be running update images OS, installing dependencies, set Timezone to singapore and copying file to the container. The 2 last line there it command to running php and nginx services then will be expose container port to public.

```bash
FROM php:7.1.22-fpm

RUN apt-get update
RUN apt-get install -y nginx curl telnet zip unzip

ENV TZ=Asia/Singapore
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


ADD . /home/web/app
WORKDIR /home/web/app

COPY www.conf /etc/nginx/sites-available/default


CMD php-fpm -D && nginx -g 'daemon off;'
EXPOSE 80
```

Nginx config define upstream connection, which it will be forwarding the traffic to the multiple container define on the URL.
You can add, edit or remove server URL based on your wordpres container on you system.
```bash
upstream backend  {
  server 192.168.1.106:8000;
  server 192.168.1.106:8080;
}

server {
	listen 80 default_server;

	root /var/www/html;

	# Add index.php to the list if you are using PHP
	index index.php ndex.html index.htm index.nginx-debian.html;

	server_name shopee.id;

	location / {
		proxy_pass http://backend;
		proxy_http_version 1.1;
	        proxy_set_header Upgrade $http_upgrade;
	        proxy_set_header Connection 'upgrade';
	        proxy_set_header Host $host;
	        proxy_cache_bypass $http_upgrade;
		#try_files $uri $uri/ /index.php?$query_string;
	}

}
```

## Wordpress Server

You can running wordpress container directly without any configuration. But if you want to the same website, you need to build wordpress images as a Master. This code only allow you to build by default images and if you are running wordpress container like this, you need to configure each server to connecting to your database.
```bash
docker run -p 8000:80 -d wordpress:latest
docker run -p 8080:80 -d wordpress:latest
```

## Database Server

If you want to trying your database on container, you can run this command and your database will be running on container.
This code will configure you images with expose port to 3306, Root Password, Create Database, Create New User and Create New User Password.

```bash
version: '3.3'

services:
   db:
     image: mysql:5.7
     ports:
       - "3306:3306"
     volumes:
       - db_data:/var/lib/mysql
     restart: always
     environment:
       MYSQL_ROOT_PASSWORD: secret
       MYSQL_DATABASE: wordpress
       MYSQL_USER: wordpress
       MYSQL_PASSWORD: secret
volumes:
    db_data:
```

## BONUS

I was crate a Makefile to for Deployment ECS Container on AWS.
Need to some credential if you want to create container until registered on you Balancer.

```bash
cd ecs-script
cat Makefile
```
