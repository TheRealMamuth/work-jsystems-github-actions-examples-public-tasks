#!/usr/bin/env bash
# Deletes the infrastructure tracked in this cloud's PostgreSQL state.
set -euo pipefail
umask 077

: "${CLOUD:?Set CLOUD to aws or digitalocean}"
: "${DEPLOY_TEMP:?Set a private temporary directory}"
: "${PG_CONN_STR:?Configure the TF_PG_CONN_STR GitHub secret}"
case "$CLOUD" in
  aws)
    : "${AWS_ACCESS_KEY_ID:?AWS authentication step has not run}"
    : "${AWS_SECRET_ACCESS_KEY:?AWS authentication step has not run}"
    ;;
  digitalocean)
    : "${DIGITALOCEAN_TOKEN:?Configure DIGITALOCEAN_TOKEN}"
    ;;
  *) echo 'Unsupported cloud' >&2; exit 1 ;;
esac

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tf_dir="$project_dir/terraform/$CLOUD"
export TF_DATA_DIR="$DEPLOY_TEMP/terraform"
export TF_IN_AUTOMATION=1 TF_INPUT=0 TF_WORKSPACE=default
# Terraform still requires input variables when planning destruction. This valid
# placeholder is never applied to a firewall; no SSH or public-IP lookup is needed.
export TF_VAR_ssh_cidr=127.0.0.1/32

# Same database, schema and workspace as deploy.sh; credentials stay in PG_CONN_STR.
terraform -chdir="$tf_dir" init -input=false -lockfile=readonly \
  -backend-config="schema_name=full_deploy_${CLOUD}"
terraform -chdir="$tf_dir" validate
terraform -chdir="$tf_dir" plan -destroy -input=false -lock-timeout=5m \
  -out="$DEPLOY_TEMP/destroy.tfplan"
# A saved destroy plan needs no interactive approval. Never upload this plan:
# it can contain private keys from state and is deleted by the job's always() step.
terraform -chdir="$tf_dir" apply -input=false -lock-timeout=5m "$DEPLOY_TEMP/destroy.tfplan"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf 'Destroyed infrastructure from PostgreSQL schema full_deploy_%s (workspace default).\n' \
    "$CLOUD" >> "$GITHUB_STEP_SUMMARY"
fi
