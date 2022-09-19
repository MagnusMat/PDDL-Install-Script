#!/bin/bash

cd ~

# Update
sudo apt -y update; sudo apt -y upgrade

# Install dependencies
sudo apt-get -y install g++
sudo apt-get -y install git
sudo apt-get -y install make
sudo apt-get -y install python3
sudo snap install cmake --classic

sudo apt -y update; sudo apt -y upgrade

# Download Fast Downward and benchmarks
git clone https://github.com/aibasel/downward.git Fast-Downward
git clone https://github.com/aibasel/downward-benchmarks.git Fast-Downward/Benchmarks
cd Fast-Downward
./build.py
echo "For usage, please use './fast-downward.py --help'."
echo "For good known domains, please use './suites.py optimal_strips' in the benchmarks folder."
