#!/usr/bin/env python3
"""Klient API: użytkownik podaje tylko miasto, klucz pozostaje na serwerze."""

import argparse
import json
import os
import urllib.error
import urllib.parse
import urllib.request


def main() -> None:
    parser = argparse.ArgumentParser(description="Pobierz pogodę z uruchomionej aplikacji.")
    parser.add_argument("city", help="Nazwa miasta; nazwę ze spacjami umieść w cudzysłowach")
    parser.add_argument("--base-url", default=os.environ.get("WEATHER_BASE_URL", "http://localhost:18090"))
    args = parser.parse_args()
    url = args.base_url.rstrip("/") + "/api/weather?" + urllib.parse.urlencode({"city": args.city})
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        try:
            message = json.load(error).get("detail", "Błąd API pogody")
        except (ValueError, AttributeError):
            message = "Błąd API pogody"
        raise SystemExit(f"HTTP {error.code}: {message}") from None
    except urllib.error.URLError:
        raise SystemExit("Nie można połączyć się z aplikacją pogody.") from None
    print(json.dumps(data, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
