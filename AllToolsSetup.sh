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
git clone https://github.com/aibasel/downward.git Desktop/Fast-Downward
git clone https://github.com/aibasel/downward-benchmarks.git Desktop/Fast-Downward/Benchmarks
cd Desktop/Fast-Downward
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
printf "\n# Make executables in ~/bin directory available globally.\nexport PATH=\"\${PATH}:\${HOME}/bin\"\n# Some example experiments need these two environment variables.\nexport DOWNWARD_BENCHMARKS=\${HOME}/Desktop/Fast-Downward/Benchmarks\nexport DOWNWARD_REPO=\${HOME}/Desktop/Fast-Downward\nexport SIMULATION_PDDL=\${HOME}/Desktop/Swarm-Robotics/Simulation/PDDL\n" >> ~/.bashrc
printf "\n# Activate virtualenv and unset PYTHONPATH to obtain isolated virtual environments.\nalias venv=\"unset PYTHONPATH; source .venv/bin/activate\"" >> ~/.bash_aliases

source ~/.bashrc

# Create Fast Downward Lab files
touch fd.py
touch project.py
touch parser.py
touch 01-evaluation.py

printf "#! /usr/bin/env python\n\nimport os\nimport shutil\n\nimport project\n\n\nREPO = project.get_repo_base()\nBENCHMARKS_DIR = os.environ[\"DOWNWARD_BENCHMARKS\"]\nDOWNWARD_REPO = os.environ[\"DOWNWARD_REPO\"]\nSIMULATION_DIR = os.environ[\"SIMULATION_PDDL\"]\nSCP_LOGIN = \"myname@myserver.com\"\nREMOTE_REPOS_DIR = \"/infai/seipp/projects\"\nif project.REMOTE:\n    SUITE = project.SUITE_SATISFICING\n    ENV = project.BaselSlurmEnvironment(email=\"my.name@myhost.ch\")\nelse:\n    SUITE = [\"depot:p01.pddl\", \"grid:prob01.pddl\",\n             \"gripper:prob01.pddl\", \"airport:p01-airport1-p1.pddl\"]\n    ENV = project.LocalEnvironment(processes=2)\n\nrev = \"main\"\nATTRIBUTES = [\n    \"error\",\n    \"run_dir\",\n    \"search_start_time\",\n    \"search_start_memory\",\n    \"total_time\",\n    \"h_values\",\n    \"coverage\",\n    \"expansions\",\n    \"memory\",\n    project.EVALUATIONS_PER_TIME,\n]\n\nexp = project.FastDownwardExperiment(environment=ENV)\n\n#exp.add_suite(BENCHMARKS_DIR, SUITE)\nexp.add_suite(SIMULATION_DIR, [\n              \"SimulationDomain:simulationProblem3-2-simulationDomain-0.pddl\"])\n\n# exp.add_algorithm(\"lm cut\", DOWNWARD_REPO, rev, [\"--search\", \"astar(lmcut())\"], driver_options=[\n#                   \"--overall-time-limit\", \"1000000m\", \"--overall-memory-limit\", \"1000000M\"])\n# exp.add_algorithm(\"ipdb\", DOWNWARD_REPO, rev, [\"--search\", \"astar(ipdb())\"], driver_options=[\n#                   \"--overall-time-limit\", \"1000000m\", \"--overall-memory-limit\", \"1000000M\"])\nexp.add_algorithm(\"Lama-First\", DOWNWARD_REPO, rev, [],\n                  driver_options=[\"--alias\", \"lama-first\", \"--overall-time-limit\", \"1000000m\", \"--overall-memory-limit\", \"1000000M\"])\n\nexp.add_parser(exp.EXITCODE_PARSER)\nexp.add_parser(exp.TRANSLATOR_PARSER)\nexp.add_parser(exp.SINGLE_SEARCH_PARSER)\nexp.add_parser(project.DIR / \"parser.py\")\nexp.add_parser(exp.PLANNER_PARSER)\n\nexp.add_step(\"build\", exp.build)\nexp.add_step(\"start\", exp.start_runs)\nexp.add_fetcher(name=\"fetch\")\n\nif not project.REMOTE:\n    exp.add_step(\"remove-eval-dir\", shutil.rmtree,\n                 exp.eval_dir, ignore_errors=True)\n    project.add_scp_step(exp, SCP_LOGIN, REMOTE_REPOS_DIR)\n\nproject.add_absolute_report(\n    exp, attributes=ATTRIBUTES, filter=[project.add_evaluations_per_time]\n)\n\nattributes = [\"expansions\"]\n\nexp.run_steps()\n" >> fd.py
printf "from pathlib import Path\nimport platform\nimport subprocess\nimport sys\n\nfrom downward.experiment import FastDownwardExperiment\nfrom downward.reports.absolute import AbsoluteReport\nfrom downward.reports.scatter import ScatterPlotReport\nfrom downward.reports.taskwise import TaskwiseReport\nfrom lab import tools\nfrom lab.environments import (\n    BaselSlurmEnvironment,\n    LocalEnvironment,\n    TetralithEnvironment,\n)\nfrom lab.experiment import ARGPARSER\nfrom lab.reports import Attribute, geometric_mean\n\n\n# Silence import-unused messages. Experiment scripts may use these imports.\nassert (\n    BaselSlurmEnvironment\n    and FastDownwardExperiment\n    and LocalEnvironment\n    and ScatterPlotReport\n    and TaskwiseReport\n    and TetralithEnvironment\n)\n\n\nDIR = Path(__file__).resolve().parent\nNODE = platform.node()\nREMOTE = NODE.endswith((\".scicore.unibas.ch\", \".cluster.bc2.ch\"))\n\n\ndef parse_args():\n    ARGPARSER.add_argument(\"--tex\", action=\"store_true\",\n                           help=\"produce LaTeX output\")\n    ARGPARSER.add_argument(\n        \"--relative\", action=\"store_true\", help=\"make relative scatter plots\"\n    )\n    return ARGPARSER.parse_args()\n\n\nARGS = parse_args()\nTEX = ARGS.tex\nRELATIVE = ARGS.relative\n\nEVALUATIONS_PER_TIME = Attribute(\n    \"evaluations_per_time\", min_wins=False, function=geometric_mean, digits=1\n)\n\n# Generated by \"./suites.py satisficing\" in aibasel/downward-benchmarks repo.\n# fmt: off\nSUITE_SATISFICING = [\n    \"agricola-sat18-strips\", \"airport\", \"assembly\", \"barman-sat11-strips\",\n    \"barman-sat14-strips\", \"blocks\", \"caldera-sat18-adl\",\n    \"caldera-split-sat18-adl\", \"cavediving-14-adl\", \"childsnack-sat14-strips\",\n    \"citycar-sat14-adl\", \"data-network-sat18-strips\", \"depot\", \"driverlog\",\n    \"elevators-sat08-strips\", \"elevators-sat11-strips\", \"flashfill-sat18-adl\",\n    \"floortile-sat11-strips\", \"floortile-sat14-strips\", \"freecell\",\n    \"ged-sat14-strips\", \"grid\", \"gripper\", \"hiking-sat14-strips\",\n    \"logistics00\", \"logistics98\", \"maintenance-sat14-adl\", \"miconic\",\n    \"miconic-fulladl\", \"miconic-simpleadl\", \"movie\", \"mprime\", \"mystery\",\n    \"nomystery-sat11-strips\", \"nurikabe-sat18-adl\", \"openstacks\",\n    \"openstacks-sat08-adl\", \"openstacks-sat08-strips\",\n    \"openstacks-sat11-strips\", \"openstacks-sat14-strips\", \"openstacks-strips\",\n    \"optical-telegraphs\", \"organic-synthesis-sat18-strips\",\n    \"organic-synthesis-split-sat18-strips\", \"parcprinter-08-strips\",\n    \"parcprinter-sat11-strips\", \"parking-sat11-strips\", \"parking-sat14-strips\",\n    \"pathways\", \"pegsol-08-strips\", \"pegsol-sat11-strips\", \"philosophers\",\n    \"pipesworld-notankage\", \"pipesworld-tankage\", \"psr-large\", \"psr-middle\",\n    \"psr-small\", \"rovers\", \"satellite\", \"scanalyzer-08-strips\",\n    \"scanalyzer-sat11-strips\", \"schedule\", \"settlers-sat18-adl\",\n    \"snake-sat18-strips\", \"sokoban-sat08-strips\", \"sokoban-sat11-strips\",\n    \"spider-sat18-strips\", \"storage\", \"termes-sat18-strips\",\n    \"tetris-sat14-strips\", \"thoughtful-sat14-strips\", \"tidybot-sat11-strips\",\n    \"tpp\", \"transport-sat08-strips\", \"transport-sat11-strips\",\n    \"transport-sat14-strips\", \"trucks\", \"trucks-strips\",\n    \"visitall-sat11-strips\", \"visitall-sat14-strips\",\n    \"woodworking-sat08-strips\", \"woodworking-sat11-strips\", \"zenotravel\",\n]\n# fmt: on\n\n\ndef get_repo_base() -> Path:\n    \"\"\"Get base directory of the repository, as an absolute path.\n\n    Search upwards in the directory tree from the main script until a\n    directory with a subdirectory named \".git\" is found.\n\n    Abort if the repo base cannot be found.\"\"\"\n    path = Path(tools.get_script_path())\n    while path.parent != path:\n        if (path / \".git\").is_dir():\n            return path\n        path = path.parent\n    sys.exit(\"repo base could not be found\")\n\n\ndef remove_file(path: Path):\n    try:\n        path.unlink()\n    except FileNotFoundError:\n        pass\n\n\ndef add_evaluations_per_time(run):\n    evaluations = run.get(\"evaluations\")\n    time = run.get(\"search_time\")\n    if evaluations is not None and evaluations >= 100 and time:\n        run[\"evaluations_per_time\"] = evaluations / time\n    return run\n\n\ndef _get_exp_dir_relative_to_repo():\n    repo_name = get_repo_base().name\n    script = Path(tools.get_script_path())\n    script_dir = script.parent\n    rel_script_dir = script_dir.relative_to(get_repo_base())\n    expname = script.stem\n    return repo_name / rel_script_dir / \"data\" / expname\n\n\ndef add_scp_step(exp, login, repos_dir):\n    remote_exp = Path(repos_dir) / _get_exp_dir_relative_to_repo()\n    exp.add_step(\n        \"scp-eval-dir\",\n        subprocess.call,\n        [\n            \"scp\",\n            \"-r\",  # Copy recursively.\n            \"-C\",  # Compress files.\n            f\"{login}:{remote_exp}-eval\",\n            f\"{exp.path}-eval\",\n        ],\n    )\n\n\ndef fetch_algorithm(exp, expname, algo, *, new_algo=None):\n    \"\"\"Fetch (and possibly rename) a single algorithm from *expname*.\"\"\"\n    new_algo = new_algo or algo\n\n    def rename_and_filter(run):\n        if run[\"algorithm\"] == algo:\n            run[\"algorithm\"] = new_algo\n            run[\"id\"][0] = new_algo\n            return run\n        return False\n\n    exp.add_fetcher(\n        f\"data/{expname}-eval\",\n        filter=rename_and_filter,\n        name=f\"fetch-{new_algo}-from-{expname}\",\n        merge=True,\n    )\n\n\ndef add_absolute_report(exp, *, name=None, outfile=None, **kwargs):\n    report = AbsoluteReport(**kwargs)\n    if name and not outfile:\n        outfile = f\"{name}.{report.output_format}\"\n    elif outfile and not name:\n        name = Path(outfile).name\n    elif not name and not outfile:\n        name = f\"{exp.name}-abs\"\n        outfile = f\"{name}.{report.output_format}\"\n\n    if not Path(outfile).is_absolute():\n        outfile = Path(exp.eval_dir) / outfile\n\n    exp.add_report(report, name=name, outfile=outfile)\n    if not REMOTE:\n        exp.add_step(f\"open-{name}\", subprocess.call, [\"xdg-open\", outfile])\n    exp.add_step(f\"publish-{name}\", subprocess.call, [\"publish\", outfile])\n" >> project.py
printf "#! /usr/bin/env python\n\nimport logging\nimport re\n\nfrom lab.parser import Parser\n\n\nclass CommonParser(Parser):\n    def add_repeated_pattern(\n        self, name, regex, file=\"run.log\", required=False, type=int\n    ):\n        def find_all_occurences(content, props):\n            matches = re.findall(regex, content)\n            if required and not matches:\n                logging.error(f\"Pattern {regex} not found in file {file}\")\n            props[name] = [type(m) for m in matches]\n\n        self.add_function(find_all_occurences, file=file)\n\n    def add_bottom_up_pattern(\n        self, name, regex, file=\"run.log\", required=False, type=int\n    ):\n        def search_from_bottom(content, props):\n            reversed_content = \"\n\".join(reversed(content.splitlines()))\n            match = re.search(regex, reversed_content)\n            if required and not match:\n                logging.error(f\"Pattern {regex} not found in file {file}\")\n            if match:\n                props[name] = type(match.group(1))\n\n        self.add_function(search_from_bottom, file=file)\n\n\ndef main():\n    parser = CommonParser()\n    parser.add_bottom_up_pattern(\n        \"search_start_time\",\n        r\"\[t=(.+)s, \d+ KB\] g=0, 1 evaluated, 0 expanded\",\n        type=float,\n    )\n    parser.add_bottom_up_pattern(\n        \"search_start_memory\",\n        r\"\[t=.+s, (\d+) KB\] g=0, 1 evaluated, 0 expanded\",\n        type=int,\n    )\n    parser.add_pattern(\n        \"initial_h_value\",\n        r\"f = (\d+) \[1 evaluated, 0 expanded, t=.+s, \d+ KB\]\",\n        type=int,\n    )\n    parser.add_repeated_pattern(\n        \"h_values\",\n        r\"New best heuristic value for .+: (\d+)\n\",\n        type=int,\n    )\n    parser.parse()\n\n\nif __name__ == \"__main__\":\n    main()\n" >> parser.py
printf "#! /usr/bin/env python\n\nfrom pathlib import Path\n\nfrom lab.experiment import Experiment\n\nimport project\n\n\nATTRIBUTES = [\n    \"error\",\n    \"run_dir\",\n    \"planner_time\",\n    \"initial_h_value\",\n    \"coverage\",\n    \"cost\",\n    \"evaluations\",\n    \"memory\",\n    project.EVALUATIONS_PER_TIME,\n]\n\nexp = Experiment()\nexp.add_step(\n    \"remove-combined-properties\", project.remove_file, Path(\n        exp.eval_dir) / \"properties\"\n)\n\nfilters = [project.add_evaluations_per_time]\n\nproject.add_absolute_report(\n    exp, attributes=ATTRIBUTES, filter=filters, name=f\"{exp.name}\"\n)\n\n\nexp.run_steps()\n" >> 01-evaluation.py

