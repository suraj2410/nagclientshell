#!/bin/bash


echo -e "Nagios Client installation script in progress.
---------Please run this script on a newly installed/clean system"

read -p "Please enter the Nagios Monitoring server IP address" IP

if [ "$IP" == "" ];then
echo " You did not enter an IP address. Nagios client will only listen to localhost"
read -p "Do you wish to continue[Y/n]" wish
    case "$wish" in
	   Y | y | "")
	   echo "Proceeding further..."
	   ;;
	   
	   *)
	   echo "Installation cancelled.."
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

rpm -ivh $PKG > /dev/null 2>&1 && echo "epel rpm installed" || echo "looks like epel is already installed"


#Installing CentOS dependencies for the Nagios client

echo "Installing CentOS dependencies for the Nagios client"

yum -y install gcc glibc glibc-common xinetd >> $LOGFILE 2>&1



#Installing and configuring Nagios user and group

echo "Installing Nagios user and group"

useradd -m nagios > /dev/null 2>&1


#Compiling and installing Nagios Plugin

echo "Compiling and installing Nagios Plugin 2.1.2"

cd $PLUGINDIR

./configure &>> $LOGFILE && make &>> $LOGFILE  && make install &>> $LOGFILE

RESULT=$?

if [ $RESULT == 0 ];then
    echo "Plugin complied and installed successfully"
else
    echo "Plugin compilation and installation failed Please check $LOGFILE" && exit 1
fi

cd ..

echo "Changing file and directory ownerships"

chown nagios.nagios /usr/local/nagios

chown -R nagios.nagios /usr/local/nagios/libexec



#Installing NRPE Plugin 


cd $NRPEDIR

./configure &>> $LOGFILE && make all &>> $LOGFILE && make install-plugin &>> $LOGFILE && make install-daemon &>> $LOGFILE && make install-daemon-config &>> $LOGFILE && make install-xinetd &>> $LOGFILE

RESULT=$?

if [ $RESULT == 0 ];then
    echo "Plugin Installed successfully"
else
    echo "Plugin installation failed Please check $LOGFILE" && exit 1
fi

cd ..


# Inserting Nagios server IP to /xinedt conf file

if [ "$IP" -ne "" ];then

    sed -i "/only_from/ s/$/ $IP/" /etc/xinetd.d/nrpe
fi

echo "nrpe            5666/tcp                 NRPE" >> /etc/services

service xinetd restart
