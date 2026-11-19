#!/bin/bash
set -euo pipefail

if [ -z "${OPENWEATHER_API_KEY:-}" ]; then
  echo "Brak OPENWEATHER_API_KEY. Przekaż klucz dopiero w docker run -e OPENWEATHER_API_KEY." >&2
  exit 1
fi

mkdir -p /tmp/weather-nginx
python - <<'PY'
import json
import os
from pathlib import Path

config = Path('/app/nginx/nginx.conf').read_text()
cert = os.environ.get('TLS_CERT_FILE', '')
key = os.environ.get('TLS_KEY_FILE', '')
if bool(cert) != bool(key):
    raise SystemExit('HTTPS wymaga jednocześnie TLS_CERT_FILE i TLS_KEY_FILE.')
tls_server = ''
if cert and key:
    for path in (cert, key):
        if not Path(path).is_file() or not os.access(path, os.R_OK):
            raise SystemExit('Nie można odczytać zamontowanego certyfikatu lub klucza TLS.')
        if any(character in path for character in ('\n', '\r', '\x00')):
            raise SystemExit('Nieprawidłowa ścieżka pliku TLS.')
    tls_server = """server {
        listen 8443 ssl;
        server_name _;
        ssl_certificate %s;
        ssl_certificate_key %s;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_session_cache shared:WEATHER_TLS:1m;
        include /app/nginx/proxy.conf;
    }""" % (json.dumps(cert), json.dumps(key))
Path('/tmp/weather-nginx/nginx.conf').write_text(config.replace('# OPTIONAL_TLS_SERVER', tls_server))
PY

nginx -t -c /tmp/weather-nginx/nginx.conf

api_pid=''
nginx_pid=''
# shellcheck disable=SC2329 # Funkcja jest wywoływana pośrednio przez trap.
cleanup() {
  trap - TERM INT EXIT
  if [ -n "$nginx_pid" ]; then kill -QUIT "$nginx_pid" 2>/dev/null || true; fi
  if [ -n "$api_pid" ]; then kill -TERM "$api_pid" 2>/dev/null || true; fi
  wait 2>/dev/null || true
}
trap 'cleanup; exit 0' TERM INT
trap cleanup EXIT

uvicorn app:app --host 127.0.0.1 --port 8000 \
  --proxy-headers --forwarded-allow-ips 127.0.0.1 &
api_pid=$!
nginx -c /tmp/weather-nginx/nginx.conf -g 'daemon off;' &
nginx_pid=$!

# Awaria dowolnego procesu kończy kontener i uruchamia politykę restartu Dockera.
status=0
wait -n "$api_pid" "$nginx_pid" || status=$?
if [ "$status" -eq 0 ]; then status=1; fi
exit "$status"
