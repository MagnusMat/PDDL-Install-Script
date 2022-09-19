#!/bin/bash

cd ~

# Update
sudo apt -y update; sudo apt -y upgrade

# Install dependencies
sudo apt-get -y install g++
sudo apt-get -y install git
sudo apt-get -y install make
sudo apt-get -y install bison
sudo apt-get -y install flex
sudo apt-get -y install python3
sudo apt-get -y install python3-venv
sudo snap install cmake --classic

sudo apt -y update; sudo apt -y upgrade

# Download Fast Downward and benchmarks
git clone https://github.com/aibasel/downward.git Fast-Downward
git clone https://github.com/aibasel/downward-benchmarks.git Fast-Downward/Benchmarks
cd Fast-Downward
./build.py

# Create directory for holding binaries and scripts.
mkdir --parents ~/bin

# Install the plan validator VAL.
git clone https://github.com/KCL-Planning/VAL.git
cd VAL
# Newer VAL versions need time stamps, so we use an old version
# (https://github.com/KCL-Planning/VAL/issues/46).
git checkout a556539
make clean  # Remove old binaries.
sed -i 's/-Werror //g' Makefile  # Ignore warnings.
make
make tan
make parser
cp validate ~/bin/  # Add binary to a directory on your ``$PATH``.
# Return to projects directory.
cd ../

# Make directory for Lab
cd experiments
mkdir fd
cd fd

# Create and activate a Python 3 virtual environment for Lab.
python3 -m venv --prompt fd .venv
source .venv/bin/activate

# Install Lab in the virtual environment.
pip install -U pip wheel  # It's good to have new versions of these.

pip install lab  # or preferably a specific version with lab==x.y

# Store installed packages and exact versions for reproducibility.
# Ignore pkg-resources package (https://github.com/pypa/pip/issues/4022).
pip freeze | grep -v "pkg-resources" > requirements.txt
git add requirements.txt

pip install -r requirements.txt

# Add to path and aliases
if [[ ! -e /.bashrc ]]; then
    touch /.bashrc
fi

if [[ ! -e /.bash_aliases ]]; then
    touch /.bash_aliases
fi

# Add to path and aliases
wget https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/DownwardLab/.bashrc -O ->> /.bashrc
wget -O ->> /.bash_aliases https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/DownwardLab/.bash_aliases
source ~/.bashrc

# Create Fast Downward Lab files
wget -O fd.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/DownwardLab/fd.py
wget -O project.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/DownwardLab/project.py
wget -O parser.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/DownwardLab/parser.py
wget -O 01-evaluation.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/DownwardLab/01-evaluation.py

cd ../..

# Download and install FF Planner
wget https://fai.cs.uni-saarland.de/hoffmann/ff/Metric-FF.tgz
gunzip Metric-FF.tgz
tar -xvf Metric-FF.tar
mv Metric-FF FF

cd FF
make

# Create Lab Files
wget -O ~/ff-parser.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/FF/ff-parser.py
wget -O ~/ff.py https://raw.githubusercontent.com/MagnusMat/PDDL-Install-Script/main/FF/ff.py

# Cleanup
cd ..
rm -r Metric-FF.tar

# Instructions
echo "For Fast Downward usage, please use './fast-downward.py --help'."
echo "For good known domains, please use './suites.py optimal_strips' in the benchmarks folder."
echo 'Activate a Python Virtual Environment by running venv in directories containing a .venv subdirectory.'
echo 'Run Fast Downward experiments with the file fd.py build 2 3 6 7'
echo 'Run FF experiments with the file ff.py'
