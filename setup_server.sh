#!/bin/bash
# This is the standard Mindvalley base install script by Gareth
# Other than this all that needs to be configured before running this script is /etc/hostname /etc/hosts to add the hostname and /etc/network/interfaces to add the LAN IP
# You can also add any relevant SSH keys for the particular server below if you wish
#
export DEBIAN_FRONTEND="noninteractive"

# command line arguments
if [ $# -gt 0 ]; then
    echo "Your command line contains $# arguments"
    username="$1"
    password="$2"
    ssh_key="$3"
else
    echo "Your command line contains no arguments"
	username="manu"
    password=".manu@L1n0de2017!"
    ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5BhQjg6WaR+0XDWPIXl8CErceSyGMhTUbZak1fA5wwvi8j2ax5CbF1CyWl7Rfd/tmz4lkPClrvhwgQiVNQ7T34en4ze1p9bZdh0BWdU2H2Cng6aUkWT+qQJNgiYR1que+ItTQcOzdzBZ2JCwxQsz1WRLSbdlnc3gXhjuGC4J2+TQk91osMcSONn/HuMRvpEGYUX+bZkatoxvwJx3Vtcl1awYHVOKa9c0js1QfNll3eUj35VUdwAIPaME56rD4QY6n3Io6iAN+yMG2bLayxEFoOIX+gkTxyw/UoMV0DW9DQmarvejTVjn8dnvnf8O7rwQLJuv2crNR1tm5f07i9QMz emmanuel@Emmanuels-MacBook-Pro.local"
fi

echo "======= Got Domain Name ============"
echo $username
echo $password

# Security measures for SSH
#
echo "=============== - Change ssh port to 20022 ==============="
# - Change ssh port to 20022
sed -i 's/Port 22/Port 20022/' /etc/ssh/sshd_config

echo "================ - Disallow root login ==============="
# - disallow root login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

echo "================ - Disallow Password Auth ==============="
# - disallow password auth
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config << EOF
AllowUsers $username
EOF


echo "================ CREATE USER ==============="

echo " ************* - Configure SSH Keys ==============="
# - configure SSH allowed keys
echo " ************* - Create Home Directory + .ssh Directory ****************"
mkdir -p /home/$username/.ssh

echo " ************* - Create Authorized Keys File ****************"
touch /home/$username/.ssh/authorized_keys

echo " ************* - Add SSH Keys ****************"
echo $ssh_key >> /home/$username/.ssh/authorized_keys

echo " ************* - Create User + Set Home Directory ****************"
useradd -d /home/$username $username -s /bin/bash

echo " ************* - Add User to sudo Group ****************"
usermod -aG sudo $username 

echo " ************* - Add sudo ability to User ****************"
# # - add sudo ability
echo "$username   ALL=NOPASSWD: ALL" >> /etc/sudoers

echo " ************* - Set Default Shell to /bin/bash ****************"
usermod -s /bin/bash $username

echo " ************* - $username chown -R  Permissions on Home Directory ****************"
chown -R $username:$username /home/$username/

echo " ************* - ROOT chown Permissions on Home Directory ****************"
chown root:root /home/$username

echo " ************* - Set Permissions on .ssh Directory to 700 ****************"
chmod 700 /home/$username/.ssh

echo " ************* - Set Permissions on Authorized Key File to 0644 ****************"
chmod 644 /home/$username/.ssh/authorized_keys

echo " ************* - Set Password for User $username ****************"
echo -e "$password\n$password\n" | sudo passwd $username

if [ $OSTYPE == "linux-gnu" ]; then
    echo "+++++++ Creating bashrc and profile files +++++"
    cp $HOME/.bashrc /home/$username/.bashrc
    cp $HOME/.profile /home/$username/.profile
fi

#
# Systems stuff

echo "================ - Install aptitude ==============="
# 16.04 onwards doesn't have aptitude by default
apt-get install -y aptitude

echo "================ - Update System Packages ==============="
# - upgrade all existing packages
apt-get -o Acquire::ForceIPv4=true update
# aptitude update && aptitude --assume-yes safe-upgrade -y
aptitude -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" upgrade

echo "================ - Install htop iftop iotop sysstat screen curl ntp ==============="
# - install base packages
aptitude install -y htop iftop iotop sysstat screen curl ntp

echo "================ - Enable Sysstat ==============="
# - enable sysstat
sed -i "s/ENABLED=\"false\"/ENABLED=\"true\"/" /etc/default/sysstat

echo "================ - Change Permissions on /etc/ and /var/ ==============="
if [ -d /var/www ]; then
    chmod 0755 -R /var/www
else
    mkdir /var/www
    chmod 0755 -R /var/www
fi

# echo "================ - Install Fail2Ban ==============="
# apt-get install -y fail2ban
#
# echo "================ - Install Sendmail ==============="
# apt-get install -y sendmail
#
# echo "================ - Configure Fail2Ban jail.local Settings ==============="
# cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#
# sed -i 's/backend = auto/backend = systemd/' /etc/fail2ban/jail.local

echo "================ - REBOOT ==============="
# Reboot - kinda obvious no?
# reboot
