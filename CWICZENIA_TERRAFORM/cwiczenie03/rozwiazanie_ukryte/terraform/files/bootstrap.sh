#!/usr/bin/env bash
set -euo pipefail
umask 077

current_stage='bootstrap-start'
stage_started=$SECONDS

diagnostics() {
  echo '[bootstrap] Failure diagnostics (service state and process names only).' >&2
  if command -v cloud-init >/dev/null 2>&1; then
    timeout --kill-after=5s 15 cloud-init status --long >&2 || true
  fi
  timeout --kill-after=5s 15 systemctl --no-pager show \
    --property=Id,LoadState,ActiveState,SubState,Result,ExecMainStatus \
    cloud-init.service cloud-final.service apt-daily.service apt-daily-upgrade.service \
    docker.service nginx.service >&2 || true
  ps -eo pid,ppid,stat,etimes,comm |
    awk 'NR == 1 || $5 ~ /^(apt|apt-get|dpkg|unattended|cloud-init|mandb|needrestart)/' >&2 || true
}

finish() {
  local status=$?
  trap - EXIT HUP INT TERM
  set +e
  if [ "$status" -ne 0 ]; then
    printf '[bootstrap] FAILED stage=%s exit=%s duration=%ss\n' \
      "$current_stage" "$status" "$((SECONDS - stage_started))" >&2
    diagnostics
  fi
  rm -f -- "$0"
  exit "$status"
}
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

run_stage() {
  current_stage=$1
  local limit=$2
  shift 2
  stage_started=$SECONDS
  printf '[bootstrap] START stage=%s limit=%ss command=' "$current_stage" "$limit" >&2
  printf '%q ' "$@" >&2
  printf '\n' >&2
  local status
  if timeout --kill-after=30s "$limit" "$@"; then
    status=0
  else
    status=$?
  fi
  printf '[bootstrap] END stage=%s exit=%s duration=%ss\n' \
    "$current_stage" "$status" "$((SECONDS - stage_started))" >&2
  if [ "$status" -eq 124 ]; then
    printf '[bootstrap] TIMEOUT stage=%s exceeded %ss; bootstrap stopped.\n' \
      "$current_stage" "$limit" >&2
  fi
  return "$status"
}

if command -v cloud-init >/dev/null 2>&1; then
  if run_stage cloud-init-wait 480 cloud-init status --wait; then
    cloud_init_status=0
  else
    cloud_init_status=$?
  fi
  case "$cloud_init_status" in
    0) ;;
    2) echo '::warning::Cloud-init finished with recoverable warnings; checking its final status.' ;;
    *) exit "$cloud_init_status" ;;
  esac
  current_stage='cloud-init-final-status'
  stage_started=$SECONDS
  echo '[bootstrap] Checking final cloud-init status (limit=20s).' >&2
  if cloud_init_details="$(timeout --kill-after=5s 20 cloud-init status --long 2>&1)"; then
    cloud_init_details_status=0
  else
    cloud_init_details_status=$?
  fi
  case "$cloud_init_details_status" in
    0|2) ;;
    *) printf '%s\n' "$cloud_init_details" >&2; exit "$cloud_init_details_status" ;;
  esac
  if ! grep -Eq '^[[:space:]]*status:[[:space:]]+done([[:space:]]|$)' <<< "$cloud_init_details"; then
    printf '%s\n' "$cloud_init_details" >&2
    echo 'Cloud-init must finish before installing application services.' >&2
    exit 1
  fi
fi

# APT/dpkg use fcntl locks: never remove their files or use flock as a substitute.
wait_for_package_locks() {
  local busy lock_path locked_paths
  while true; do
    busy=0
    if command -v fuser >/dev/null 2>&1; then
      for lock_path in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock \
        /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
        if [ -e "$lock_path" ] && fuser -s "$lock_path"; then
          busy=1
        fi
      done
    elif command -v lslocks >/dev/null 2>&1; then
      if ! locked_paths="$(lslocks --noheadings --notruncate --output PATH)"; then
        echo '[bootstrap] Could not read package-manager locks.' >&2
        return 1
      fi
      if grep -Eq '^[[:space:]]*/(var/lib/dpkg/lock(-frontend)?|var/lib/apt/lists/lock|var/cache/apt/archives/lock)[[:space:]]*$' <<< "$locked_paths"; then
        busy=1
      fi
    else
      echo '[bootstrap] Neither fuser nor lslocks is available; cannot safely check package-manager locks.' >&2
      return 1
    fi
    if [ "$busy" -eq 0 ]; then
      return 0
    fi
    echo '[bootstrap] Another package-manager process is active; waiting without removing its locks.' >&2
    sleep 5
  done
}
export -f wait_for_package_locks
run_stage package-lock-wait 180 bash -c wait_for_package_locks

