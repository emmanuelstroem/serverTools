#!/bin/bash
export DEBIAN_FRONTEND="noninteractive"

# Uninstall old versions of Docker.
# The contents of /var/lib/docker/, including images, containers, volumes, and networks, are preserved
echo "==== Remove old Docker"
sudo apt-get remove docker docker-engine docker.io

# SETUP REPOSIROTY

# 1. Update the apt package index:
echo "==== Update packages"
sudo apt-get update

# 2. Install packages to allow apt to use a repository over HTTPS:
echo "==== Install Docker Dependencies"
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# 3. Add Docker’s official GPG key:
echo "==== Add docker GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# verify key fingerprint by searching for it
echo "==== Verify docker GPG key fingerprint"
sudo apt-key fingerprint 0EBFCD88

# 4. set up the stable repository
echo "==== Setup Docker Repository"
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"


# INSTALL DOCKER CE

# 1. Update the apt package index
echo "==== Update packages"
sudo apt-get update

# 2. Install the latest version of Docker CE
echo "==== Install docker-ce"
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
echo "==== Download docker-compose"
sudo curl -L https://github.com/docker/compose/releases/download/1.20.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

echo "==== Make docker-compose executable"
# 2. Apply executable permissions to the binary:
sudo chmod +x /usr/local/bin/docker-compose


# Uninstall docker-compose
# sudo rm /usr/local/bin/docker-compose