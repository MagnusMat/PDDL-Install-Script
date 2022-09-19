#! /usr/bin/env python

import re

from lab.parser import Parser


def error(content, props):
    if props["planner_exit_code"] == 0:
        props["error"] = "plan-found"
    else:
        props["error"] = "unsolvable-or-error"


def coverage(content, props):
    props["coverage"] = int(props["planner_exit_code"] == 0)


def get_plan(content, props):
    # All patterns are parsed before functions are called.
    if props.get("evaluations") is not None:
        props["plan"] = re.findall(r"^(?:step)?\s*\d+: (.+)$", content, re.M)


def get_times(content, props):
    props["times"] = re.findall(r"(\d+\.\d+) seconds", content)


def trivially_unsolvable(content, props):
    props["trivially_unsolvable"] = int(
        "ff: goal can be simplified to FALSE. No plan will solve it" in content
    )


parser = Parser()
parser.add_pattern("node", r"node: (.+)", type=str,
                   file="driver.log", required=True)
parser.add_pattern("planner_exit_code", r"run-planner exit code: (.+)", type=int, file="driver.log"
                   )
parser.add_pattern("evaluations", r"evaluating (\d+) states")
parser.add_function(error)
parser.add_function(coverage)
parser.add_function(get_plan)
parser.add_function(get_times)
parser.add_function(trivially_unsolvable)
parser.parse()
