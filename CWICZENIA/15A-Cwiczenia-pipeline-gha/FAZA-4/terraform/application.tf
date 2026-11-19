# Terraform zarządza także uruchomieniem aplikacji. Błąd provisionera oznacza
# nieudany apply i ponowienie terraform_data, bez odtwarzania samej VM.
# Sekrety są ephemeral: nie trafiają do zapisanego planu ani do state.
resource "terraform_data" "application" {
  triggers_replace = [
    digitalocean_droplet.application.id,
    var.image_reference,
    var.deployment_id,
    filesha256("${path.module}/application.tf"),
  ]

  depends_on = [digitalocean_firewall.application]

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.application.ipv4_address
    private_key = tls_private_key.deployment.private_key_openssh
    host_key    = var.ssh_host_key
    timeout     = "10m"
    script_path = "/root/terraform-deploy-%RAND%.sh"
  }

  # Oddzielny provisioner bez sekretów zachowuje czytelną diagnostykę
  # cloud-init. Kod 2 oznacza ostrzeżenia i wymaga dodatkowego sprawdzenia.
  provisioner "remote-exec" {
    inline = [<<-BOOTSTRAP
      #!/usr/bin/env bash
      set -euo pipefail
      set +e
      timeout 480 cloud-init status --wait
      cloud_init_status=$?
      set -e
      case "$cloud_init_status" in
        0) ;;
        2)
          echo '::warning::Cloud-init zakończył się z ostrzeżeniami; sprawdzam stan i Docker.'
          cloud-init status --long || true
          ;;
        *)
          cloud-init status --long || true
          echo "Cloud-init nie zakończył bootstrapu poprawnie (kod $cloud_init_status)." >&2
          exit "$cloud_init_status"
          ;;
      esac
      cloud_init_details="$(cloud-init status --long 2>&1 || true)"
      if ! printf '%s\n' "$cloud_init_details" | grep -Eq '^[[:space:]]*status:[[:space:]]+done([[:space:]]|$)'; then
        printf '%s\n' "$cloud_init_details" >&2
        echo 'Cloud-init nie jest w stanie done.' >&2
        exit 1
      fi
      # Warnings from an invalid cloud-config can leave Docker uninstalled.
      # Reconcile the required packages only after cloud-init has finished.
      install_required=0
      for package in ca-certificates curl docker.io python3; do
        package_status="$(dpkg-query -W -f='$${Status}' "$package" 2>/dev/null || true)"
        if [ "$package_status" != 'install ok installed' ]; then
          echo "Required package is missing: $package"
          install_required=1
        fi
      done
      if ! command -v docker >/dev/null 2>&1; then
        install_required=1
      fi
      if [ "$install_required" -eq 1 ]; then
        export DEBIAN_FRONTEND=noninteractive
        if ! timeout 300 apt-get update; then
          echo 'Package index update failed; application deployment is stopped.' >&2
          exit 1
        fi
        if ! timeout 300 apt-get install -y --no-install-recommends ca-certificates curl docker.io python3; then
          echo 'Required package installation failed; application deployment is stopped.' >&2
          exit 1
        fi
      fi
      if ! command -v docker >/dev/null 2>&1; then
        echo 'Docker executable is missing after package installation.' >&2
        exit 1
      fi
      if ! systemctl enable --now docker; then
        systemctl status --no-pager docker || true
        echo 'Docker service could not be enabled or started.' >&2
        exit 1
      fi
      if ! systemctl is-active --quiet docker; then
        systemctl status --no-pager docker || true
        echo 'Docker service is not active after startup.' >&2
        exit 1
      fi
      if ! docker info >/dev/null; then
        echo 'Docker daemon does not respond to docker info.' >&2
        exit 1
      fi
      echo 'Cloud-init zakończony; Docker jest aktywny i odpowiada.'
    BOOTSTRAP
    ]
  }

  # Base64 chroni składnię powłoki przed znakami w sekretach, nie jest
  # szyfrowaniem. Skrypt leży w prywatnym /root i jest usuwany przy wyjściu.
  # Terraform ukrywa wyjście tego provisionera ze względu na sensitive vars.
  provisioner "remote-exec" {
    inline = [<<-DEPLOY
      #!/usr/bin/env bash
      set -euo pipefail
      umask 077
      chmod 600 -- "$0"
      DOCKER_CONFIG=''
      cleanup() {
        task_status=$?
        trap - EXIT
        if [ -n "$DOCKER_CONFIG" ]; then
          timeout 30 docker logout >/dev/null 2>&1 || true
          rm -f -- "$DOCKER_CONFIG/config.json"
          rmdir -- "$DOCKER_CONFIG" 2>/dev/null || true
        fi
        unset DOCKERHUB_TOKEN OPENWEATHER_API_KEY
        rm -f -- "$0"
        exit "$task_status"
      }
      trap cleanup EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM

      DOCKERHUB_USERNAME="$(printf '%s' '${base64encode(var.dockerhub_username)}' | base64 --decode)"
      DOCKERHUB_TOKEN="$(printf '%s' '${base64encode(var.dockerhub_token == null ? "" : var.dockerhub_token)}' | base64 --decode)"
      OPENWEATHER_API_KEY="$(printf '%s' '${base64encode(var.openweather_api_key == null ? "" : var.openweather_api_key)}' | base64 --decode)"
      IMAGE_REFERENCE="$(printf '%s' '${base64encode(var.image_reference == null ? "" : var.image_reference)}' | base64 --decode)"
      # Zachowujemy nazwę wcześniejszego deploya na tej VM, aby migracja
      # zastąpiła istniejący kontener korzystający z portu 80.
      CONTAINER_NAME='pogoda_api_faza4_${var.environment}'

      if [ -z "$DOCKERHUB_USERNAME" ] || [ -z "$DOCKERHUB_TOKEN" ] || [ -z "$OPENWEATHER_API_KEY" ]; then
        echo 'Brak loginu Docker Hub, tokenu lub klucza OpenWeather.' >&2
        exit 1
      fi
      if ! [[ "$IMAGE_REFERENCE" =~ ^[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$ ]]; then
        echo 'Wymagany jest obraz przypięty digestem SHA256.' >&2
        exit 1
      fi

      DOCKER_CONFIG="$(mktemp -d /root/pogoda-faza4-docker.XXXXXX)"
      chmod 700 "$DOCKER_CONFIG"
      export DOCKER_CONFIG OPENWEATHER_API_KEY
      printf '%s' "$DOCKERHUB_TOKEN" | timeout 60 docker login --username "$DOCKERHUB_USERNAME" --password-stdin
      unset DOCKERHUB_TOKEN

      # Nie usuwamy działającego kontenera, jeśli pobranie obrazu się nie uda.
      timeout 180 docker pull "$IMAGE_REFERENCE"
      existing_container="$(docker container ls --all --quiet --filter "name=^/$CONTAINER_NAME$")"
      if [ -n "$existing_container" ]; then
        docker rm --force "$existing_container"
      fi
      docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 80:8080 \
        -e OPENWEATHER_API_KEY \
        "$IMAGE_REFERENCE"
      unset OPENWEATHER_API_KEY

      curl --fail --silent --show-error \
        --retry 15 --retry-all-errors --retry-delay 2 \
        --retry-max-time 60 --max-time 5 \
        --output /dev/null \
        http://127.0.0.1/healthz
      test "$(docker inspect --format '{{.State.Running}}' "$CONTAINER_NAME")" = true
      echo 'Kontener aplikacji działa i endpoint gotowości odpowiada.'
    DEPLOY
    ]
  }
}
