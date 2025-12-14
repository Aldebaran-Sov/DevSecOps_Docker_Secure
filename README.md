# DevSecOps_Docker_Secure

Repo pédagogique pour apprendre à écrire des Dockerfiles **sécurisés** en partant d’un Dockerfile volontairement mauvais puis en appliquant des **bonnes pratiques** pour l’améliorer.

### Objectifs

- Identifier les mauvaises pratiques courantes lors de la containerisation d’une app Python/Flask.
- Appliquer les bonnes pratiques Docker (cache, `.dockerignore`, base image minimale, etc.).
- Mettre en place un build “production-like” (WSGI + non-root + healthcheck).


## Application Flask

- `/` : endpoint simple
- `/health` : endpoint de healthcheck (utilisé par Docker HEALTHCHECK / monitoring)[web:28]

## Dockerfiles

### Dockerfile.bad (anti‑patterns)

- Base image trop grosse / tag non déterministe.
- Tout copié sans `.dockerignore`.
- Dépendances non optimisées pour le cache (rebuild lent).
- Paquets inutiles installés.
- Secrets en dur (exemple pédagogique).
- Exécution en root.
- Serveur Flask de dev en debug au lieu d’un WSGI.

### Dockerfile (bonnes pratiques)

- Base image explicite et plus petite (ex: `python:X.Y-slim`)
- `.dockerignore` pour limiter le contexte envoyé au build.
- `COPY requirements.txt` puis `pip install` avant `COPY . .` pour tirer parti du cache
- User non-root (moindre privilège)
- Gunicorn (WSGI) pour exécuter Flask
- Healthcheck fiable sans dépendre de `curl` (souvent absent des images slim)

## Build des images

Depuis la racine du repo :

```zsh
docker build -f Dockerfile.bad -t flask-demo:bad .
docker build -f Dockerfile -t flask-demo:good .
```

## Comparaison des images

La taille des images :

```zsh
docker images
```

| Image | Taille |
|-------|--------|
| flask-demo:bad |  1.2GB |
| flask-demo:good |  133MB |

### Scan des images avec Trivy

Si Trivy n’a pas accès au socket Docker.

Sauvegarde des images en tar :

```zsh
docker save flask-demo:bad -o flask-bad.tar

docker save flask-demo:good -o flask-good.tar
```
Scan des images avec Trivy :

```zsh
trivy image --input flask-bad.tar --format json -o trivy-bad.json

trivy image --input flask-good.tar --format json -o trivy-good.json
```

Résumé des vulnérabilités par sévérité (jq utilisé pour parser le JSON) :

```zsh
jq -r '
  [ .Results[].Vulnerabilities[]? | .Severity ] 
  | group_by(.) 
  | map({severity: .[0], count: length})
' trivy-bad.json

jq -r '
  [ .Results[].Vulnerabilities[]? | .Severity ] 
  | group_by(.) 
  | map({severity: .[0], count: length})
' trivy-good.json
```


| Image | High | Medium | Low |
|-------|------|--------|-----|
| flask-demo:bad |  123 |  272 |  730 |
| flask-demo:good |  0 |  11 |  52 |

## Script d’automatisation
Un script bash `script/scan_trivy.sh` est fourni pour automatiser le build des images, leur sauvegarde en tar, le scan Trivy et la génération d’un rapport markdown `Scan_Trivy.md`.

**Attention** : si vous avez fait les commandes manuelement sans passer par le script, supprimez les fichiers générés (`flask-bad.tar`, `flask-good.tar`, `trivy-bad.json`, `trivy-good.json`) avant d'exécuter le script pour éviter les taille de containers incohérentes dans le rapport.


```zsh
chmod +x script/scan_trivy.sh
./script/scan_trivy.sh
```

## Ressources

- https://docs.docker.com/build/building/best-practices/
- https://snyk.io/blog/best-practices-containerizing-python-docker/
- https://blog.stephane-robert.info/docs/securiser/outils/trivy/

