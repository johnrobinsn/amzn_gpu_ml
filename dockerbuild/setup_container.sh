#!/bin/bash

# =====================================
# John Robinson 2017
#
# multipathnet
# https://github.com/facebookresearch/multipathnet
# docker container setup script
# assumes nvidia/cuda:7.5-devel docker base

# Manually invoke container for this script using
# nvidia-docker run -it nvidia/cuda:7.5-devel

# nvidia-docker run -it -p 80:80 johnrobinsn/mp bash

# Manually invoke container to autostart apache for this script using
# http://slopjong.de/2014/09/17/install-and-run-a-web-server-in-a-docker-container/
# nvidia-docker run -d -p 80:80 johnrobinsn/mp /usr/sbin/apache2ctl -D FOREGROUND
# Connect to running container
# docker exec -it <mycontainer> bash

# =====================================
sudo apt -y update
sudo apt-get -y install python2.7-dev
sudo apt-get -y install python-pip
sudo pip install numpy
sudo apt-get -y install libboost-all-dev
sudo apt-get -y install git
sudo apt-get -y install automake
sudo apt-get -y install wget
sudo apt-get -y install unzip

# Optional... I use emacs
sudo apt-get -y install emacs

# =====================================
# Install glog
cd ~
wget https://github.com/google/glog/archive/v0.3.3.zip
unzip v0.3.3.zip
cd glog-0.3.3/
./configure
make
sudo make install

# =====================================
# Install torch
cd ~
git clone https://github.com/torch/distro.git ~/torch --recursive
cd ~/torch
bash install-deps
./install.sh -b
. ~/torch/install/bin/torch-activate

luarocks install inn
luarocks install torchnet

# =====================================
# Install thpp
# Work around an issue with fbpython by building THPP separately at a
# specific revision
# Read More: https://github.com/facebook/fblualib/issues/84
# https://github.com/facebook/thpp

cd ~
git clone https://github.com/facebook/thpp.git
cd thpp
git checkout d358a52
cd thpp
THPP_NOFB=1 ./build.sh
cd ~

# =====================================

luarocks install fbpython

luarocks install class
luarocks install optnet

# https://github.com/torch/sys  
luarocks install sys


# =====================================
# Install COCO

cd ~
git clone https://github.com/pdollar/coco.git
cd coco
luarocks make LuaAPI/rocks/coco-scm-1.rockspec

pip install cython
cd PythonAPI
make
export PYTHONPATH=$PYTHONPATH:~/coco/PythonAPI
cd ~

# =====================================
# Install nVidia CUDA

cd ~
wget http://developer.download.nvidia.com/compute/redist/cudnn/v5.1/cudnn-7.5-linux-x64-v5.1.tgz
tar xvf cudnn-7.5-linux-x64-v5.1.tgz
cd cuda/lib64
export LD_LIBRARY_PATH=`pwd`:$LD_LIBRARY_PATH

# =====================================
# Install Multipathnet
# https://github.com/facebookresearch/multipathnet

cd ~
git clone https://github.com/facebookresearch/multipathnet.git

# =====================================
# Install apache
sudo apt-get -y install apache2
sudo service apache2 start


cd /tmp
wget http://mscoco.org/static/annotations/PASCAL_VOC.zip
wget http://mscoco.org/static/annotations/ILSVRC2014.zip
wget http://msvocds.blob.core.windows.net/annotations-1-0-3/instances_train-val2014.zip

export MPROOT=~/multipathnet
mkdir -p $MPROOT/data/annotations
cd $MPROOT/data/annotations
unzip -j /tmp/PASCAL_VOC.zip
unzip -j /tmp/ILSVRC2014.zip
unzip -j /tmp/instances_train-val2014.zip

mkdir -p $MPROOT/data/proposals/VOC2007/selective_search
cd $MPROOT/data/proposals/VOC2007/selective_search
wget https://s3.amazonaws.com/multipathnet/proposals/VOC2007/selective_search/train.t7
wget https://s3.amazonaws.com/multipathnet/proposals/VOC2007/selective_search/val.t7
wget https://s3.amazonaws.com/multipathnet/proposals/VOC2007/selective_search/trainval.t7
wget https://s3.amazonaws.com/multipathnet/proposals/VOC2007/selective_search/test.t7

