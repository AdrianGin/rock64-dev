#Download docker image
FROM debian:stretch-slim

#environment variables
LABEL version="1.0"
LABEL vendor="Adrian.gin@gmail.com"
ENV USERNAME=rock64dev


ADD .bashrc /root/.bashrc

# setup multiarch enviroment
RUN dpkg --add-architecture arm64

RUN echo "deb http://deb.debian.org/debian stretch main contrib" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian stretch main contrib" >> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian stretch-updates main" >> /etc/apt/sources.list
RUN echo "deb-src http://security.debian.org stretch/updates main" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y sudo git net-tools vim #gcc-6-aarch64-linux-gnu device-tree-compiler make

RUN useradd -ms /bin/bash $USERNAME

RUN adduser $USERNAME sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USERNAME
USER $USERNAME

#add current directory to work DIR
#COPY . /home/$USERNAME
#No need to do this as the directory is mounted with the docker -v command


