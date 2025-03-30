# Deployment 
 
Deployment configurations for Kormit. 
 
- `docker/` - Docker Compose configurations 
  - `production/` - Production deployment 
  - `development/` - Development deployment 
- `kubernetes/` - Kubernetes configurations 
- `scripts/` - Deployment scripts 

# Kormit Deployment-Dokumentation

## Schnellinstallation

### Linux/MacOS

Mit diesem Befehl können Sie Kormit direkt von unserem Repository installieren:

```bash
curl -sSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install_curl.sh | bash
```

Für benutzerdefinierte Optionen:

```bash
curl -sSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install_curl.sh | bash -s -- --domain=example.com --install-dir=/opt/kormit --auto-start
```

### Windows (PowerShell)

Öffnen Sie PowerShell als Administrator und führen Sie diesen Befehl aus:

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install_curl.ps1')
```

Für benutzerdefinierte Optionen:

```powershell
$script = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install_curl.ps1'); 
Invoke-Expression "$script -DomainName example.com -InstallDir C:\kormit -AutoStart"
```

## Universeller Installationsbefehl

Mit diesem Befehl erkennt das System automatisch Ihr Betriebssystem und wählt den passenden Installer:

```bash
curl -sSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install.sh | bash
```

Dieser Befehl funktioniert auf Linux und macOS direkt. Unter Windows wird die empfohlene PowerShell-Syntax angezeigt.

# Kormit Installationsanleitung

Dieses Verzeichnis enthält Skripte und Konfigurationen zur Installation von Kormit auf verschiedenen Plattformen.

## Schnellinstallation

### Linux (Ubuntu, Debian, CentOS, RHEL)

```bash
# Standard-Installation (interaktiv)
curl -fsSL https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.sh | sudo bash

# Mit GitHub-Token (nicht-interaktiv)
curl -fsSL https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.sh | sudo bash -s -- --username=GITHUB_USERNAME --token=GITHUB_TOKEN --auto-start
```

Parameter für das Linux-Installationsskript:

| Parameter | Beschreibung | Standardwert |
|-----------|--------------|--------------|
| `--username=NAME` | GitHub-Benutzername für die Authentifizierung | - |
| `--token=TOKEN` | GitHub Personal Access Token | - |
| `--install-dir=DIR` | Installationsverzeichnis | `/opt/kormit` |
| `--domain=DOMAIN` | Domain-Name oder IP-Adresse | `localhost` |
| `--auto-start` | Kormit nach der Installation automatisch starten | - |
| `--help` | Hilfe anzeigen | - |

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
# Standard-Installation (interaktiv)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.ps1" -OutFile "$env:TEMP\install.ps1"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "$env:TEMP\install.ps1"

# Mit GitHub-Token (nicht-interaktiv)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.ps1" -OutFile "$env:TEMP\install.ps1"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "$env:TEMP\install.ps1" -GitHubUsername "GITHUB_USERNAME" -GitHubToken "GITHUB_TOKEN" -AutoStart
```

Parameter für das Windows-Installationsskript:

| Parameter | Beschreibung | Standardwert |
|-----------|--------------|--------------|
| `-GitHubUsername` | GitHub-Benutzername für die Authentifizierung | - |
| `-GitHubToken` | GitHub Personal Access Token | - |
| `-InstallDir` | Installationsverzeichnis | `C:\kormit` |
| `-DomainName` | Domain-Name oder IP-Adresse | `localhost` |
| `-AutoStart` | Kormit nach der Installation automatisch starten | - |
| `-Help` | Hilfe anzeigen | - |

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

### Anmeldung über die Kommandozeile

Sie können das GitHub-Token direkt bei der Installation als Parameter übergeben:

```bash
# Linux
curl -fsSL https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.sh | sudo bash -s -- --username=GITHUB_USERNAME --token=GITHUB_TOKEN

# Windows PowerShell
& "$env:TEMP\install.ps1" -GitHubUsername "GITHUB_USERNAME" -GitHubToken "GITHUB_TOKEN"
```

Alternativ können Sie sich manuell anmelden:

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

## Schnellstart und Verwaltung

Sobald Kormit installiert ist, können Sie das Schnellstart-Skript verwenden, um es einfach zu verwalten:

### Linux/MacOS

```bash
curl -sSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/quick_start.sh | bash
```

