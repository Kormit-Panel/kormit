# GitHub Packages für Kormit

Diese Anleitung beschreibt, wie du auf die Docker Images von Kormit in der GitHub Container Registry zugreifen kannst.

## Voraussetzungen

1. Ein GitHub Konto
2. Ein Personal Access Token (PAT) mit `read:packages` Berechtigung, falls die Images privat sind

## Authentifizierung bei der GitHub Container Registry

Wenn die Kormit-Pakete öffentlich sind, kannst du ohne Authentifizierung auf sie zugreifen. 
Falls sie privat sind, musst du dich bei der GitHub Container Registry anmelden:

```bash
# Linux/macOS
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Windows (PowerShell)
$env:GITHUB_TOKEN | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin
```

Ersetze `$GITHUB_TOKEN` mit deinem Personal Access Token und `$GITHUB_USERNAME` mit deinem GitHub-Benutzernamen.

## Docker Images abrufen

Nach erfolgreicher Anmeldung kannst du die Images mit den folgenden Befehlen abrufen:

```bash
# Backend-Image
docker pull ghcr.io/kormit-panel/kormit/kormit-backend:latest

# Frontend-Image
docker pull ghcr.io/kormit-panel/kormit/kormit-frontend:latest
```

## Verfügbare Tags

Die folgenden Tags stehen zur Verfügung:

- `latest` - Die neueste Version des Images
- `sha-xxxxxxxx` - Ein spezifischer Commit
- `v1.x.x` - Release-Tags (z.B. v1.0.0)

## Verwendung in docker-compose.yml

In deiner `docker-compose.yml` kannst du die Images wie folgt verwenden:

```yaml
version: '3.8'

services:
  kormit-backend:
    image: ghcr.io/kormit-panel/kormit/kormit-backend:latest
    # weitere Konfiguration...
    
  kormit-frontend:
    image: ghcr.io/kormit-panel/kormit/kormit-frontend:latest
    # weitere Konfiguration...
```

## GitHub Actions Workflow

Der Workflow `.github/workflows/build.yml` baut und veröffentlicht die Docker Images automatisch. 
Es werden Images erstellt für:

1. Jeden Push zum `main` oder `master` Branch
2. Jede neue Pull Request (als Artefakt, nicht in die Registry gepusht)
3. Jedes neue Release (mit dem Release-Tag versehen)

Die Images werden mit verschiedenen Tags versehen, um verschiedene Versionen zu kennzeichnen. 