# The observed apt-install timeout followed the man-db trigger message.
# Preseed its supported setting before reconfiguring or resuming interrupted dpkg.
export DEBIAN_FRONTEND=noninteractive
run_stage man-db-preseed 30 debconf-set-selections <<<'man-db man-db/auto-update boolean false'
current_stage='man-db-state'
stage_started=$SECONDS
man_db_state="$(dpkg-query -W '-f=${db:Status-Status}' man-db 2>/dev/null || true)"
case "$man_db_state" in
  installed|unpacked|half-configured|triggers-pending|triggers-awaited)
    run_stage man-db-reconfigure 180 dpkg-reconfigure --frontend=noninteractive --force man-db
    ;;
esac
current_stage='man-db-auto-update-check'
stage_started=$SECONDS
if [ -e /var/lib/man-db/auto-update ]; then
  echo '[bootstrap] man-db automatic indexing is still enabled after reconfiguration; refusing to resume dpkg.' >&2
  exit 1
fi

current_stage='dpkg-audit'
stage_started=$SECONDS
echo '[bootstrap] Checking for interrupted package configuration (limit=30s).' >&2
if dpkg_audit="$(timeout --kill-after=5s 30 dpkg --audit 2>&1)"; then
  :
else
  dpkg_audit_status=$?
  printf '%s\n' "$dpkg_audit" >&2
  exit "$dpkg_audit_status"
fi
# shellcheck disable=SC2016 # dpkg-query expands this format, not Bash.
package_states="$(timeout --kill-after=5s 30 dpkg-query -W '-f=${db:Status-Status}\n')"
if [ -n "$dpkg_audit" ] ||
  grep -Eq '^(unpacked|half-configured|half-installed|triggers-pending|triggers-awaited)$' <<< "$package_states"; then
  echo '[bootstrap] Resuming interrupted dpkg configuration with man-db indexing disabled.' >&2
  run_stage dpkg-recovery 600 dpkg --configure -a
else
  echo '[bootstrap] No interrupted package configuration; skipping dpkg recovery.' >&2
fi

current_stage='package-check'
stage_started=$SECONDS
missing_packages=()
for package in docker.io nginx ca-certificates curl; do
  if [ "$(dpkg-query -W '-f=${Status}' "$package" 2>/dev/null || true)" = 'install ok installed' ]; then
    printf '[bootstrap] Package already installed: %s\n' "$package" >&2
    continue
  fi
  if [ "$package" = docker.io ] && command -v docker >/dev/null 2>&1; then
    echo '[bootstrap] Using the existing Docker installation; not replacing it with docker.io.' >&2
    continue
  fi
  if [ "$package" = nginx ] && command -v nginx >/dev/null 2>&1; then
    echo '[bootstrap] Using the existing Nginx installation.' >&2
    continue
  fi
  if [ "$package" = docker.io ]; then
    for existing_package in docker-ce docker-ce-cli moby-engine moby-cli; do
      if [ "$(dpkg-query -W '-f=${Status}' "$existing_package" 2>/dev/null || true)" = 'install ok installed' ]; then
        echo 'An existing Docker CE/Moby package has no working Docker CLI; repair it before rerunning.' >&2
        exit 1
      fi
    done
  fi
  missing_packages+=("$package")
done

if [ "${#missing_packages[@]}" -gt 0 ]; then
  export DEBIAN_FRONTEND=noninteractive
  apt_options=(
    -o Acquire::Retries=3
    -o Acquire::http::Timeout=30
    -o Acquire::https::Timeout=30
    -o Acquire::ForceIPv4=true
    -o DPkg::Lock::Timeout=180
    -o Dpkg::Use-Pty=0
    -o Dpkg::Options::=--force-confdef
    -o Dpkg::Options::=--force-confold
  )
  run_stage apt-update 300 apt-get "${apt_options[@]}" -o APT::Update::Error-Mode=any update
  run_stage apt-install 600 apt-get "${apt_options[@]}" install -y --no-upgrade --no-install-recommends "${missing_packages[@]}"
else
  echo '[bootstrap] All required packages are installed; skipping apt update/install.' >&2
fi

run_stage docker-cli-check 15 docker --version
run_stage nginx-cli-check 15 nginx -v
run_stage docker-start 60 systemctl enable --now docker
run_stage docker-active 30 systemctl is-active --quiet docker
run_stage docker-info 30 docker info >/dev/null

current_stage='nginx-vhost'
stage_started=$SECONDS
# Manage only the packaged default and this exercise's own virtual host.
rm -f -- /etc/nginx/sites-enabled/default
if [ ! -e /etc/nginx/sites-available/cw03-pogoda ]; then
  cat > /etc/nginx/sites-available/cw03-pogoda <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    return 503;
}
NGINX
  chmod 644 /etc/nginx/sites-available/cw03-pogoda
fi
ln -sfn /etc/nginx/sites-available/cw03-pogoda /etc/nginx/sites-enabled/cw03-pogoda
run_stage nginx-config-check 30 nginx -t
run_stage nginx-start 60 systemctl enable --now nginx
run_stage nginx-reload 30 systemctl reload nginx
echo 'Docker and Nginx are ready; application credentials were not needed for bootstrap.'
