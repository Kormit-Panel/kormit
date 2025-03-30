<div align="center">
  
![Kormit](https://github.com/user-attachments/assets/f6cde4d5-05e9-4bde-a860-9cb15efeea02)

# Kormit

### Lightweight All-in-One Admin Management Panel

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/Kormit-Panel/kormit/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](CONTRIBUTING.md)
[![Docker](https://img.shields.io/badge/docker-ready-informational)](https://github.com/Kormit-Panel/kormit/packages)
[![Build Status](https://img.shields.io/badge/build-passing-success)](https://github.com/Kormit-Panel/kormit/actions)
[![Go](https://img.shields.io/badge/go-1.21%2B-00ADD8)](https://go.dev/)
[![Vue](https://img.shields.io/badge/vue-3.x-42b883)](https://vuejs.org/)

</div>

## 🌟 Features

- 🚀 **Hochperformant** - Gebaut mit Go und Vue.js für maximale Leistung
- 🔒 **Sicher** - Moderne Sicherheitsstandards und regelmäßige Updates
- 🔄 **Einfache Verwaltung** - Intuitive Benutzeroberfläche für alle Administrationsaufgaben
- 🌐 **Multi-Plattform** - Läuft auf Linux, Windows und macOS
- 📦 **Docker-Ready** - Einfache Bereitstellung mit Docker und Docker Compose
- 🛠️ **Anpassbar** - Flexibel konfigurierbar für unterschiedliche Anwendungsfälle
- 🔌 **Erweiterbar** - Modulare Architektur für einfache Erweiterungen

## 📋 Inhaltsverzeichnis

- [Überblick](#-überblick)
- [Schnellstart](#-schnellstart)
- [Installation](#-installation)
  - [Automatische Installation](#automatische-installation)
  - [Manuelle Installation](#manuelle-installation)
  - [Docker Compose](#docker-compose)
- [Konfiguration](#-konfiguration)
- [Verwendung](#-verwendung)
- [Entwicklung](#-entwicklung)
- [Beitragen](#-beitragen)
- [Häufige Fragen](#-häufige-fragen)
- [Fehlersuche](#-fehlersuche)
- [Lizenz](#-lizenz)

## 👀 Überblick

Kormit ist ein leichtgewichtiges, aber leistungsstarkes Administrations-Panel für moderne Anwendungen. Es vereint einen Go-Backend mit einer reaktiven Vue.js-Frontend-Oberfläche und bietet eine vollständige Lösung für die Systemverwaltung.

<div align="center">
  <img src="/api/placeholder/800/450" alt="Kormit Dashboard Screenshot" width="800"/>
</div>

## 🚀 Schnellstart

Der schnellste Weg, um Kormit zu starten:

```bash
# Automatische Installation
curl -sSL https://github.com/Kormit-Panel/kormit/raw/refs/heads/main/deploy/kormit-setup.sh | sudo bash

# Nach der Installation, starte Kormit
sudo kormit
```

Nach der Installation ist Kormit unter `http://localhost` (oder `https://localhost`) erreichbar.

## 📥 Installation

### Automatische Installation

Die einfachste Methode, um Kormit zu installieren, ist unser automatisches Setup-Skript:

```bash
curl -sSL https://github.com/Kormit-Panel/kormit/raw/refs/heads/main/deploy/kormit-setup.sh | sudo bash
```

Das Skript überprüft alle Abhängigkeiten, lädt die neueste Version herunter und richtet alles für dich ein.

<div align="center">
  <img src="/api/placeholder/700/400" alt="Kormit Setup Process" width="700"/>
</div>

### Manuelle Installation

#### Voraussetzungen

- Git
- Docker und Docker Compose
- (Optional) Go 1.21+ für Entwicklung
- (Optional) Node.js 20+ für Frontend-Entwicklung

#### Installations-Schritte

1. Repository klonen:
   ```bash
   git clone https://github.com/Kormit-Panel/kormit.git
   cd kormit
   ```

2. Installation starten:
   ```bash
   sudo ./deploy/install.sh
   ```

3. Kormit starten:
   ```bash
   sudo /opt/kormit/start.sh
   ```

### Docker Compose

Du kannst Kormit auch direkt mit Docker Compose starten:

```bash
# Produktionsumgebung
docker-compose -f deploy/docker/production/docker-compose.yml up -d

# Entwicklungsumgebung
docker-compose -f deploy/docker/development/docker-compose.yml up
```

## ⚙️ Konfiguration

Kormit lässt sich über Umgebungsvariablen oder eine Konfigurationsdatei anpassen.

### Wichtige Konfigurationsoptionen

| Parameter | Beschreibung | Standard |
|-----------|--------------|----------|
| `DOMAIN_NAME` | Domain für Zugriff | `localhost` |
| `HTTP_PORT` | HTTP Port | `80` |
| `HTTPS_PORT` | HTTPS Port | `443` |
| `DB_USER` | Datenbank Benutzer | `kormit_user` |
| `DB_PASSWORD` | Datenbank Passwort | Zufällig generiert |
| `SECRET_KEY` | App Secret Key | Zufällig generiert |

Für eine vollständige Liste der Konfigurationsoptionen siehe den [Konfigurations-Leitfaden](deploy/docker/production/README.md).

## 🖥️ Verwendung

Nach der erfolgreichen Installation kannst du Kormit über deinen Webbrowser unter der konfigurierten URL (standardmäßig `http://localhost`) erreichen.

### Management-Befehle

```bash
# Kormit starten
sudo kormit

# Kormit-Status prüfen
sudo kormit status

# Logs anzeigen
sudo kormit logs

# Kormit aktualisieren
sudo kormit update
```

<div align="center">
  <img src="/api/placeholder/800/500" alt="Kormit Management Interface" width="800"/>
</div>

## 💻 Entwicklung

Für Entwickler, die an Kormit arbeiten möchten:

### Entwicklungsumgebung einrichten

```bash
# Repository klonen
git clone https://github.com/Kormit-Panel/kormit.git
cd kormit

# Entwicklungsmodus starten
./build.sh run-dev
```

Oder unter Windows:

```bash
build.bat run-dev
```

Die Entwicklungsumgebung bietet:
- Hot-Reload für Frontend-Änderungen
- Automatische Backend-Neustarts bei Code-Änderungen
- Entwicklungs-Tools und Debug-Logging

### Projektstruktur

```
kormit/
├── backend/             # Go Backend
│   ├── api/            # API Routes und Handlers
│   ├── auth/           # Authentifizierung
│   ├── config/         # Konfiguration
│   └── cmd/kormit/     # Hauptanwendung
├── frontend/            # Vue.js Frontend
│   ├── src/            # Quellcode
│   ├── public/         # Statische Dateien
│   └── tests/          # Frontend-Tests
├── deploy/              # Deployment-Konfigurationen
│   ├── docker/         # Docker-Konfigurationen
│   └── scripts/        # Deployment-Skripte
└── scripts/             # Build- und Hilfsskripte
```

## 🤝 Beitragen

Wir freuen uns über Beiträge aller Art! Schau dir unsere [Beitragsrichtlinien](CONTRIBUTING.md) an, um zu erfahren, wie du zum Projekt beitragen kannst.

- 🐛 Fehler melden und beheben
- ✨ Neue Features vorschlagen und implementieren
- 📚 Dokumentation verbessern
- 🧪 Tests hinzufügen

## ❓ Häufige Fragen

<details>
<summary><b>Welche Anforderungen hat Kormit?</b></summary>
Kormit ist darauf ausgelegt, mit minimalen Systemanforderungen zu laufen. Es benötigt Docker, mindestens 1GB RAM und 10GB freien Speicherplatz.
</details>

<details>
<summary><b>Wie aktualisiere ich Kormit auf die neueste Version?</b></summary>
Wenn du die automatische Installation verwendet hast, führe einfach <code>sudo kormit update</code> aus. Bei manueller Installation, navigiere zum Installationsverzeichnis und führe <code>./update.sh</code> aus.
</details>

<details>
<summary><b>Kann ich Kormit ohne Docker verwenden?</b></summary>
Derzeit wird Kormit hauptsächlich für Docker-Umgebungen entwickelt, aber eine Docker-lose Installation ist für zukünftige Versionen geplant.
</details>

<details>
<summary><b>Wo finde ich die Logs?</b></summary>
Die Logs befinden sich unter <code>/opt/kormit/docker/production/logs/</code> oder können mit <code>sudo kormit logs</code> angezeigt werden.
</details>

## 🛠️ Fehlersuche

Bei Problemen mit Kormit:

1. Prüfe die Logs: `sudo kormit logs`
2. Stelle sicher, dass alle Abhängigkeiten installiert sind: `sudo kormit check`
3. Repariere die Installation falls nötig: `sudo kormit repair`

Weitere Fehlerbehebungs-Tipps findest du in der [Produktions-README](deploy/docker/production/README.md).

## 📜 Lizenz

[MIT](LICENSE)

---

<div align="center">
  <p>
    Made with ❤️ by the Kormit Team
  </p>
  <p>
    <img src="https://github.com/user-attachments/assets/931f382c-085e-4061-9825-f42b0ac50b40" alt="Kormit Logo Footer" width="400"/>
  </p>
</div>
