#!/bin/bash

cd ~

# Update
sudo apt -y update; sudo apt -y upgrade

# Install dependencies
sudo add-apt-repository universe
sudo add-apt-repository multiverse
sudo add-apt-repository restricted

sudo apt-get -y install build-essential
sudo apt-get -y install lua5.2
sudo apt-get -y install lua5.2-dev
sudo apt-get -y install curl
sudo apt-get -y install git
sudo snap install cmake --classic
sudo snap install code --classic

# Update
sudo apt -y update; sudo apt -y upgrade

# Install ROS Noetic
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
sudo apt-get -y update
sudo apt-get -y install ros-noetic-desktop-full
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
source ~/.bashrc
sudo apt-get -y install python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool

# Update
sudo apt -y update; sudo apt -y upgrade

# Setup Swarm Robotics
cd Desktop
git clone https://github.com/MagnusMat/Swarm-Robotics/
cd Swarm-Robotics/Simulation/
mkdir build
cd build
cmake ..
make -j 7
cd external/bin
echo "To run the project, execute ./run_a_scene.sh scene3"
