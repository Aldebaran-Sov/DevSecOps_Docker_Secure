# Good Dockerfile example following best practices
# Image explicite, légère
FROM python:3.12-slim@sha256:fa48eefe2146644c2308b909d6bb7651a768178f84fc9550dcd495e4d6d84d01

# Labels (optionnel mais propre)
LABEL maintainer="ton-email@example.com" \
      description="Flask app dockerisée avec bonnes pratiques"

# Créer utilisateur non-root
RUN useradd -m -u 1001 appuser

# Dossier de travail clair
WORKDIR /app

# Dépendances en premier pour profiter du cache
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copier le code applicatif
COPY . .

# Donner les bons droits au user applicatif
RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 5000

# Healthcheck sur l'endpoint Flask /health
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Utiliser Gunicorn (WSGI) plutôt que le serveur de dev Flask
# "app:app" = fichier app.py / variable app = Flask(...)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]