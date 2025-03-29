# Deployment 
 
Deployment configurations for Kormit. 
 
- `docker/` - Docker Compose configurations 
  - `production/` - Production deployment 
  - `development/` - Development deployment 
- `kubernetes/` - Kubernetes configurations 
- `scripts/` - Deployment scripts 

# Kormit Installationsanleitung

Dieses Verzeichnis enthält Skripte und Konfigurationen zur Installation von Kormit auf verschiedenen Plattformen.

## Schnellinstallation

### Linux (Ubuntu, Debian, CentOS, RHEL)

```bash
# Als Root-Benutzer ausführen
curl -fsSL https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.sh | sudo bash
```

Nach der Installation:

```bash
# Kormit starten
/opt/kormit/start.sh

# Kormit stoppen
/opt/kormit/stop.sh

# Kormit aktualisieren
/opt/kormit/update.sh
```

### Windows

1. PowerShell als Administrator starten
2. Installationsskript herunterladen und ausführen:

```powershell
# PowerShell als Administrator ausführen
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.ps1" -OutFile "$env:TEMP\install.ps1"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "$env:TEMP\install.ps1"
```

Nach der Installation:

```powershell
# Kormit starten
C:\kormit\start.ps1

# Kormit stoppen
C:\kormit\stop.ps1

# Kormit aktualisieren
C:\kormit\update.ps1
```

## Authentifizierung für private Repositories

Da Kormit in einem privaten Repository gehostet wird, benötigen Sie Anmeldedaten für den Zugriff auf die Docker-Images:

### Voraussetzungen

1. Ein GitHub-Konto mit Zugriff auf das Kormit-Repository
2. Ein Personal Access Token (PAT) mit `read:packages`-Berechtigung

### Token erstellen

1. Gehen Sie zu GitHub → Settings → Developer settings → Personal access tokens
2. Klicken Sie auf "Generate new token" (Classic)
3. Vergeben Sie einen Namen (z.B. "Kormit Docker")
4. Wählen Sie mindestens die Berechtigung `read:packages`
5. Klicken Sie auf "Generate token" und speichern Sie das Token sicher

### Manuelle Anmeldung

Die Installationsskripte enthalten eine interaktive Abfrage zur Authentifizierung. Falls Sie die manuelle Anmeldung bevorzugen:

```bash
# Linux
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Windows PowerShell
$env:GITHUB_TOKEN | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin
```

## Manuelle Installation

Falls Sie die Installation manuell durchführen möchten, folgen Sie diesen Schritten:

1. Stellen Sie sicher, dass Docker und Docker Compose installiert sind
2. Melden Sie sich bei GitHub Container Registry an (siehe oben)
3. Erstellen Sie ein Verzeichnis für Kormit:

```bash
# Linux
sudo mkdir -p /opt/kormit/docker/production
sudo mkdir -p /opt/kormit/docker/production/ssl
sudo mkdir -p /opt/kormit/docker/production/logs

# Windows (PowerShell als Administrator)
New-Item -Path "C:\kormit\docker\production\ssl" -ItemType Directory -Force
New-Item -Path "C:\kormit\docker\production\logs" -ItemType Directory -Force
```

4. Kopieren Sie die Konfigurationsdateien:

```bash
# Linux
sudo cp deploy/docker/production/docker-compose.yml /opt/kormit/docker/production/
sudo cp deploy/docker/production/nginx.conf /opt/kormit/docker/production/

# Windows
Copy-Item -Path "deploy\docker\production\docker-compose.yml" -Destination "C:\kormit\docker\production\"
Copy-Item -Path "deploy\docker\production\nginx.conf" -Destination "C:\kormit\docker\production\"
```

5. Erstellen Sie eine .env-Datei mit Ihren Konfigurationen:

```
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=sicheres_passwort_hier
DB_NAME=kormit
SECRET_KEY=sehr_sicherer_key_hier
DOMAIN_NAME=ihre-domain.com
TIMEZONE=Europe/Berlin
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network

# Image-Konfiguration 
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:main
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:main
```

6. Erstellen Sie ein SSL-Zertifikat
7. Starten Sie die Container:

```bash
# Linux
cd /opt/kormit/docker/production
docker compose up -d

# Windows
cd C:\kormit\docker\production
docker compose up -d
```

## Verwendung bestimmter Image-Versionen

Um eine bestimmte Version der Docker-Images zu verwenden, können Sie die folgenden Umgebungsvariablen setzen:

```bash
# Linux
export BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:main
export FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:main
docker compose up -d

# Windows (PowerShell)
$env:BACKEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-backend:main"
$env:FRONTEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-frontend:main"
docker compose up -d
```

Oder Sie können diese Variablen in der .env-Datei definieren:

```
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:main
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:main
```

## Zugriff auf Kormit

Nach erfolgreicher Installation können Sie auf Kormit zugreifen unter:

- https://server-ip oder https://ihre-domain.com

## Fehlerbehebung

### Zugriffsprobleme bei privaten Repositories

Wenn Sie Fehlermeldungen wie `ERROR: pull access denied` erhalten:

1. Überprüfen Sie, ob Sie korrekt bei ghcr.io angemeldet sind:
   ```bash
   docker login ghcr.io
   ```
2. Stellen Sie sicher, dass Ihr Token die richtigen Berechtigungen hat
3. Überprüfen Sie, ob Sie auf das Repository zugreifen können

### Allgemeine Probleme

Bei Problemen mit der Installation prüfen Sie bitte zunächst die Logs:

```bash
# Linux
docker compose -f /opt/kormit/docker/production/docker-compose.yml logs

# Windows
docker compose -f C:\kormit\docker\production\docker-compose.yml logs
```

Weitere Informationen finden Sie in der [Fehlerbehebung](docker/production/README.md#fehlerbehebung) der Produktionsdokumentation.
