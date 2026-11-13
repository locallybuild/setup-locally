#!/usr/bin/env python3
"""Run a composite action's `run:` steps locally, without GitHub Actions.

    tests/run-action.py snapshot-diff/action.yml from=baseline to=after comment=false

It understands just enough of the expression syntax for these actions -
`inputs.*`, `steps.*.outputs.*`, `github.*`, `runner.*` and `env.*`, `==`,
`!=`, `&&`, `||`, `always()` and `failure()` - and skips `uses:` steps, which
it reports. Needs PyYAML. The job summary is written to $RUNNER_TEMP/summary.md.
"""

import os
import re
import subprocess
import sys
import tempfile

import yaml

EXPR = re.compile(r"\$\{\{\s*(.*?)\s*\}\}")


def main():
    action_path = os.path.abspath(sys.argv[1])
    action = yaml.safe_load(open(action_path))
    given = dict(a.split("=", 1) for a in sys.argv[2:])

    runner_temp = os.environ.get("RUNNER_TEMP") or tempfile.mkdtemp(prefix="run-action-")
    os.makedirs(runner_temp, exist_ok=True)
    platform = {"darwin": "macOS", "win32": "Windows"}.get(sys.platform, "Linux")
    github = {
        "repository": os.environ.get("GITHUB_REPOSITORY", "locallybuild/example"),
        "run_id": "1", "run_attempt": "1", "token": os.environ.get("GH_TOKEN", ""),
        "action_path": os.path.dirname(action_path),
        "event": {"pull_request": {"number": given.pop("_pr", "")}},
    }
    runner = {"temp": runner_temp, "os": platform}
    base_env = dict(os.environ, RUNNER_TEMP=runner_temp, RUNNER_OS=platform,
                    GITHUB_RUN_ID="1", GITHUB_RUN_ATTEMPT="1",
                    GITHUB_REPOSITORY=github["repository"],
                    GITHUB_STEP_SUMMARY=os.path.join(runner_temp, "summary.md"))

    steps = {}
    failed = False

    def lookup(path, ctx):
        v = ctx
        for part in path.split("."):
            if not isinstance(v, dict):
                return ""
            v = v.get(part, "")
        return v if v is not None else ""

    def evaluate(expr, ctx):
        def ref(m):
            return repr(str(lookup(m.group(0), ctx)))
        py = re.sub(r"\b(inputs|steps|github|runner|env)(\.[A-Za-z0-9_-]+)+", ref, expr)
        py = py.replace("&&", " and ").replace("||", " or ").replace("!=", " != ")
        py = py.replace("always()", "True").replace("failure()", repr(failed))
        py = re.sub(r"'([^']*)'", lambda m: repr(m.group(1)), py)
        return eval(py)  # noqa: S307 - our own action files only

    def substitute(value, ctx):
        return EXPR.sub(lambda m: str(evaluate(m.group(1), ctx)), str(value))

    ctx = {"github": github, "runner": runner, "steps": steps, "env": base_env, "inputs": {}}
    for name, spec in (action.get("inputs") or {}).items():
        ctx["inputs"][name] = given.pop(name) if name in given else substitute(spec.get("default", ""), ctx)
    if given:
        sys.exit(f"unknown inputs: {', '.join(given)}")

    for i, step in enumerate(action["runs"]["steps"]):
        title = step.get("name", f"step {i}")
        cond = step.get("if")
        # As in GitHub Actions, a condition without a status function only
        # runs while everything before it has succeeded.
        if failed and not re.search(r"\b(always|failure)\(\)", str(cond or "")):
            print(f"--- skip (failed): {title}")
            continue
        if cond is not None and not evaluate(str(cond), ctx):
            print(f"--- skip: {title}")
            continue
        if "uses" in step:
            print(f"--- SKIPPED (uses {step['uses'].split('@')[0]}): {title}")
            continue
        print(f"--- run: {title}")
        out = os.path.join(runner_temp, f"output-{i}")
        open(out, "w").close()
        env = dict(base_env, GITHUB_OUTPUT=out)
        env.update({k: substitute(v, ctx) for k, v in (step.get("env") or {}).items()})
        rc = subprocess.run(["bash", "-e", "-c", step["run"]], env=env).returncode
        outputs = {}
        with open(out) as f:
            for line in f.read().splitlines():
                if "=" in line:
                    k, v = line.split("=", 1)
                    outputs[k] = v
        if "id" in step:
            steps[step["id"]] = {"outputs": outputs}
        if rc != 0:
            print(f"--- FAILED ({rc}): {title}")
            failed = True

    print("--- outputs:")
    for name, spec in (action.get("outputs") or {}).items():
        print(f"{name}={substitute(spec['value'], ctx)}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
