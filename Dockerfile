# Dockerfile illustrant de mauvaises pratiques courantes
# Mauvaise pratique 1 : aucune version, aucune variante slim, base très large
FROM python

# Mauvaise pratique 2 : pas de WORKDIR clair / absolu au début
RUN mkdir app
WORKDIR app

# Mauvaise pratique 3 :
# - utilisation de ADD au lieu de COPY
# - copie du requirements avec tout le contexte
# - pas de .dockerignore, on copie tout le contexte
ADD . .

# Mauvaise pratique 4 : installation de paquets système inutiles
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        vim \
        curl

# Mauvaise pratique 5 : dépendances non pinées, installation après ADD .
# => invalide le cache à chaque changement de code et rend le build lent
RUN pip install -r requirements.txt.bad

# Mauvaise pratique 6 : variables "sensibles" en dur dans l'image
ENV SECRET_KEY="super-secret-key" \
    DATABASE_URL="postgres://user:password@localhost:5432/db" \
    FLASK_ENV=development

# Mauvaise pratique 7 : on tourne en root (par défaut) sans user dédié
# - aucun USER non-root défini


# Mauvaise pratique 8 : utiliser le serveur de dev Flask (via python app.py)
# en mode debug, au lieu d’un WSGI type gunicorn pour la "prod"
# et cmd en forme shell, moins explicite
CMD ["python", "app.py"]
