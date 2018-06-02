#Download docker image
FROM debian:stretch-slim

#environment variables
LABEL version="1.0"
LABEL vendor="Adrian.gin@gmail.com"
ENV USERNAME=rock64dev


#ADD .bashrc /root/.bashrc

# setup multiarch enviroment
#RUN dpkg --add-architecture arm64

RUN echo "deb http://deb.debian.org/debian stretch contrib" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian stretch main contrib" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian stretch-updates main" >> /etc/apt/sources.list
RUN echo "deb-src http://security.debian.org stretch/updates main" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y sudo git net-tools vim file python bc gcc gcc-aarch64-linux-gnu make device-tree-compiler libncurses5-dev swig libpython-dev gawk parted udev dosfstools mtools time kmod

#For build-root
RUN apt-get update && apt-get install -y wget cpio g++ unzip locales

#RUN apt-get update && apt-get install -y gcc:arm64 device-tree-compiler:arm64 make:arm64


RUN useradd -ms /bin/bash $USERNAME

RUN adduser $USERNAME sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USERNAME
USER $USERNAME

#add current directory to work DIR
#COPY . /home/$USERNAME
#No need to do this as the directory is mounted with the docker -v command

RUN sudo bash -c "echo en_NZ.UTF-8 UTF-8 >> /etc/locale.gen"
RUN sudo locale-gen


#set environment to use aarch64
RUN sudo ln -s /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 /lib/
#ENV LD_LIBRARY_PATH=/usr/aarch64-linux-gnu/lib:$LD_LIBRARY_PATH


