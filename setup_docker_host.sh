#!/bin/bash

# =====================================
# Amazon Linux AMI with NVIDIA GRID and TESLA GPU Driver
# https://aws.amazon.com/marketplace/pp/B00FYCDDTE
# nvidia 7.5 drivers 1/28/2017
# 200GB volume
# Add port 80 to security group

# =====================================
# Install docker
# http://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html


# Install a few utilities
sudo yum update -y
sudo yum install -y docker

sudo yum install -y git    #optional
sudo yum -y install tmux   #optional
sudo yum -y install htop   #optional
sudo yum -y install emacs  #optional

# To increase default docker container limit from 10G to 30G
# edit /etc/sysconfig/docker-storage
# DOCKER_STORAGE_OPTIONS="--storage-opt dm.basesize=30G"

sudo service docker start

# Add this user to the docker group to let us run docker as non-root
sudo usermod -a -G docker ec2-user
# You'll need log out and back in to get new permissions

# =====================================
# Install nvidia-docker
# https://github.com/NVIDIA/nvidia-docker
# Other distributions

# Install nvidia-docker and nvidia-docker-plugin
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.0/nvidia-docker_1.0.0_amd64.tar.xz
sudo tar --strip-components=1 -C /usr/bin -xvf /tmp/nvidia-docker*.tar.xz && rm /tmp/nvidia-docker*.tar.xz

# Run nvidia-docker-plugin
#sudo -b nohup nvidia-docker-plugin > /tmp/nvidia-docker.log

# Test nvidia-smi with this command
#   Note: nvidia 7.5 drivers so use appropriate tag (devel for cuda dev bits)
#   Note: https://hub.docker.com/r/nvidia/cuda/
# nvidia-docker run --rm nvidia/cuda:7.5-devel nvidia-smi

# =====================================
# Setup up the nvidia-docker-plugin to autostart
# https://ruk.si/notes/servers/aws_nvidia_docker_setup

# stupid shell tricks
sudo tee "/etc/rc.d/init.d/nvidia-docker" > /dev/null <<'EOF'
#!/bin/sh
#
# chkconfig: 345 80 20
# description: NVIDIA Docker plugin.

. /etc/rc.d/init.d/functions

name="nvidia-docker"
cmd="nohup /usr/bin/nvidia-docker-plugin > /tmp/nvidia-docker.log"

RETVAL=0

start() {
    echo "Starting $name"
    daemon $cmd &
    RETVAL=$?
    return $RETVAL
}

stop() {
    echo "Stopping $name"
    kill `pidof nvidia-docker-plugin`
    RETVAL=$?
    return $RETVAL
}

case "$1" in
    start)
        start
        ;;

    stop)
        stop
        ;;

    restart)
        stop
        start
        ;;
esac

exit $RETVAL
EOF

sudo chkconfig --add nvidia-docker
sudo chkconfig --levels 0123456 nvidia-docker off
sudo chkconfig --levels 345 nvidia-docker on
chkconfig --list nvidia-docker
sudo chmod +x /etc/rc.d/init.d/nvidia-docker


# Start the nvidia-docker-plugin
sudo service nvidia-docker start
