FROM python:3.12-slim

# Ustawiamy katalog roboczy
WORKDIR /app

# Kopiujemy pliki zależności
COPY requirements.txt .

# Instalujemy zależności
RUN pip install --no-cache-dir -r requirements.txt

# Kopiujemy resztę aplikacji
COPY . .

# Zmienna środowiskowa (opcjonalnie)
ENV PYTHONUNBUFFERED=1

# Domyślny port
EXPOSE 8000

# Komenda startowa - FastAPI przez uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
