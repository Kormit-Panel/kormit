# Kormit

Ein modernes Entwicklungstool-Projekt mit Backend in Go und Frontend in Vue.js.

## Anforderungen

- Docker und Docker Compose
- Go 1.24.1 (für lokale Entwicklung)
- Node.js 16 (für lokale Frontend-Entwicklung)

## Schnellstart

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

## Entwicklung

### Backend (Go)

Das Backend ist unter `/backend` zu finden und verwendet Go 1.24.1. Es bietet eine REST-API, die vom Frontend konsumiert wird.

### Frontend (Vue.js)

Das Frontend ist unter `/frontend` zu finden und verwendet Vue.js mit einem modernen UI.

## Deployment

### GitHub Actions

Das Projekt enthält einen GitHub-Workflow, der automatisch Docker-Images baut und in die GitHub Container Registry pusht, wenn:
- Ein Push zum Hauptbranch erfolgt
- Eine Pull-Request erstellt wird
- Ein neues Release veröffentlicht wird

### Manuelles Deployment

```bash
# Docker-Images bauen
build docker-build

# Docker-Container starten
build docker-run
```

## Architektur

- **Backend**: Go 1.24.1, REST-API mit Datenbankanbindung
- **Frontend**: Vue.js mit modernem UI
- **Datenbank**: PostgreSQL für Datenpersistenz

## Lizenz

[MIT](LICENSE) 
