"use strict";

(() => {
  const form = document.getElementById("weather-form");
  const input = document.getElementById("city");
  const button = document.getElementById("search-button");
  const buttonLabel = document.getElementById("button-label");
  const status = document.getElementById("live-status");
  const errorBox = document.getElementById("error-message");
  const errorText = document.getElementById("error-text");
  const emptyState = document.getElementById("empty-state");
  const emptyTitle = document.getElementById("empty-title");
  const emptyDescription = document.getElementById("empty-description");
  const result = document.getElementById("weather-result");
  const numberFormat = new Intl.NumberFormat("pl-PL", { maximumFractionDigits: 1 });
  let activeRequest = null;
  let requestNumber = 0;

  function write(id, value) {
    document.getElementById(id).textContent = value;
  }

  function finite(value) {
    return typeof value === "number" && Number.isFinite(value);
  }

  function measurement(id, value, unit, fractionDigits = 0) {
    const element = document.getElementById(id);
    element.replaceChildren();
    if (!finite(value)) {
      element.textContent = "Brak danych";
      return;
    }
    const formatted = new Intl.NumberFormat("pl-PL", { maximumFractionDigits: fractionDigits }).format(value);
    element.append(document.createTextNode(formatted));
    const suffix = document.createElement("span");
    suffix.className = "unit";
    suffix.textContent = unit;
    element.append(suffix);
  }

  function localDate(timestamp, offset) {
    if (!finite(timestamp)) return null;
    return new Date((timestamp + (finite(offset) ? offset : 0)) * 1000);
  }

  function localTime(timestamp, offset) {
    const date = localDate(timestamp, offset);
    return date && Number.isFinite(date.getTime())
      ? new Intl.DateTimeFormat("pl-PL", { hour: "2-digit", minute: "2-digit", timeZone: "UTC" }).format(date)
      : "Brak danych";
  }

  function countryName(code) {
    if (typeof code !== "string" || !code.trim()) return "Aktualna pogoda";
    try {
      return new Intl.DisplayNames(["pl"], { type: "region" }).of(code.toUpperCase()) || code;
    } catch {
      return code;
    }
  }

  function symbolFor(code, isDay) {
    if (code >= 200 && code < 300) return "weather-storm";
    if (code >= 300 && code < 600) return "weather-rain";
    if (code >= 600 && code < 700) return "weather-snow";
    if (code >= 700 && code < 800) return "weather-mist";
    if (code === 800) return isDay ? "weather-sun" : "weather-moon";
    if (code === 801 || code === 802) return isDay ? "weather-partly-cloudy" : "weather-night-cloud";
    return "weather-cloud";
  }

  function renderWeather(weather) {
    if (!weather || typeof weather.city !== "string" || !finite(weather.temperature)) {
      throw new Error("invalid-response");
    }
    write("result-city", weather.city);
    write("result-country", countryName(weather.country));
    const date = localDate(weather.observed_at, weather.timezone_offset);
    write("result-date", date && Number.isFinite(date.getTime())
      ? new Intl.DateTimeFormat("pl-PL", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" }).format(date)
      : "Aktualna pogoda");
    write("temperature", String(Math.round(weather.temperature)));
    write("weather-description", typeof weather.description === "string" ? weather.description : "Aktualne warunki");
    write("feels-like", finite(weather.feels_like) ? `${numberFormat.format(weather.feels_like)}°C` : "Brak danych");
    write("day-label", weather.is_day ? "Dzień" : "Noc");
    write("observation-time", `Pomiar o ${localTime(weather.observed_at, weather.timezone_offset)}`);
    measurement("humidity", weather.humidity, "%");
    measurement("wind", finite(weather.wind_speed) ? weather.wind_speed * 3.6 : null, "km/h", 1);
    measurement("pressure", weather.pressure, "hPa");
    measurement("visibility", finite(weather.visibility) ? weather.visibility / 1000 : null, "km", 1);
    write("sunrise", localTime(weather.sunrise, weather.timezone_offset));
    write("sunset", localTime(weather.sunset, weather.timezone_offset));
    write("clouds", finite(weather.clouds) ? `${numberFormat.format(weather.clouds)}%` : "Brak danych");
    document.getElementById("weather-symbol").setAttribute("href", `#${symbolFor(weather.condition_code, weather.is_day)}`);
    document.querySelector(".current-weather").classList.toggle("is-night", !weather.is_day);
    emptyState.hidden = true;
    result.hidden = false;
    status.textContent = `Pogoda w mieście ${weather.city}: ${numberFormat.format(weather.temperature)} stopni Celsjusza. ${weather.description || ""}`;
  }

  function setLoading(city) {
    errorBox.hidden = true;
    result.hidden = true;
    emptyState.hidden = false;
    emptyState.classList.add("is-loading");
    emptyTitle.textContent = "Sprawdzamy pogodę…";
    emptyDescription.textContent = `Szukamy aktualnych danych dla miasta ${city}. Jeszcze chwila i możesz planować dzień.`;
    button.disabled = true;
    button.classList.add("is-loading");
    buttonLabel.textContent = "Sprawdzamy…";
    form.setAttribute("aria-busy", "true");
    status.textContent = `Sprawdzamy pogodę dla miasta ${city}.`;
  }

  function showError(message) {
    errorText.textContent = message;
    errorBox.hidden = false;
    emptyState.hidden = false;
    result.hidden = true;
    emptyTitle.textContent = "Spróbujmy jeszcze raz.";
    emptyDescription.textContent = "Sprawdź nazwę miasta lub wybierz inne miejsce. Twoja pogoda jest o jedno wyszukanie stąd.";
    status.textContent = "Nie udało się wyświetlić pogody.";
  }

  async function lookup(city) {
    const ownRequest = ++requestNumber;
    if (activeRequest) activeRequest.abort();
    const controller = new AbortController();
    activeRequest = controller;
    let timedOut = false;
    const timeout = window.setTimeout(() => {
      timedOut = true;
      controller.abort();
    }, 20000);
    setLoading(city);

    try {
      const parameters = new URLSearchParams({ city });
      const response = await fetch(`/api/weather?${parameters.toString()}`, {
        signal: controller.signal,
        headers: { Accept: "application/json" },
        cache: "no-store",
      });
      const payload = await response.json().catch(() => null);
      if (ownRequest !== requestNumber) return;
      if (!response.ok) {
        const message = payload && typeof payload.detail === "string"
          ? payload.detail
          : response.status === 422
            ? "Sprawdź nazwę miasta i spróbuj ponownie."
            : "Nie udało się pobrać pogody. Spróbuj ponownie za chwilę.";
        showError(message);
        return;
      }
      renderWeather(payload);
    } catch (error) {
      if (ownRequest !== requestNumber) return;
      if (timedOut) {
        showError("Pobieranie pogody trwa zbyt długo. Spróbuj ponownie za chwilę.");
      } else if (error instanceof Error && error.message === "invalid-response") {
        showError("Otrzymaliśmy niepełne dane pogodowe. Spróbuj ponownie za chwilę.");
      } else {
        showError("Nie możemy teraz połączyć się z pogodą. Sprawdź połączenie i spróbuj ponownie.");
      }
    } finally {
      window.clearTimeout(timeout);
      if (ownRequest === requestNumber) {
        activeRequest = null;
        button.disabled = false;
        button.classList.remove("is-loading");
        buttonLabel.textContent = "Sprawdź pogodę";
        emptyState.classList.remove("is-loading");
        form.removeAttribute("aria-busy");
      }
    }
  }

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const city = input.value.trim();
    input.setCustomValidity(city ? "" : "Podaj nazwę miasta.");
    if (!form.reportValidity()) return;
    input.value = city;
    lookup(city);
  });
  input.addEventListener("input", () => input.setCustomValidity(""));
  document.querySelectorAll("[data-city]").forEach((chip) => {
    chip.addEventListener("click", () => {
      input.value = chip.dataset.city;
      input.setCustomValidity("");
      lookup(chip.dataset.city);
    });
  });
})();