### Windows (PowerShell)

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/quick_start.ps1')
```

Das Schnellstart-Skript bietet ein einfaches Menü zur Verwaltung Ihrer Kormit-Installation:
- Starten
- Stoppen
- Aktualisieren
- Status anzeigen

## Änderungen in Version 1.1.5

- **Start-Skript-Fehler vollständig behoben**: Vollständige Bereinigung der Skript-Datei von allen problematischen Kommentaren.
- **Neues Reparatur-Tool**: Hinzufügung eines Hilfsskripts, um fehlerhafte Start-Skripte automatisch zu korrigieren.
- **Verbesserte Zuverlässigkeit**: Optimierung der Skript-Generierung für maximale Kompatibilität.

## Änderungen in Version 1.1.4

- **Start-Skript-Korrektur**: Entfernung von Kommentaren, die fälschlicherweise in das Start-Skript kopiert wurden und es funktionsunfähig machten.
- **Verbesserte Skript-Bereinigung**: Optimierung des Installationsskripts, um unerwünschtes Übertragen von Kommentaren zu verhindern.

## Änderungen in Version 1.1.3

- **Pfadproblem behoben**: Korrektur eines Fehlers, der dazu führte, dass der falsche Installationspfad in den abschließenden Meldungen angezeigt wurde.
- **Skript-Variable verbessert**: Umbenennung der `RESULT`-Variable zu `EXIT_CODE` für bessere Klarheit und um Konflikte zu vermeiden.
- **Pfadbehandlung verbessert**: Korrekte Anführungszeichen bei Pfadverwendung für bessere Unterstützung von Pfaden mit Leerzeichen.

## Änderungen in Version 1.1.2

- **Verbesserte SSL-Zertifikatserstellung**: Robustere Methode zur Erstellung von SSL-Zertifikaten, die mit allen OpenSSL-Versionen kompatibel ist.
- **Bessere Fehlerbehandlung**: Mehrere Fallback-Methoden für den Fall, dass die primäre Zertifikatserstellung fehlschlägt.
- **Automatisches Failover**: Bei Fehlern wird automatisch auf einfachere Zertifikatsmethoden zurückgegriffen.
- **Ubuntu 24.04 Unterstützung**: Behebt Probleme mit neueren Ubuntu-Versionen.
- **HTTP-only Option**: Neue Option `--http-only` für Installationen ohne HTTPS.

## Änderungen in Version 1.1.0

- **SSL-Zertifikat-Fix**: Die Erstellung der selbstsignierten SSL-Zertifikate wurde verbessert und ist jetzt kompatibel mit verschiedenen OpenSSL-Versionen.
- **Verbesserte Sicherheit**: Verwendung von SHA-256 für Zertifikate und Hinzufügung von 'localhost' als alternativer Name.
- **Automatische Anpassung**: Das Installationsskript erkennt die OpenSSL-Version und wählt die passende Methode zur Zertifikatserstellung.

## Fehlerbehebung für bestehende Installationen

Wenn Ihre Kormit-Installation ein fehlerhaftes Start-Skript hat, können Sie es mit diesem Befehl reparieren:

```bash
sudo curl -sSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/fix_start_script.sh | sudo bash
```

Alternativ können Sie das Start-Skript manuell korrigieren:

```bash
sudo bash -c 'cat > /opt/kormit/start.sh << EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist unter http://localhost erreichbar."
EOL'
sudo chmod +x /opt/kormit/start.sh
```

## HTTP-only Modus

Wenn Sie Kormit ohne HTTPS betreiben möchten (z.B. hinter einem Reverse-Proxy oder für Testzwecke), können Sie den HTTP-only-Modus verwenden:

### Linux/MacOS

```bash
curl -sSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install_curl.sh | bash -s -- --http-only
```

### Windows (PowerShell)

```powershell
$script = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/scripts/install_curl.ps1'); 
Invoke-Expression "$script -HttpOnly"
```

Im HTTP-only-Modus:
- Es wird kein SSL-Zertifikat erstellt
- Nginx wird nur auf Port 80 ausgeführt
- Es gibt keine Umleitung von HTTP auf HTTPS
- Die Installation ist einfacher und vermeidet mögliche SSL-Konfigurationsprobleme

**Hinweis:** Für Produktionsumgebungen wird die Verwendung von HTTPS dringend empfohlen.