cd ../..

# Download and install FF Planner
wget https://fai.cs.uni-saarland.de/hoffmann/ff/Metric-FF.tgz
gunzip Metric-FF.tgz
tar -xvf Metric-FF.tar
mv Metric-FF FF

cd FF
make

# Create Lab Files
touch ff.py
touch ff-parser.py

printf "#! /usr/bin/env python\n\nimport os\nimport platform\n\nfrom downward import suites\nfrom downward.reports.absolute import AbsoluteReport\nfrom lab.environments import BaselSlurmEnvironment, LocalEnvironment\nfrom lab.experiment import Experiment\nfrom lab.reports import Attribute, geometric_mean\n\n\n# Create custom report class with suitable info and error attributes.\nclass BaseReport(AbsoluteReport):\n    INFO_ATTRIBUTES = [\"time_limit\", \"memory_limit\"]\n    ERROR_ATTRIBUTES = [\n        \"domain\",\n        \"problem\",\n        \"algorithm\",\n        \"unexplained_errors\",\n        \"error\",\n        \"node\",\n    ]\n\n\nNODE = platform.node()\nREMOTE = NODE.endswith(\n    \".scicore.unibas.ch\") or NODE.endswith(\".cluster.bc2.ch\")\nBENCHMARKS_DIR = os.environ[\"DOWNWARD_BENCHMARKS\"]\nSIMULATION_DIR = os.environ[\"SIMULATION_PDDL\"]\nif REMOTE:\n    ENV = BaselSlurmEnvironment(email=\"my.name@unibas.ch\")\nelse:\n    ENV = LocalEnvironment(processes=2)\nSUITE = [\"grid\", \"gripper:prob01.pddl\",\n         \"miconic:s1-0.pddl\", \"mystery:prob07.pddl\"]\nATTRIBUTES = [\n    \"error\",\n    \"plan\",\n    \"times\",\n    Attribute(\"coverage\", absolute=True, min_wins=False, scale=\"linear\"),\n    Attribute(\"evaluations\", function=geometric_mean),\n    Attribute(\"trivially_unsolvable\", min_wins=False),\n]\nTIME_LIMIT = 1800\nMEMORY_LIMIT = 2048\n\n\n# Create a new experiment.\nexp = Experiment(environment=ENV)\n# Add custom parser for FF.\nexp.add_parser(\"ff-parser.py\")\n\nfor task in suites.build_suite(BENCHMARKS_DIR, SUITE):\n    run = exp.add_run()\n    # Create symbolic links and aliases. This is optional. We\n    # could also use absolute paths in add_command().\n    run.add_resource(\"domain\", task.domain_file, symlink=True)\n    run.add_resource(\"problem\", task.problem_file, symlink=True)\n    # 'ff' binary has to be on the PATH.\n    # We could also use exp.add_resource().\n    run.add_command(\n        \"run-planner\",\n        [\"ff\", \"-o\", \"{domain}\", \"-f\", \"{problem}\"],\n        time_limit=TIME_LIMIT,\n        memory_limit=MEMORY_LIMIT,\n    )\n    # AbsoluteReport needs the following properties:\n    # 'domain', 'problem', 'algorithm', 'coverage'.\n    run.set_property(\"domain\", task.domain)\n    run.set_property(\"problem\", task.problem)\n    run.set_property(\"algorithm\", \"ff\")\n    # BaseReport needs the following properties:\n    # 'time_limit', 'memory_limit'.\n    run.set_property(\"time_limit\", TIME_LIMIT)\n    run.set_property(\"memory_limit\", MEMORY_LIMIT)\n    # Every run has to have a unique id in the form of a list.\n    # The algorithm name is only really needed when there are\n    # multiple algorithms.\n    run.set_property(\"id\", [\"ff\", task.domain, task.problem])\n\n# Add step that writes experiment files to disk.\nexp.add_step(\"build\", exp.build)\n\n# Add step that executes all runs.\nexp.add_step(\"start\", exp.start_runs)\n\n# Add step that collects properties from run directories and\n# writes them to *-eval/properties.\nexp.add_fetcher(name=\"fetch\")\n\n# Make a report.\nexp.add_report(BaseReport(attributes=ATTRIBUTES), outfile=\"report.html\")\n\n# Parse the commandline and run the specified steps.\nexp.run_steps()\n" >> ff.py
printf "#! /usr/bin/env python\n\nimport re\n\nfrom lab.parser import Parser\n\n\ndef error(content, props):\n    if props[\"planner_exit_code\"] == 0:\n        props[\"error\"] = \"plan-found\"\n    else:\n        props[\"error\"] = \"unsolvable-or-error\"\n\n\ndef coverage(content, props):\n    props[\"coverage\"] = int(props[\"planner_exit_code\"] == 0)\n\n\ndef get_plan(content, props):\n    # All patterns are parsed before functions are called.\n    if props.get(\"evaluations\") is not None:\n        props[\"plan\"] = re.findall(r\"^(?:step)?\s*\d+: (.+)\$\", content, re.M)\n\n\ndef get_times(content, props):\n    props[\"times\"] = re.findall(r\"(\d+\.\d+) seconds\", content)\n\n\ndef trivially_unsolvable(content, props):\n    props[\"trivially_unsolvable\"] = int(\n        \"ff: goal can be simplified to FALSE. No plan will solve it\" in content\n    )\n\n\nparser = Parser()\nparser.add_pattern(\"node\", r\"node: (.+)\n\", type=str,\n                   file=\"driver.log\", required=True)\nparser.add_pattern(\n    \"planner_exit_code\", r\"run-planner exit code: (.+)\n\", type=int, file=\"driver.log\"\n)\nparser.add_pattern(\"evaluations\", r\"evaluating (\d+) states\")\nparser.add_function(error)\nparser.add_function(coverage)\nparser.add_function(get_plan)\nparser.add_function(get_times)\nparser.add_function(trivially_unsolvable)\nparser.parse()\n" >> ff-parser.py

# Cleanup
cd ..
rm -r Metric-FF.tar

# Instructions
echo "For Fast Downward usage, please use './fast-downward.py --help'."
echo "For good known domains, please use './suites.py optimal_strips' in the benchmarks folder."
echo 'Activate a Python Virtual Environment by running venv in directories containing a .venv subdirectory.'
echo 'Run Fast Downward experiments with the file fd.py build 2 3 6 7'
echo 'Run FF experiments with the file ff.py'
