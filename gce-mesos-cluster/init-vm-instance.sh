#!/bin/bash

function init_opt_boot
{
  gcsfuse mesos-shared /opt/shared
  chmod 644 /opt/shared
}

function install_opt_software
{
  echo "Not installed opt software, proceed install..."
  echo "INSTALL: mesos repo"
  apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
  DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  CODENAME=$(lsb_release -cs)
  echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | tee /etc/apt/sources.list.d/mesosphere.list

  echo "INSTALL: Java 8 from Oracle's PPA"
  add-apt-repository -y ppa:webupd8team/java
  apt-get update -y

  # install oracle-java8 package without prompt
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

  apt-get install -y oracle-java8-installer oracle-java8-set-default

  echo "INSTALL: gcsfuse - optional, using google storage to share installation packages."
  export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
  echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" | tee /etc/apt/sources.list.d/gcsfuse.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  apt-get update -y
  apt-get install -y gcsfuse
  mkdir -p /opt/shared
  
  apt-get install -y git

  echo "installed opt software done." > /root/opt-installed
  echo `date` >> /root/opt-installed
}

function install_opt_mesos_master
{
  echo "INSTALL: for master, install mesosphere"
  apt-get install -y mesosphere
}

function install_opt_mesos_slave
{
  echo "INSTALL: for slave, install mesos"
  apt-get install -y mesos
}

function install_opt_smack
{
  # cassandra
  mkdir -p /opt/cassandra
  mkdir -p /opt/disk/lssd/cax-data/commitlog
  mkdir -p /opt/disk/lssd/cax-data/data
  mkdir -p /opt/disk/lssd/cax-data/saved_caches
  
  cp /opt/shared/apache-cassandra-3.3-bin.tar.gz /opt/cassandra/
  cd /opt/cassandra/
  tar zxvf apache-cassandra-3.3-bin.tar.gz
  ln -s /opt/cassandra/apache-cassandra-3.3 /opt/cassandra/current
  echo 'export CASSANDRA_HOME="/opt/cassandra/current"' >> /etc/profile.d/cassandra.sh
  echo 'export PATH="$PATH:$CASSANDRA_HOME/bin"' >> /etc/profile.d/cassandra.sh
  chmod 755 /etc/profile.d/cassandra.sh
  cp -f /opt/shared/cassandra.yaml /opt/cassandra/current/conf/
  # set the 2 seeds' ip address in cassandra.yaml
  SEED_IP=`getent hosts mesos-slave-1 | awk '{ print $1 }'`; sed -i "s/seed1_ip_addr/$SEED_IP/g" /opt/cassandra/current/conf/cassandra.yaml
  SEED_IP=`getent hosts mesos-slave-2 | awk '{ print $1 }'`; sed -i "s/seed2_ip_addr/$SEED_IP/g" /opt/cassandra/current/conf/cassandra.yaml
  MY_IP=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`; sed -i "s/my_ip_address/$MY_IP/g" /opt/cassandra/current/conf/cassandra.yaml  

  # scala
  mkdir -p /opt/scala
  cp /opt/shared/scala-2.11.7.tgz /opt/scala/
  cd /opt/scala/
  tar zxvf scala-2.11.7.tgz
  ln -s /opt/scala/scala-2.11.7 /opt/scala/current
  echo 'export SCALA_HOME="/opt/scala/current"' >> /etc/profile.d/scala.sh
  echo 'export PATH="$PATH:$SCALA_HOME/bin"' >> /etc/profile.d/scala.sh
  chmod 755 /etc/profile.d/scala.sh

  # sbt
  mkdir -p /opt/sbt
  cp /opt/shared/sbt-0.13.9.tgz /opt/sbt/
  cd /opt/sbt/
  tar zxvf sbt-0.13.9.tgz
  mv /opt/sbt/sbt /opt/sbt/sbt-0.13.9
  ln -s /opt/sbt/sbt-0.13.9 /opt/sbt/current
  echo 'export SBT_HOME="/opt/sbt/current"' >> /etc/profile.d/scala.sh
  echo 'export PATH="$PATH:$SBT_HOME/bin"' >> /etc/profile.d/scala.sh
  # trigger sbt downloading
  # /opt/sbt/current/bin/sbt about
  
  # spark
  mkdir -p /opt/spark
  cp /opt/shared/spark-1.6.0-bin-hadoop2.6.tgz /opt/spark/
  cd /opt/spark/
  tar zxvf spark-1.6.0-bin-hadoop2.6.tgz
  ln -s /opt/spark/spark-1.6.0-bin-hadoop2.6 /opt/spark/current
  echo 'export SPARK_HOME="/opt/spark/current"' >> /etc/profile.d/spark.sh
  echo 'export PATH="$PATH:$SPARK_HOME/bin"' >> /etc/profile.d/spark.sh
  chmod 755 /etc/profile.d/spark.sh
  
}

function install_opt_mesosdns
{
  mkdir -p /opt/mesos-dns
  cp /opt/shared/mesos-dns-v0.5.1-linux-amd64 /opt/mesos-dns/
  chmod 755 /opt/mesos-dns/mesos-dns-v0.5.1-linux-amd64
  ln -s /opt/mesos-dns/mesos-dns-v0.5.1-linux-amd64 /opt/mesos-dns/mesos-dns
  cp /opt/shared/mesos-dns-config.json /opt/mesos-dns/
  MY_IP=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`; sed -i "s/listener_ip_addr/$MY_IP/g" /opt/mesos-dns/mesos-dns-config.json
}

