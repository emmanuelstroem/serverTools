#!/bin/bash
# This is the standard Mindvalley base install script by Gareth
# Other than this all that needs to be configured before running this script is /etc/hostname /etc/hosts to add the hostname and /etc/network/interfaces to add the LAN IP
# You can also add any relevant SSH keys for the particular server below if you wish
#
export DEBIAN_FRONTEND="noninteractive"

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
cat >> /etc/ssh/sshd_config << EOF
PasswordAuthentication no
AllowUsers manu
EOF

# Add user etc
echo "================ - Add User (manu) ==============="
# - add manu user & set base permissions
echo "manu:manu:1000:1000::/home/manu:/bin/bash" | newusers
cp -a /etc/skel/.[a-z]* /home/manu/
chown -R manu:www-data /home/manu/

echo "================ - Add User to SUDOERS ==============="
# add user to sudoers
usermod -aG sudo manu

echo "================ - Add sudo ability to User ==============="
# - add sudo ability
echo "manu   ALL=NOPASSWD: ALL" >> /etc/sudoers

echo "================ - Configure SSH Keys ==============="
# - configure SSH allowed keys
mkdir /home/manu/.ssh
chmod -R 600 /home/manu/.ssh/
touch /home/manu/.ssh/authorized_keys
cat > /home/manu/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5BhQjg6WaR+0XDWPIXl8CErceSyGMhTUbZak1fA5wwvi8j2ax5CbF1CyWl7Rfd/tmz4lkPClrvhwgQiVNQ7T34en4ze1p9bZdh0BWdU2H2Cng6aUkWT+qQJNgiYR1que+ItTQcOzdzBZ2JCwxQsz1WRLSbdlnc3gXhjuGC4J2+TQk91osMcSONn/HuMRvpEGYUX+bZkatoxvwJx3Vtcl1awYHVOKa9c0js1QfNll3eUj35VUdwAIPaME56rD4QY6n3Io6iAN+yMG2bLayxEFoOIX+gkTxyw/UoMV0DW9DQmarvejTVjn8dnvnf8O7rwQLJuv2crNR1tm5f07i9QMz emmanuel@Emmanuels-MacBook-Pro.local
EOF

echo "================ - Set correct SSH file Permissions ==============="
# - set correct SSH file permissions
/etc/init.d/ssh restart
chown -R manu /home/manu/
chmod 700 /home/manu/.ssh
chmod 600 /home/manu/.ssh/authorized_keys

# Systems stuff

echo "================ - Install aptitude ==============="
# 16.04 onwards doesn't have aptitude by default
apt-get install -y aptitude

echo "================ - Update System Packages ==============="
# - upgrade all existing packages
apt update && apt upgrade -y
# aptitude safe-upgrade -y

echo "================ - Install htop iftop iotop sysstat screen curl ntp ==============="
# - install base packages
apt-get install -y htop iftop iotop sysstat screen curl ntp

echo "================ - Enable Sysstat ==============="
# - enable sysstat
sed -i "s/ENABLED=\"false\"/ENABLED=\"true\"/" /etc/default/sysstat

echo "================ - Add Secure User Password ==============="
# - add secure manu password
# echo -e 'manuL1n0de2017!' | sudo passwd manu

# The end - remove script
# rm /root/install.sh

echo "================ - REBOOT ==============="
# Reboot - kinda obvious no?
reboot now
