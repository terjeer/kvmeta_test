#!/bin/bash

# Run "vagrant provision" to rerun this file via vagrant.

# exit on error
set -e

# "|| true" makes the command always exit "ok"
apt-get update || true
apt-get upgrade --force-yes -y || true


apt-get install --force-yes -y emacs

apt-get install --force-yes -y debhelper
apt-get install --force-yes -y autotools-dev debconf devscripts fakeroot build-essential 
apt-get install --force-yes -y lintian autoconf automake
apt-get install --force-yes -y libdbd-pg-perl libdbi-perl libperl5.18 
apt-get install --force-yes -y libperl-dev libdate-calc-perl 
apt-get install --force-yes -y postgresql 
apt-get install --force-yes -y less bzip2 
apt-get install --force-yes -y subversion


# sudo export LANGUAGE="en_US.UTF-8"
# sudo echo 'LANGUAGE="en_US.UTF-8"' >> /etc/default/locale
# sudo echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale
# . /etc/default/locale

# sudo -u kvalobs svn co https://svn.met.no/kvoss/kvalobs_metadata/trunk/src/ /metno/kvalobs/src/ || true
# 

# pg_createcluster --socketdir=/var/run/kvalobs --user=kvalobs 9.3 kvalobs


adduser --home /metno/kvalobs --shell /bin/bash kvalobs --disabled-password --quiet --gecos GECOS || true
sudo -u postgres createuser -sER kvalobs  || true
sudo -u kvalobs createdb --owner kvalobs kvalobs || true
sudo -u kvalobs createdb --owner kvalobs METNO || true
sudo -u kvalobs createdb --owner kvalobs PROJ || true
sudo -u kvalobs createdb --owner kvalobs SVV || true

sudo -u kvalobs mkdir -p /metno/kvalobs/src 

#sudo -u kvalobs svn co https://svn.met.no/kvoss/kvalobs/trunk/src/kvalobs_database/ /metno/kvalobs/src/kvalobs_database || true

#sudo -u kvalobs psql -f /metno/kvalobs/src/kvalobs_database/kvalobs_schema.sql || true
#sudo -u kvalobs psql -d METNO -f /metno/kvalobs/src/instance_tables.sql || true  
#sudo -u kvalobs psql -d PROJ  -f /metno/kvalobs/src/instance_tables.sql || true
#sudo -u kvalobs psql -d SVV   -f /metno/kvalobs/src/instance_tables.sql || true

#sudo apt-get install --force-yes -y libaio1

# sudo -u kvalobs svn co https://svn.met.no/kvoss_intern/kvmetadata/trunk/share/metadata/   /metno/kvalobs/kvmetadata
# sudo -u kvalobs svn co https://svn.met.no/kvoss_intern/kvmetadata_auto/   /metno/kvalobs/kvmetadata_auto

sudo mkdir -pv /usr/share/kvalobs/
sudo chgrp kvalobs /usr/share/kvalobs/
sudo chmod g+ws /usr/share/kvalobs/

sudo mkdir -pv /usr/share/kvalobs/metadata
sudo chown -R kvalobs:kvalobs /usr/share/kvalobs/metadata

# sudo -u kvalobs cp -puv /metno/kvalobs/kvmetadata_auto/station_param_auto/station_param_QC1-1.out /metno/kvalobs/kvmetadata/station_param/station_param_auto

# HUSK /etc/resolv.conf
#root@vagrant-ubuntu-trusty-64:~# cat /etc/resolv.conf
## Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
##     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
#nameserver 10.0.2.2
#search met.no oslo.dnmi.no