mkdir -p $MPROOT/data/proposals/coco/sharpmask
cd $MPROOT/data/proposals/coco/sharpmask
wget https://s3.amazonaws.com/multipathnet/proposals/coco/sharpmask/train.t7
wget https://s3.amazonaws.com/multipathnet/proposals/coco/sharpmask/val.t7

mkdir -p $MPROOT/data/models
cd $MPROOT/data/models
wget https://s3.amazonaws.com/multipathnet/models/imagenet_pretrained_alexnet.t7
wget https://s3.amazonaws.com/multipathnet/models/imagenet_pretrained_vgg.t7
wget https://s3.amazonaws.com/multipathnet/models/vgg16_fast_rcnn_iter_40000.t7
wget https://s3.amazonaws.com/multipathnet/models/caffenet_fast_rcnn_iter_40000.t7

if [ ! -f ~/multipathnet/config.lua.backup ]; then
  cp ~/multipathnet/config.lua ~/multipathnet/config.lua.backup
fi

echo "
-- put your paths to VOC and COCO containing subfolders with images here
local VOCdevkit = '$MPROOT/data/proposals'
local coco_dir = '$MPROOT/data/proposals/coco'
return {
   pascal_train2007 = paths.concat(VOCdevkit, 'VOC2007/selective_search'),
   pascal_val2007 = paths.concat(VOCdevkit, 'VOC2007/selective_search'),
   pascal_test2007 = paths.concat(VOCdevkit, 'VOC2007/selective_search'),
   pascal_train2012 = paths.concat(VOCdevkit, 'VOC2007/selective_search'),
   pascal_val2012 = paths.concat(VOCdevkit, 'VOC2007/selective_search'),
   pascal_test2012 = paths.concat(VOCdevkit, 'VOC2007/selective_search'),
   coco_train2014 = paths.concat(coco_dir, 'sharpmask'),
   coco_val2014 = paths.concat(coco_dir, 'sharpmask'),
}" > ~/multipathnet/config.lua

cd $MPROOT
git clone https://github.com/facebookresearch/deepmask.git

cd $MPROOT/data/models
# download SharpMask based on ResNet-50
wget https://s3.amazonaws.com/deepmask/models/sharpmask/model.t7 -O sharpmask.t7
wget https://s3.amazonaws.com/multipathnet/models/resnet18_integral_coco.t7

echo
echo 'Add the following to your .bashrc:
export PYTHONPATH=~/coco/PythonAPI
export LD_LIBRARY_PATH=~/cuda/lib64:$LD_LIBRARY_PATH'

echo "export PYTHONPATH=~/coco/PythonAPI" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=~/cuda/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc


# Test multipathnet with
# MP=/root/multipathnet
# cd $MP
# th demo.lua -img ./deepmask/data/testImage.jpg

DEEPMASK=/root/deepmask
git clone https://github.com/facebookresearch/deepmask.git $DEEPMASK
mkdir -p $DEEPMASK/pretrained/deepmask; cd $DEEPMASK/pretrained/deepmask
wget https://s3.amazonaws.com/deepmask/models/deepmask/model.t7
mkdir -p $DEEPMASK/pretrained/sharpmask; cd $DEEPMASK/pretrained/sharpmask
wget https://s3.amazonaws.com/deepmask/models/sharpmask/model.t7

# test deepmask with 
# DEEPMASK=/root/deepmask
# th computeProposals.lua $DEEPMASK/pretrained/sharpmask -img data/testImage.jpg

# =====================================
# Install apache

sudo apt-get -y install apache2
#sudo update-rc.d apache2 enable
#sudo system apache2 start

# =====================================
# Install php
sudo apt-get -y install php5 libapache2-mod-php5 php5-mcrypt

CMD /bin/bash

