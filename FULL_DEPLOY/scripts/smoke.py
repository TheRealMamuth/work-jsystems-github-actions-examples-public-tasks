"""Check the running image over HTTP; never call an external weather service."""
import json
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

base = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:18000"
for attempt in range(60):
    try:
        with urlopen(f"{base}/health", timeout=3) as response:
            assert response.status == 200
            assert json.load(response) == {"status": "ok"}
        break
    except (URLError, TimeoutError, ConnectionError):
        if attempt == 59:
            raise
        time.sleep(1)

with urlopen(f"{base}/openapi.json", timeout=3) as response:
    assert "/weather" in json.load(response)["paths"]

for path, expected in [("/weather", 422), ("/weather?city=Warsaw", 400)]:
    try:
        urlopen(f"{base}{path}", timeout=3)
    except HTTPError as error:
        assert error.code == expected, (path, error.code)
    else:
        raise AssertionError(f"Expected HTTP {expected}: {path}")
print("Container HTTP checks passed")