function configure_zookeeper
{
  echo ${HOSTNAME##*-} > /etc/zookeeper/conf/myid
  echo "server.1=mesos-master-1:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
  echo "server.2=mesos-master-2:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
  echo "server.3=mesos-master-3:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
}

function configure_mesos_master
{
  echo "zk://mesos-master-1:2181,mesos-master-2:2181,mesos-master-3:2181/mesos" > /etc/mesos/zk
  
  # mesos-master
  echo 2 > /etc/mesos-master/quorum
  echo $HOSTNAME | tee /etc/mesos-master/hostname
  ifconfig eth0 | awk '/inet addr/{print substr($2,6)}' | tee /etc/mesos-master/ip
  
  # mesos-marathon
  mkdir -p /etc/marathon/conf
  echo $HOSTNAME | tee /etc/marathon/conf/hostname
  echo "zk://mesos-master-1:2181,mesos-master-2:2181,mesos-master-3:2181/mesos" | tee /etc/marathon/conf/master
  echo "zk://mesos-master-1:2181,mesos-master-2:2181,mesos-master-3:2181/marathon" | tee /etc/marathon/conf/zk
  
  # set boot service
  echo manual | sudo tee /etc/init/mesos-slave.override
  restart zookeeper
  start mesos-master
  start marathon
}

function configure_mesos_slave
{
  
  stop zookeeper
  echo manual | tee /etc/init/zookeeper.override
  stop mesos-master
  echo manual | tee /etc/init/mesos-master.override
  
  echo "zk://mesos-master-1:2181,mesos-master-2:2181,mesos-master-3:2181/mesos" > /etc/mesos/zk
  ifconfig eth0 | awk '/inet addr/{print substr($2,6)}' | tee /etc/mesos-slave/ip
  echo $HOSTNAME | tee /etc/mesos-slave/hostname
  
  start mesos-slave
}

function configure_slave_os
{
  # format & mount local-ssd
  mkfs.ext4 -F /dev/disk/by-id/google-local-ssd-0 
  mkdir -p /opt/disk/lssd
  mount -o discard,defaults /dev/disk/by-id/google-local-ssd-0 /opt/disk/lssd
  
  # adjust os parameters
  echo 8 > /sys/class/block/sdb/queue/read_ahead_kb
  echo "root - memlock unlimited" | tee -a /etc/security/limits.conf
  echo "root - nofile 100000" | tee -a /etc/security/limits.conf
  echo "root - nproc 32768" | tee -a /etc/security/limits.conf
  echo "root - as unlimited" | tee -a /etc/security/limits.conf
  echo "vm.max_map_count = 131072" | tee -a /etc/sysctl.conf
  sysctl -p

  # check the cax process limits: 
  # cat /proc/<pid>/limits
  
}

if [ -f "/root/opt-installed" ]; then
  echo "installed opt software."
  init_opt_boot
elif [[ $HOSTNAME == *"master"* ]]; then
  echo "install for role:master"
  install_opt_software
  install_opt_mesos_master
  init_opt_boot
  configure_zookeeper
  configure_mesos_master
  install_opt_mesosdns

  install_opt_smack
elif [[ $HOSTNAME == *"slave"* ]]; then
  echo "install for role:slave"
  configure_slave_os
  install_opt_software
  install_opt_mesos_slave
  init_opt_boot
  configure_mesos_slave
  install_opt_mesosdns
  
  install_opt_smack
else
  echo "please use a hostname like: mesos-master-1 or mesos-slave-1"
fi
