import pytest
from scripts.metadata import metadata


@pytest.fixture
def env():
    return {"GITHUB_SHA": "a" * 40, "GITHUB_REF_TYPE": "branch",
            "GITHUB_REF_NAME": "main", "GITHUB_REPOSITORY": "Owner/Repo",
            "GITHUB_EVENT_NAME": "push"}


@pytest.mark.parametrize("tag", ["v1.2.3", "v10.20.30", "v0.0.0"])
def test_release(env, tag):
    env.update(GITHUB_REF_TYPE="tag", GITHUB_REF_NAME=tag)
    assert metadata(env)["tag"] == tag


@pytest.mark.parametrize("tag", ["v1", "v1.2", "1.2.3", "v01.2.3", "v1.2.3-rc.1",
                                  "v1.2.3+build.1", "v1.2.3\ninjected=true", "v1.2.3.4"])
def test_invalid_release(env, tag):
    env.update(GITHUB_REF_TYPE="tag", GITHUB_REF_NAME=tag)
    with pytest.raises(ValueError):
        metadata(env)


def test_pull_request_cannot_publish_or_deploy(env):
    env.update(GITHUB_EVENT_NAME="pull_request", DEPLOY_CLOUD="both")
    assert metadata(env)["publish"] == "false"
    assert metadata(env)["deploy"] == "false"


def test_defaults_to_ghcr_and_commit(env):
    result = metadata(env)
    assert result["operation"] == "deploy"
    assert result["image"] == "ghcr.io/owner/repo/full-deploy"
    assert result["tag"] == "a" * 40
    assert result["deploy"] == "false"


def test_manual_choice_overrides_automatic_deployment(env):
    env.update(GITHUB_EVENT_NAME="workflow_dispatch", INPUT_CLOUD="none", DEPLOY_CLOUD="both")
    assert metadata(env)["deploy"] == "false"
    env["INPUT_CLOUD"] = "both"
    assert metadata(env)["clouds"] == '["aws", "digitalocean"]'


def test_dockerhub(env):
    env.update(REGISTRY="dockerhub", DOCKERHUB_IMAGE="example/weather")
    assert metadata(env)["image"] == "example/weather"
    env["DOCKERHUB_IMAGE"] = "example/weather:latest"
    with pytest.raises(ValueError):
        metadata(env)


@pytest.mark.parametrize("cloud,clouds", [("aws", '["aws"]'),
                                        ("digitalocean", '["digitalocean"]'),
                                        ("both", '["aws", "digitalocean"]')])
def test_manual_destroy_skips_publishing_and_deployment(env, cloud, clouds):
    env.update(GITHUB_EVENT_NAME="workflow_dispatch", INPUT_OPERATION="destroy", INPUT_CLOUD=cloud)
    result = metadata(env)
    assert result["operation"] == "destroy"
    assert result["clouds"] == clouds
    assert result["publish"] == "false"
    assert result["deploy"] == "false"


def test_destroy_does_not_require_valid_registry_or_release_tag(env):
    env.update(GITHUB_EVENT_NAME="workflow_dispatch", INPUT_OPERATION="destroy", INPUT_CLOUD="aws",
               REGISTRY="dockerhub", DOCKERHUB_IMAGE="", GITHUB_REF_TYPE="tag", GITHUB_REF_NAME="v1")
    assert metadata(env)["operation"] == "destroy"


@pytest.mark.parametrize("cloud", ["", "none"])
def test_destroy_requires_explicit_cloud(env, cloud):
    env.update(GITHUB_EVENT_NAME="workflow_dispatch", INPUT_OPERATION="destroy", INPUT_CLOUD=cloud,
               DEPLOY_CLOUD="both")
    with pytest.raises(ValueError, match="Destroy requires"):
        metadata(env)


@pytest.mark.parametrize("event", ["push", "pull_request"])
def test_destroy_cannot_be_selected_by_automatic_events(env, event):
    env.update(GITHUB_EVENT_NAME=event, INPUT_OPERATION="destroy", INPUT_CLOUD="both")
    assert metadata(env)["operation"] == "deploy"


def test_unknown_manual_operation_is_rejected(env):
    env.update(GITHUB_EVENT_NAME="workflow_dispatch", INPUT_OPERATION="remove", INPUT_CLOUD="aws")
    with pytest.raises(ValueError, match="Operation must be"):
        metadata(env)
