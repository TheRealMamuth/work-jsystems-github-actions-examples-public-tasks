group "default" {
  targets = ["web"]
}

target "web" {
  context    = "DODATKOWE/docker-bake-actions-01"
  dockerfile = "DODATKOWE/docker-bake-actions-01/Dockerfile"


  # Multi-arch (opcjonalnie) – możesz zostawić jedną platformę dla szybkości
  platforms = ["linux/amd64", "linux/arm64"]

  # Domyślne tagi (nadpisze je metadata-action przez bake-file-tags)
  tags = ["piotrskoska/github-action-test:local"]

  # Cache do GitHub Actions (szybkie buildy)
  cache-from = ["type=gha"]
  cache-to   = ["type=gha,mode=max"]

  # Build args → ENV w Dockerfile
  args = {
    NGINX_VERSION = "1.27-alpine"
    APP_NAME      = "demo-nginx"
    APP_ENV       = "ci"
    IMAGE_VERSION = "0.1.0"  # zostanie nadpisane tagami/annotacjami z metadata
  }

  # (opcjonalnie) dodatkowe, ręczne annotations – będą scalone z tymi z metadata-action
  # annotations = ["org.opencontainers.image.vendor=HelpPointIT"]
}
