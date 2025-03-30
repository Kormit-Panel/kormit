# Kormit - Einfache Installationsanleitung

Diese Anleitung ermöglicht es Ihnen, Kormit mit einem einfachen Befehl zu installieren.

## 1. Installation mit curl

Kopieren Sie den folgenden Befehl und führen Sie ihn in Ihrem Terminal aus:

```bash
curl -sSL https://beispiel.com/kormit-setup.sh | sudo bash
```

Ersetzen Sie `https://beispiel.com/kormit-setup.sh` mit der tatsächlichen URL, unter der Sie das Setup-Skript gehostet haben.

## 2. Nach der Installation

Nach der Installation können Sie Kormit mit einem der folgenden Befehle verwenden:

- `sudo kormit` - Der systemweite Befehl
- `sudo /opt/kormit/kormit-manager.sh` - Direkter Aufruf des Manager-Skripts

## 3. Verfügbare Funktionen

- Abhängigkeiten prüfen (Docker, Git)
- Kormit installieren
- Kormit starten/stoppen/neustarten
- Kormit aktualisieren
- Logs anzeigen
- Status prüfen
- Und mehr...

## 4. Tipps

- Das Skript benötigt root-Rechte für die Installation und Verwaltung
- Standardmäßig wird Kormit in `/opt/kormit` installiert
- Für Probleme oder Fehler, starten Sie das Reparatur-Tool über das Hauptmenü
