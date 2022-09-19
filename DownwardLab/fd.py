#! /usr/bin/env python

import os
import shutil

import project


REPO = project.get_repo_base()
BENCHMARKS_DIR = os.environ["DOWNWARD_BENCHMARKS"]
DOWNWARD_REPO = os.environ["DOWNWARD_REPO"]
SIMULATION_DIR = os.environ["SIMULATION_PDDL"]
SCP_LOGIN = "myname@myserver.com"
REMOTE_REPOS_DIR = "/infai/seipp/projects"
if project.REMOTE:
    SUITE = project.SUITE_SATISFICING
    ENV = project.BaselSlurmEnvironment(email="my.name@myhost.ch")
else:
    SUITE = ["depot:p01.pddl", "grid:prob01.pddl",
             "gripper:prob01.pddl", "airport:p01-airport1-p1.pddl"]
    ENV = project.LocalEnvironment(processes=2)

rev = "main"
ATTRIBUTES = [
    "error",
    "run_dir",
    "search_start_time",
    "search_start_memory",
    "total_time",
    "h_values",
    "coverage",
    "expansions",
    "memory",
    project.EVALUATIONS_PER_TIME,
]

exp = project.FastDownwardExperiment(environment=ENV)

#exp.add_suite(BENCHMARKS_DIR, SUITE)
exp.add_suite(SIMULATION_DIR, [
              "SimulationDomain:simulationProblem3-2-simulationDomain-0.pddl"])

# exp.add_algorithm("lm cut", DOWNWARD_REPO, rev, ["--search", "astar(lmcut())"], driver_options=[
#                   "--overall-time-limit", "1000000m", "--overall-memory-limit", "1000000M"])
# exp.add_algorithm("ipdb", DOWNWARD_REPO, rev, ["--search", "astar(ipdb())"], driver_options=[
#                   "--overall-time-limit", "1000000m", "--overall-memory-limit", "1000000M"])
exp.add_algorithm("Lama-First", DOWNWARD_REPO, rev, [],
                  driver_options=["--alias", "lama-first", "--overall-time-limit", "1000000m", "--overall-memory-limit", "1000000M"])

exp.add_parser(exp.EXITCODE_PARSER)
exp.add_parser(exp.TRANSLATOR_PARSER)
exp.add_parser(exp.SINGLE_SEARCH_PARSER)
exp.add_parser(project.DIR / "parser.py")
exp.add_parser(exp.PLANNER_PARSER)

exp.add_step("build", exp.build)
exp.add_step("start", exp.start_runs)
exp.add_fetcher(name="fetch")

if not project.REMOTE:
    exp.add_step("remove-eval-dir", shutil.rmtree,
                 exp.eval_dir, ignore_errors=True)
    project.add_scp_step(exp, SCP_LOGIN, REMOTE_REPOS_DIR)

project.add_absolute_report(
    exp, attributes=ATTRIBUTES, filter=[project.add_evaluations_per_time]
)

attributes = ["expansions"]

exp.run_steps()
