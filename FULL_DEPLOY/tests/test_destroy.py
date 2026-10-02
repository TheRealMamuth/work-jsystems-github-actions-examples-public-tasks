"""Exercise the destructive script with a fake CLI; never contact Terraform or a cloud."""
import json
import os
from pathlib import Path
import subprocess
import sys

import pytest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "destroy.sh"


@pytest.fixture
def destroy_runner(tmp_path):
    cli = tmp_path / "terraform"
    cli.write_text(f"#!{sys.executable}\n" + '''
import json, os, pathlib, sys
args = sys.argv[1:]
command = args[1]
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps({"args": args, "workspace": os.environ["TF_WORKSPACE"],
                          "ssh_cidr": os.environ["TF_VAR_ssh_cidr"],
                          "data_dir": os.environ["TF_DATA_DIR"]}) + "\\n")
if command == os.environ.get("FAIL_ON"):
    sys.exit(7)
if command == "plan":
    plan = pathlib.Path(next(arg.removeprefix("-out=") for arg in args if arg.startswith("-out=")))
    plan.write_text(json.dumps({"destroy": "-destroy" in args}))
elif command == "apply":
    if not json.loads(pathlib.Path(args[-1]).read_text())["destroy"]:
        sys.exit("Refusing to apply a plan that is not a destroy plan")
elif command not in {"init", "validate"}:
    sys.exit("Unexpected operation during destruction")
''')
    cli.chmod(0o755)
    private_dir = tmp_path / "private"
    private_dir.mkdir(mode=0o700)
    log = tmp_path / "calls.jsonl"
    summary = tmp_path / "summary.md"
    env = {
        "PATH": str(tmp_path) + os.pathsep + os.environ["PATH"],
        "CLOUD": "aws", "DEPLOY_TEMP": str(private_dir),
        "PG_CONN_STR": "postgresql://example:dummy@localhost/unused",
        "AWS_ACCESS_KEY_ID": "dummy", "AWS_SECRET_ACCESS_KEY": "dummy",
        "DIGITALOCEAN_TOKEN": "dummy", "CALL_LOG": str(log),
        "GITHUB_STEP_SUMMARY": str(summary),
    }

    def run(**overrides):
        current = {**env, **overrides}
        current = {key: value for key, value in current.items() if value is not None}
        result = subprocess.run(["/bin/bash", str(SCRIPT)], env=current,
                                capture_output=True, text=True, timeout=10)
        calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        return result, calls, summary

    return run


@pytest.mark.parametrize("cloud", ["aws", "digitalocean"])
def test_destroy_uses_selected_state_and_applies_only_saved_destroy_plan(destroy_runner, cloud):
    result, calls, summary = destroy_runner(CLOUD=cloud)
    assert result.returncode == 0, result.stderr
    assert [call["args"][1] for call in calls] == ["init", "validate", "plan", "apply"]
    assert f"-backend-config=schema_name=full_deploy_{cloud}" in calls[0]["args"]
    assert all(call["args"][0].endswith(f"/terraform/{cloud}") for call in calls)
    assert all(call["workspace"] == "default" for call in calls)
    assert all(call["ssh_cidr"] == "127.0.0.1/32" for call in calls)
    assert "-destroy" in calls[2]["args"]
    assert all("-lock-timeout=5m" in call["args"] for call in calls[2:])
    assert "conn_str=" not in json.dumps(calls)
    assert "dummy" not in result.stdout + result.stderr + json.dumps(calls)
    plan = Path(calls[3]["args"][-1])
    assert str(plan.parent / "terraform") == calls[0]["data_dir"]
    assert plan.stat().st_mode & 0o777 == 0o600
    assert f"full_deploy_{cloud}" in summary.read_text()


@pytest.mark.parametrize("stage", ["init", "validate", "plan"])
def test_destroy_never_applies_after_preparation_failure(destroy_runner, stage):
    result, calls, summary = destroy_runner(FAIL_ON=stage)
    assert result.returncode != 0
    assert not any(call["args"][1] == "apply" for call in calls)
    assert not summary.exists()


def test_failed_apply_does_not_report_success(destroy_runner):
    result, _, summary = destroy_runner(FAIL_ON="apply")
    assert result.returncode != 0
    assert not summary.exists()


@pytest.mark.parametrize("cloud,missing", [("aws", "PG_CONN_STR"),
                                          ("aws", "AWS_ACCESS_KEY_ID"),
                                          ("aws", "AWS_SECRET_ACCESS_KEY"),
                                          ("digitalocean", "DIGITALOCEAN_TOKEN")])
def test_missing_secret_prevents_terraform_calls(destroy_runner, cloud, missing):
    result, calls, _ = destroy_runner(CLOUD=cloud, **{missing: None})
    assert result.returncode != 0
    assert calls == []


def test_invalid_cloud_prevents_terraform_calls(destroy_runner):
    result, calls, _ = destroy_runner(CLOUD="none")
    assert result.returncode != 0
    assert calls == []
