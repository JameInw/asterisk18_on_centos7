#!/bin/bash

echo '############# Set SELinux in Permissive #############'

setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
getenforce
sestatus

echo '############# Install required Packages #############'

yum install -y epel-release dmidecode gcc-c++ ncurses-devel libxml2-devel make wget openssl-devel newt-devel kernel-devel sqlite-devel libuuid-devel gtk2-devel jansson-devel binutils-devel libedit libedit-devel wget
yum -y groupinstall "Development Tools"

echo '############# Install Jansson on CentOS 7 #############'

cd /usr/src/
git clone https://github.com/akheron/jansson.git
cd /usr/src/jansson
autoreconf  -i
./configure --prefix=/usr/
make
make install

echo '############# Install PJSIP on CentOS 7 #############'

cd /usr/src
wget https://github.com/pjsip/pjproject/archive/2.10.tar.gz
tar xvf 2.10.tar.gz
cd /usr/src/pjproject-2.10
./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr
make dep
make
make install
ldconfig
ldconfig -p | grep pj

echo '############# Install Asterisk 18 LTS on Centos 7 #############'

cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
tar xvf asterisk-18-current.tar.gz
cd /usr/src/asterisk-18.8.0
yum install svn
./contrib/scripts/get_mp3_source.sh
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-jansson-bundled
make menuselect
make
make install
make samples
make config
groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk.asterisk /usr/lib64/asterisk

sed -i 's/#AST_USER="asterisk"/AST_USER="asterisk"/g' /etc/sysconfig/asterisk
sed -i 's/#AST_GROUP="asterisk"/AST_GROUP="asterisk"/g' /etc/sysconfig/asterisk
sed -i 's/;runuser = asterisk/runuser = asterisk/g' /etc/asterisk/asterisk.conf 
sed -i 's/;rungroup = asterisk/rungroup = asterisk/g' /etc/asterisk/asterisk.conf

systemctl restart asterisk
systemctl status asterisk
systemctl enable asterisk