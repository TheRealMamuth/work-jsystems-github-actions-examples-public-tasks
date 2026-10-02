#!/usr/bin/env bash
# Creates/updates real infrastructure and deploys via SSH. Run only in the deploy job.
set -euo pipefail
umask 077

: "${CLOUD:?Set CLOUD to aws or digitalocean}"
: "${DEPLOY_TEMP:?Set a private temporary directory}"
: "${PG_CONN_STR:?Configure the TF_PG_CONN_STR GitHub secret}"
: "${DEPLOY_IMAGE:?Expected an image pinned by digest}"
: "${REGISTRY_USERNAME:?Registry username is required}"
: "${REGISTRY_TOKEN:?Registry token is required}"
case "$CLOUD" in
  aws|digitalocean) ;;
  *) echo 'Unsupported cloud' >&2; exit 1 ;;
esac

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tf_dir="$project_dir/terraform/$CLOUD"
export TF_DATA_DIR="$DEPLOY_TEMP/terraform"
export TF_IN_AUTOMATION=1 TF_INPUT=0 TF_WORKSPACE=default
export ANSIBLE_CONFIG="$project_dir/ansible/ansible.cfg"
export ANSIBLE_LOCAL_TEMP="$DEPLOY_TEMP/ansible-tmp"
export ANSIBLE_HOME="$DEPLOY_TEMP/ansible-home"
export ANSIBLE_COLLECTIONS_PATH="$DEPLOY_TEMP/collections"
export ANSIBLE_SSH_CONTROL_PATH_DIR="$DEPLOY_TEMP/ssh-control"
export PIP_CACHE_DIR="$DEPLOY_TEMP/pip-cache"
mkdir -p "$ANSIBLE_LOCAL_TEMP" "$ANSIBLE_SSH_CONTROL_PATH_DIR"

if [[ "$CLOUD" == aws ]]; then
  : "${AWS_ACCESS_KEY_ID:?AWS authentication step has not run}"
  : "${AWS_SECRET_ACCESS_KEY:?AWS authentication step has not run}"
else
  : "${DIGITALOCEAN_TOKEN:?Configure DIGITALOCEAN_TOKEN}"
fi

# Optional override for networks where the HTTPS and SSH outbound IPs differ.
runner_ip="${SSH_SOURCE_IP:-}"
if [[ -z "$runner_ip" ]]; then
  runner_ip="$(curl -4 --fail --silent --show-error --retry 3 --max-time 15 https://checkip.amazonaws.com)"
fi
export TF_VAR_ssh_cidr
TF_VAR_ssh_cidr="$(python -c 'import ipaddress,sys; print(str(ipaddress.IPv4Address(sys.argv[1].strip())) + "/32")' "$runner_ip")"

# Only the non-secret schema name is stored in the backend configuration.
terraform -chdir="$tf_dir" init -input=false -lockfile=readonly \
  -backend-config="schema_name=full_deploy_${CLOUD}"
terraform -chdir="$tf_dir" validate
terraform -chdir="$tf_dir" plan -input=false -lock-timeout=5m -out="$DEPLOY_TEMP/app.tfplan"
terraform -chdir="$tf_dir" apply -input=false -lock-timeout=5m "$DEPLOY_TEMP/app.tfplan"

# Redirect sensitive output directly to a file. Never use GITHUB_OUTPUT, artifacts
# or a cache for the private key, the plan, or the Terraform state.
terraform -chdir="$tf_dir" output -json ansible_inventory > "$DEPLOY_TEMP/inventory.json"
terraform -chdir="$tf_dir" output -raw ssh_private_key > "$DEPLOY_TEMP/id_ed25519"
terraform -chdir="$tf_dir" output -raw ssh_known_hosts > "$DEPLOY_TEMP/known_hosts"
chmod 600 "$DEPLOY_TEMP/id_ed25519" "$DEPLOY_TEMP/known_hosts" "$DEPLOY_TEMP/inventory.json"

python -m venv "$DEPLOY_TEMP/venv"
"$DEPLOY_TEMP/venv/bin/python" -m pip install --disable-pip-version-check \
  -r "$project_dir/ansible/requirements-controller.txt"
"$DEPLOY_TEMP/venv/bin/ansible-galaxy" collection install \
  -r "$project_dir/ansible/requirements.yml" -p "$ANSIBLE_COLLECTIONS_PATH"
"$DEPLOY_TEMP/venv/bin/ansible-playbook" \
  -i "$DEPLOY_TEMP/inventory.json" \
  --private-key "$DEPLOY_TEMP/id_ed25519" \
  --ssh-common-args="-o StrictHostKeyChecking=yes -o UserKnownHostsFile=$DEPLOY_TEMP/known_hosts -o IdentitiesOnly=yes" \
  --limit app "$project_dir/ansible/site.yml"

app_url="$(terraform -chdir="$tf_dir" output -raw app_url)"
curl --fail --silent --show-error --retry 5 --retry-all-errors --max-time 15 "$app_url/health"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf 'Deployed %s to %s: %s\n' "$DEPLOY_IMAGE" "$CLOUD" "$app_url" >> "$GITHUB_STEP_SUMMARY"
fi
