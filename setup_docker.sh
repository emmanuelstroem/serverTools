#!/bin/bash
export DEBIAN_FRONTEND="noninteractive"

# Uninstall old versions of Docker.
# The contents of /var/lib/docker/, including images, containers, volumes, and networks, are preserved
sudo apt-get remove docker docker-engine docker.io

# SETUP REPOSIROTY

# 1. Update the apt package index:
sudo apt-get update

# 2. Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# 3. Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# verify key fingerprint by searching for it
sudo apt-key fingerprint 0EBFCD88

# 4. set up the stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"


# INSTALL DOCKER CE

# 1. Update the apt package index
sudo apt-get update

# 2. Install the latest version of Docker CE
sudo apt-get install docker-ce

# or install a specific version in production
#  sudo apt-get install docker-ce=18.03.0

# Upgrade docker with command
# sudo apt-get update

# Uninstall Docker-CE
# sudo apt-get purge docker-ce

# Remove images, volumes and other configs 
# sudo rm -rf /var/lib/docker


# INSTALL COMPOSER

# 1.  Download the latest version of Docker Compose
sudo curl -L https://github.com/docker/compose/releases/download/1.20.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

# 2. Apply executable permissions to the binary:
sudo chmod +x /usr/local/bin/docker-compose


# Uninstall docker-compose
# sudo rm /usr/local/bin/docker-compose