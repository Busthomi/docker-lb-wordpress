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
