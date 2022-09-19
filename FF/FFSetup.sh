#!/bin/bash

cd ~/Fast-Downward

# Download and install FF Planner
wget https://fai.cs.uni-saarland.de/hoffmann/ff/Metric-FF.tgz
gunzip Metric-FF.tgz
tar -xvf Metric-FF.tar
mv Metric-FF FF

cd FF
make

# Setup Lab Files
wget -O ~/ff-parser.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/FF/ff-parser.py
wget -O ~/ff.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/FF/ff.py

# Cleanup
cd ..
rm -r Metric-FF.tar

echo 'Run experiments with the file ff.py'
