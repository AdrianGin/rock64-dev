
#Download docker image
FROM debian:stretch-slim

MAINTAINER Adrian Gin "Adrian.gin@gmail.com"

ADD .bashrc /root/.bashrc

# setup multiarch enviroment
RUN dpkg --add-architecture arm64

RUN echo "deb-src http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian stretch-updates main" >> /etc/apt/sources.list
RUN echo "deb-src http://security.debian.org stretch/updates main" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y sudo git net-tools vim gcc-6-aarch64-linux-gnu device-tree-compiler

RUN useradd -ms /bin/bash rock64dev
WORKDIR /home/rock64dev
USER rock64dev
