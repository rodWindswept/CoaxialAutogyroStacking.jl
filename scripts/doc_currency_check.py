#!/usr/bin/env python3
"""
doc_currency_check.py — mechanical currency checks for CoaxialAutogyroStacking.jl docs.

Checks the drift class that a human sweep misses:
  1. DECISIONS.md newest entry vs newest handover: physics commits that
     landed after the newest decision entry are candidates for a missing
     decision record.
  2. AGENTS.md file map vs the actual src/ and test/ files.
  3. Claimed numbers in README.md, SPEC.md and docs/ACADEMIC_REPORT.md
     vs rows of docs/numbers-register.md (coverage, not values).
  4. Dated docs older than six months that read as plans (PLAN.md class).

Usage: python3 scripts/doc_currency_check.py

Exit code 0 = all checks pass; 1 = issues found. Report-only, never edits.
"""

import os
import re
import subprocess
import sys
from datetime import datetime, timedelta

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ISSUES = []


def newest_date_in(path, pattern):
    """Newest YYYY-MM-DD date that matches pattern inside path."""
    newest = None
    if not os.path.exists(path):
        return None
    for root, _, files in os.walk(path):
        for name in files:
            fpath = os.path.join(root, name)
            try:
                text = open(fpath, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for m in re.finditer(pattern, text):
                d = datetime.strptime(m.group(1), "%Y-%m-%d")
                if newest is None or d > newest:
                    newest = d
    return newest


def git_log_dates(path="."):
    """Newest commit date for each src/ file path, as YYYY-MM-DD."""
    out = subprocess.run(
        ["git", "-C", REPO, "log", "-1", "--format=%cs", "--", path],
        capture_output=True, text=True)
    return out.stdout.strip()


# 1. Decisions currency
handover_dir = os.path.join(REPO, "handovers")
newest_handover = newest_date_in(handover_dir, r"(\d{4}-\d{2}-\d{2})")
newest_decision = newest_date_in(os.path.join(REPO, "DECISIONS.md"),
                                 r"\((\d{4}-\d{2}-\d{2})\)")
newest_src = None
for root, _, files in os.walk(os.path.join(REPO, "src")):
    for name in files:
        if name.endswith(".jl"):
            d = git_log_dates(os.path.join("src", name))
            if d:
                dd = datetime.strptime(d, "%Y-%m-%d")
                if newest_src is None or dd > newest_src:
                    newest_src = dd
if newest_src and newest_decision and newest_src > newest_decision:
    ISSUES.append(
        "decisions: newest src/ commit (%s) is newer than the newest "
        "DECISIONS entry (%s). Physics commits after the newest entry "
        "need a decision record." % (
            newest_src.date(), newest_decision.date()))

# 2. AGENTS.md file map vs the tree
agents = open(os.path.join(REPO, "AGENTS.md"), encoding="utf-8").read()
# Cross-repo mentions like KiteTurbineDynamics.jl/src/lift_kite.jl are
# not this repo's map. The negative lookbehind drops them.
listed = set(re.findall(r"(?<!KiteTurbineDynamics\.jl/)src/(\w+)\.jl", agents))
listed |= set(re.findall(r"^\s{2,}(\w+)\.jl", agents, re.M))
actual = set(os.path.splitext(n)[0] for n in os.listdir(os.path.join(REPO, "src")) if n.endswith(".jl"))
if actual - listed:
    ISSUES.append("file map: AGENTS.md misses src/ modules: %s" %
                  ", ".join(sorted(actual - listed)))
if listed - actual:
    ISSUES.append("file map: AGENTS.md lists removed src/ modules: %s" %
                  ", ".join(sorted(listed - actual)))
# Test files: AGENTS.md states a count, not a list. Check the count.
actual_tests = len([n for n in os.listdir(os.path.join(REPO, "test"))
                     if n.startswith("test_") and n.endswith(".jl")])
count_claim = re.search(r"(\d+)\s+test_<module>\.jl", agents)
if count_claim and int(count_claim.group(1)) != actual_tests:
    ISSUES.append(
        "file map: AGENTS.md claims %s test files, the tree holds %d."
        % (count_claim.group(1), actual_tests))

# 3. Register coverage of claimed numbers
claim_docs = ["README.md", "SPEC.md", os.path.join("docs", "ACADEMIC_REPORT.md")]
register = open(os.path.join(REPO, "docs", "numbers-register.md"),
                encoding="utf-8").read()
covered = len(re.findall(r"^\| CA-\d+", register, re.M))
claimed = 0
for doc in claim_docs:
    path = os.path.join(REPO, doc)
    if not os.path.exists(path):
        continue
    text = open(path, encoding="utf-8").read()
    claimed += len(re.findall(r"\b\d[\d.,]*\s*(?:N|kN|kg|m|RPM|m/s|kW)\b", text))
if claimed > covered * 3:
    ISSUES.append(
        "register: %d number-shaped claims found in %s against %d "
        "candidate rows. Unsigned external claims are a release blocker."
        % (claimed, ", ".join(claim_docs), covered))

# 4. Aged plan-class docs
cutoff = datetime.now() - timedelta(days=180)
for name in ["PLAN.md", "HANDOVER.md"]:
    path = os.path.join(REPO, name)
    if not os.path.exists(path):
        continue
    d = newest_date_in(path, r"(\d{4}-\d{2}-\d{2})")
    if d and d < cutoff:
        ISSUES.append("aged: %s newest date %s is older than six months. "
                      "Review or archive it." % (name, d.date()))

if ISSUES:
    print("currency check: %d issue(s)" % len(ISSUES))
    for i in ISSUES:
        print("  - " + i)
    sys.exit(1)
print("currency check: clean")
