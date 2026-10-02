import json
import os
from pathlib import Path
import subprocess
import sys

import pytest

from scripts.image_digest import image_digest


DIGEST = "sha256:" + "a" * 64
PROJECT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize("image,reference", [
    ("traininguser/weather", f"traininguser/weather@{DIGEST}"),
    ("traininguser/weather", f"docker.io/traininguser/weather@{DIGEST}"),
    ("docker.io/traininguser/weather", f"traininguser/weather@{DIGEST}"),
    ("ghcr.io/owner/repo/full-deploy", f"ghcr.io/owner/repo/full-deploy@{DIGEST}"),
])
def test_selects_digest_for_exact_repository(image, reference):
    inspected = [{"RepoDigests": ["other/image@sha256:" + "b" * 64, reference]}]
    assert image_digest(inspected, image) == DIGEST


@pytest.mark.parametrize("references", [None, [], [f"traininguser/weather-copy@{DIGEST}"],
                                       ["traininguser/weather@sha256:too-short"],
                                       [f"traininguser/weather@{DIGEST}",
                                        "traininguser/weather@sha256:" + "b" * 64]])
def test_missing_wrong_or_ambiguous_digest_is_rejected(references):
    with pytest.raises(ValueError):
        image_digest([{"RepoDigests": references}], "traininguser/weather")


def test_cli_output_does_not_contain_docker_login_username():
    # A full reference contains the username marked secret by docker/login-action.
    # The value crossing the job boundary must contain only the digest.
    image = "traininguser/weather"
    inspected = [{"RepoDigests": [f"{image}@{DIGEST}"]}]
    result = subprocess.run([sys.executable, str(PROJECT / "scripts/image_digest.py"), image],
                            input=json.dumps(inspected), capture_output=True, text=True, check=True)
    assert result.stdout.strip() == DIGEST
    assert "traininguser" not in result.stdout


@pytest.mark.parametrize("reference", ["", "traininguser/weather:latest", "traininguser/weather@",
                                      "traininguser/weather@sha256:short", f"@{DIGEST}"])
def test_deploy_rejects_invalid_reference_before_external_commands(tmp_path, reference):
    marker = tmp_path / "external-command-called"
    tools_dir = tmp_path / "bin"
    tools_dir.mkdir()
    # Even if the validation regresses, these stubs prevent network/cloud access.
    for name in ("terraform", "curl"):
        tool = tools_dir / name
        tool.write_text('#!/bin/sh\nprintf called > "$CALL_MARKER"\nexit 77\n')
        tool.chmod(0o755)
    environment = {
        "PATH": str(tools_dir) + os.pathsep + os.environ["PATH"],
        "CLOUD": "digitalocean", "DEPLOY_TEMP": str(tmp_path),
        "PG_CONN_STR": "unused-test-connection", "DEPLOY_IMAGE": reference,
        "REGISTRY_USERNAME": "unused", "REGISTRY_TOKEN": "unused",
        "DIGITALOCEAN_TOKEN": "unused", "CALL_MARKER": str(marker),
    }
    result = subprocess.run(["/bin/bash", str(PROJECT / "scripts/deploy.sh")],
                            env=environment, capture_output=True, text=True, timeout=10)
    assert result.returncode != 0
    assert "DEPLOY_IMAGE" in result.stderr
    assert not marker.exists()
