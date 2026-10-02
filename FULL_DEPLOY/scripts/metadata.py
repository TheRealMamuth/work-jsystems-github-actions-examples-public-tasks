"""Validate refs and produce non-secret GitHub job outputs. No network calls."""
import json
import os
import re

VERSION = re.compile(r"v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")


def metadata(env):
    event = env["GITHUB_EVENT_NAME"]
    operation = (env.get("INPUT_OPERATION") if event == "workflow_dispatch" else "deploy") or "deploy"
    if operation not in {"deploy", "destroy"}:
        raise ValueError("Operation must be deploy or destroy")
    target = (env.get("INPUT_CLOUD") if event == "workflow_dispatch"
              else env.get("DEPLOY_CLOUD")) or "none"
    if target not in {"none", "aws", "digitalocean", "both"}:
        raise ValueError("Cloud must be none, aws, digitalocean or both")
    if event == "pull_request":
        target = "none"
    clouds = ["aws", "digitalocean"] if target == "both" else [target]
    selection = {
        "operation": operation,
        # A nonempty matrix also works when infrastructure jobs are skipped.
        "clouds": json.dumps(clouds if target != "none" else ["aws"]),
    }
    if operation == "destroy":
        if target == "none":
            raise ValueError("Destroy requires cloud=aws, digitalocean or both")
        # Deleting infrastructure must not depend on registry settings or an image tag.
        return {**selection, "publish": "false", "deploy": "false",
                "tag": "", "image": "", "registry": "", "server": ""}

    tag = env["GITHUB_SHA"]
    if not re.fullmatch(r"[0-9a-f]{40}", tag):
        raise ValueError("Expected a full Git commit SHA")
    if env["GITHUB_REF_TYPE"] == "tag":
        tag = env["GITHUB_REF_NAME"]
        if not VERSION.fullmatch(tag):
            raise ValueError("Only release tags vX.Y.Z are allowed, e.g. v1.2.3")
    registry = env.get("REGISTRY", "") or "ghcr"
    if registry not in {"ghcr", "dockerhub"}:
        raise ValueError("CONTAINER_REGISTRY must be ghcr or dockerhub")
    if registry == "ghcr":
        image = f"ghcr.io/{env['GITHUB_REPOSITORY'].lower()}/full-deploy"
        server = "ghcr.io"
    else:
        image = env.get("DOCKERHUB_IMAGE", "")
        if not re.fullmatch(r"[a-z0-9][a-z0-9_-]*/[a-z0-9][a-z0-9_.-]*", image):
            raise ValueError("DOCKERHUB_IMAGE must be a lowercase namespace/repository")
        server = "docker.io"
    return {
        **selection,
        "tag": tag, "image": image, "registry": registry, "server": server,
        "publish": str(event != "pull_request").lower(),
        "deploy": str(target != "none").lower(),
    }


if __name__ == "__main__":
    values = metadata(os.environ)
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        for key, value in values.items():
            output.write(f"{key}={value}\n")
