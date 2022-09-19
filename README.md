# PDDL Tools

Download and install all three tools (Fast Downward, Lab, and FF) by running the _AllToolsSetup.sh_ script in this repository. It is assumed that the script is being run in the home directory in your terminal.

```bash
wget -O - https://raw.githubusercontent.com/MagnusMat/Swarm-Robotics/master/Simulation/PDDL/AllToolsSetup.sh | bash
```

## PDDL

PDDL is an artificial intelligence planning language with the express purpose of standardizing other planning languages.

It is used in conjunction with a solver to create sequenced plans for the artificial intelligence.

PDDL is split into two parts, the domain and problems.
The domain consists of all actions, objects, constants and states possible and is generally meant to outline the possible actions and the objects for which the actions can affect.
While the domain is generic for everything in the domain, a problem is a specific scenario which we want a plan for.
If no plan can be found consider analysing step by step, utilizing actions from the domain, if the problem's goal can be achieved with the initial problem state.

### Setup

Download the [PDDL package](https://marketplace.visualstudio.com/items?itemName=jan-dolejsi.pddl) in Visual Studio Code.

Open both a Domain and a problem file and press ALT + P (or right click) to run the solver.

----

## Fast Downward Local Solver

You can use the [Fast Downward](https://www.fast-downward.org) solver locally. Use the command ```./fast-downward.py domain.pddl task.pddl --search "astar(lmcut())"``` to run the planner using the astar algorithm.

### Ubuntu 20.04

You can run the _FastDownwardSetup.sh_ script in this repository. It is assumed that the script is being run in the home directory in your terminal.

```bash
wget -O - https://raw.githubusercontent.com/MagnusMat/Swarm-Robotics/master/Simulation/PDDL/FastDownwardSetup.sh | bash
```

Otherwise, follow the instructions at [the Fast Downward documentation page](https://www.fast-downward.org/ObtainingAndRunningFastDownward).

For usage, please use ```./fast-downward.py --help```. For good known domains, please use ```./suites.py optimal_strips``` in the benchmarks folder.

<details>
  <summary>Windows setup</summary>

#### Dependency Requirements (Windows)

You need to install:

- Visual Studio >= 2017
- Python3
- Git
- Cmake

We recommend installing the Chocolatey package manager and then the packages through it. The following below is a PowerShell script:

```shell
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -recurse -Force -Confirm
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) -recurse -Force -Confirm

# Install Dependencies
choco install python -recurse -Force -Confirm
choco install git -recurse -Force -Confirm
choco install cmake --installargs 'ADD_CMAKE_TO_PATH=System' -recurse -Force -Confirm
```

#### Build

You need to download the [Downward](https://github.com/aibasel/downward.git) and [Benchmark](https://github.com/aibasel/downward-benchmarks.git) repos. I have added them to my D: drive as shown below.

```bash
# Install Fast Downward and benchmarks
git clone https://github.com/aibasel/downward.git "D:\Fast Downward"
git clone https://github.com/aibasel/downward-benchmarks.git "D:\Fast Downward\Benchmarks"
```

Then you need to access the Visual Studio Development Command Prompt in order to build the project. You can do this inside of Visual Studio by going to **Tools > Command Line > Developer Command Prompt** or by accessing Command Prompt and running the _VsDevCmd.bat_ file. It will be under your Visual Studio install folder and _\Common7\Tools\VsDevCmd.bat_. Note that, in Windows, all the Python scripts have to be prefaced with ```python3```.

Below is how i would access it on my machine, assuming you're still in PowerShell:

```bash
# Build project
cmd # Switch to cmd
"D:\Visual Studio 2022\Enterprise\Common7\Tools\VsDevCmd.bat"
python3 build.py
pwsh # Switch back to pwsh
```

For usage, please use ```python3 ./fast-downward.py --help```. For good known domains, please use ```python3 ./suites.py optimal_strips``` in the benchmarks folder.

</details>

----

## Lab Setup

[Downward Lab](https://lab.readthedocs.io/en/stable/index.html) facilitates running experiments for the Fast Downward planning system. Use the command ```./fd build 2 3 6 7``` to run the planner and build a report. It requires Linux and there is no Windows version.

### Ubuntu 20.04

You can run the _LabSetup_ script in this repository. It is assumed that the script is being run in the home directory in your terminal and that Fast Downward is installed.

```bash
wget -O - https://raw.githubusercontent.com/MagnusMat/Swarm-Robotics/master/Simulation/PDDL/LabSetup.sh | bash
```

Otherwise, follow the instructions at [the Lab documentation page](https://lab.readthedocs.io/en/stable/downward.tutorial.html).

## FF (Fast Forward) Planner Setup

You can use the [FF](https://fai.cs.uni-saarland.de/hoffmann/ff.html) planning system. Use the command ```./ff -o domain.pddl -f task.pddl``` to run the planner. It requires Linux and there is no Windows version.

### Ubuntu 20.04

You can run the _FFSetup.sh_ script in this repository. It is assumed that the script is being run in the home directory in your terminal and that Fast Downward and Lab is installed.

```bash
wget -O - https://raw.githubusercontent.com/MagnusMat/Swarm-Robotics/master/Simulation/PDDL/FFSetup.sh | bash
```

Otherwise, follow the instructions at [ai.mit.edu](http://www.ai.mit.edu/courses/16.412J/ff.html).
