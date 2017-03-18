#!/bin/bash


echo -e "Nagios Client installation script in progress.
---------Please run this script on a newly installed/clean system\n"

read -p "Please enter the Nagios Monitoring server IP address: " IP

if [ "$IP" == "" ];then
echo -e " You did not enter an IP address. Nagios client will only listen to localhost\n"
read -p "Do you wish to continue[Y/n]" wish
    case "$wish" in
	   Y | y | "")
	   echo -e "Proceeding further...\n"
	   ;;
	   
	   *)
	   echo -e "Installation cancelled..\n"
	   exit 0
	esac
fi

LOGFILE=/root/nagiosinstall.log

PKG="./package/epel-release-6-8.noarch.rpm"

PLUGINSDIR="./package/nagios-plugins-2.1.2"

NRPEDIR="./package/nrpe-2.15"

#Check if we have enough privileges


if [ $(id -u) -ne 0 ]; then
	echo "Run this script as a Root user only" >&2
	exit 1
fi



# Installing EPEL repository for CentOS 6

rpm -ivh $PKG > /dev/null 2>&1 && echo -e "epel rpm installed\n" || echo -e "looks like epel is already installed\n"


#Installing CentOS dependencies for the Nagios client

echo -e "Installing CentOS dependencies for the Nagios client\n"

yum -y install gcc glibc glibc-common xinetd >> $LOGFILE 2>&1



#Installing and configuring Nagios user and group

echo -e "Installing Nagios user and group\n"

useradd -m nagios > /dev/null 2>&1


#Compiling and installing Nagios Plugin

echo -e  "Compiling and installing Nagios Plugin 2.1.2\n"

cd $PLUGINSDIR

./configure &>> $LOGFILE && make &>> $LOGFILE  && make install &>> $LOGFILE

RESULT=$?

if [ $RESULT == 0 ];then
    echo -e "Plugin complied and installed successfully\n"
else
    echo -e "Plugin compilation and installation failed Please check $LOGFILE \n" && exit 1
fi

cd ../..

echo -e "Changing file and directory ownerships\n"

chown nagios.nagios /usr/local/nagios

chown -R nagios.nagios /usr/local/nagios/libexec



#Installing NRPE Plugin 

echo -e "Installing NRPE Plugin now...\n"

cd $NRPEDIR

./configure &>> $LOGFILE && make all &>> $LOGFILE && make install-plugin &>> $LOGFILE && make install-daemon &>> $LOGFILE && make install-daemon-config &>> $LOGFILE && make install-xinetd &>> $LOGFILE

RESULT=$?

if [ $RESULT == 0 ];then
    echo -e "Plugin Installed successfully\n"
else
    echo -e "Plugin installation failed Please check $LOGFILE\n" && exit 1
fi

cd ..


# Inserting Nagios server IP to /xinedt conf file

if [ ! -z "$IP" ];then

    sed -i "/only_from/ s/$/ $IP/" /etc/xinetd.d/nrpe
fi

echo "nrpe            5666/tcp                 NRPE" >> /etc/services

service xinetd restart

echo -e "Installation of Nagios Client successfully completed...\n"

echo -e "You may need to adjust the firewall rules to allow TCP port 5666"

