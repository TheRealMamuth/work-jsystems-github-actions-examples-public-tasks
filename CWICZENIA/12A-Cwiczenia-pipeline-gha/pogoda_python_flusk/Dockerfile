FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 weather \
    && useradd --uid 10001 --gid weather --no-create-home weather

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Lista dozwolonych plików: .env, certyfikaty i testy nie trafiają do obrazu.
COPY --chown=10001:10001 app.py start-container.sh ./
COPY --chown=10001:10001 nginx/ ./nginx/
COPY --chown=10001:10001 static/ ./static/
RUN chmod 0555 /app/start-container.sh

# OPENWEATHER_API_KEY jest przekazywany tylko w docker run -e, bez ARG/ENV w build.
USER 10001:10001
EXPOSE 8080 8443
HEALTHCHECK --interval=15s --timeout=5s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=3)"
ENTRYPOINT ["/app/start-container.sh"]
