# Kormit

Ein modernes Panel zur Verwaltung von Entwicklungsumgebungen und Servern mit Backend in Go und Frontend in Vue.js.

## Hauptfeatures

- **Containerisierte Anwendungsverwaltung**: Steuern und Überwachen von Docker-Containern
- **Server-Monitoring**: Echtzeit-Überwachung von CPU, RAM, Festplatten und Netzwerk
- **Benutzerfreundliches Dashboard**: Modernes UI für einfache Verwaltung aller Dienste
- **Automatisierte Bereitstellung**: One-Click-Deployment von Anwendungen
- **Multi-Server-Support**: Verwaltung mehrerer Server von einer zentralen Oberfläche
- **Einfache Installation**: Schnelle Installation mit nur einem Befehl
- **Sicherheit**: SSL/TLS-Unterstützung und Benutzerauthentifizierung

## Anforderungen

- Docker und Docker Compose
- Linux, Windows oder macOS
- Go 1.24.1 (nur für lokale Entwicklung)
- Node.js 16 (nur für lokale Frontend-Entwicklung)

## Schnellstart

### Installation über Skript

```bash
# Linux
curl -fsSL https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/install.sh | sudo bash

# Windows (PowerShell als Administrator)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/install.ps1" -OutFile "$env:TEMP\install.ps1"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "$env:TEMP\install.ps1"
```

### Manuelle Installation mit Docker

```bash
# Anmelden bei GitHub Container Registry (ein Token mit read:packages-Berechtigung wird benötigt)
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Docker-Images direkt verwenden
docker pull ghcr.io/kormit-panel/kormit/kormit-backend:latest
docker pull ghcr.io/kormit-panel/kormit/kormit-frontend:latest

# Mit Docker Compose
wget https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/docker/production/docker-compose.yml
docker compose up -d
```

## Entwicklung

Das Projekt verwendet ein einfaches Batch-Skript für häufige Operationen:

```bash
# Zeigt verfügbare Befehle an
build help

# Startet die Entwicklungsumgebung
build run-dev

# Baut das Projekt
build build

# Führt Tests aus
build test

# Bereinigt Build-Artefakte
build clean

# Baut Docker-Images
build docker-build

# Startet die Produktionsumgebung
build docker-run
```

### Backend (Go)

Das Backend ist unter `/backend` zu finden und verwendet Go 1.24.1. Es bietet eine REST-API für die Verwaltung von Containern, Server-Monitoring und mehr.

### Frontend (Vue.js)

Das Frontend ist unter `/frontend` zu finden und bietet eine moderne, reaktionsfähige Benutzeroberfläche mit Dashboard-Ansichten, Monitoring-Graphen und Container-Management.

## Deployment

### Docker Images

Kormit steht als Docker Images in der GitHub Container Registry zur Verfügung:

- `ghcr.io/kormit-panel/kormit/kormit-backend:latest` - Neueste Version des Backends
- `ghcr.io/kormit-panel/kormit/kormit-frontend:latest` - Neueste Version des Frontends
- `ghcr.io/kormit-panel/kormit/kormit-backend:{tag}` - Bestimmte Versionen (z.B. v1.0.0)
- `ghcr.io/kormit-panel/kormit/kormit-frontend:{tag}` - Bestimmte Versionen (z.B. v1.0.0)

### GitHub Actions

Das Projekt enthält einen GitHub-Workflow, der automatisch Docker-Images baut und zur GitHub Container Registry pusht, wenn:
- Ein Push zum Hauptbranch erfolgt
- Eine Pull-Request erstellt wird
- Ein neues Release veröffentlicht wird

### Manuelles Deployment

Detaillierte Anweisungen findest du in der [Deployment-Dokumentation](deploy/README.md).

## Architektur

- **Backend**: Go 1.24.1, REST-API mit Docker-Integration und PostgreSQL-Datenbankanbindung
- **Frontend**: Vue.js mit modernem UI, Dashboard und Grafiken
- **Datenbank**: PostgreSQL für Datenpersistenz
- **Proxy**: Nginx für SSL-Terminierung und Routing

## Beitragen

Wir freuen uns über Beiträge! Bitte lies unsere [Beitragsrichtlinien](CONTRIBUTING.md) für weitere Informationen.

## Lizenz

[MIT](LICENSE) 
