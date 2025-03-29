# Kormit Produktions-Deployment

Dieses Verzeichnis enthält alles, was für die Bereitstellung von Kormit in einer Produktionsumgebung erforderlich ist.

## Voraussetzungen

- Docker und Docker Compose installiert auf dem Server
- Die Images für kormit-backend und kormit-frontend müssen verfügbar sein

## Schnellstart

1. **Konfiguration anpassen (Optional)**

   Konfigurationen können über Umgebungsvariablen angepasst werden:

   ```bash
   # Wenn Sie eigene Image-Versionen verwenden möchten
   export BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:v1.0.0
   export FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:v1.0.0
   ```

2. **Starten Sie Kormit**

   ```bash
   docker-compose up -d
   ```

   Alle Dienste (Datenbank, Backend, Frontend, Proxy) werden gestartet und miteinander verbunden.

3. **Überprüfen Sie den Status**

   ```bash
   docker-compose ps
   ```

   Alle Dienste sollten als "Up" angezeigt werden.

4. **Zugriff auf Kormit**

   Öffnen Sie einen Webbrowser und navigieren Sie zu:
   - `http://server-ip/` für die Web-Oberfläche
   - `http://server-ip/api` für die API

## Verwendung mit eigenen Images

Wenn Sie die Docker-Images bereits lokal haben oder aus Artefakten laden möchten:

1. **Images laden**

   ```bash
   # Wenn die Images als .tar-Dateien vorliegen
   docker load -i kormit-backend.tar
   docker load -i kormit-frontend.tar
   
   # Tags anpassen, falls erforderlich
   docker tag [image-id] ghcr.io/kormit-panel/kormit/kormit-backend:latest
   docker tag [image-id] ghcr.io/kormit-panel/kormit/kormit-frontend:latest
   ```

2. **Docker Compose starten wie oben beschrieben**

## SSL konfigurieren

Um SSL zu aktivieren:

1. Legen Sie Ihre SSL-Zertifikate in das `ssl`-Verzeichnis:
   - `ssl/cert.pem` (Zertifikat)
   - `ssl/key.pem` (Privater Schlüssel)

2. Bearbeiten Sie die `nginx.conf` und entkommentieren Sie die SSL-Konfiguration.

## Aktualisierung

Um auf eine neue Version zu aktualisieren:

```bash
# Neue Images ziehen
docker pull ghcr.io/kormit-panel/kormit/kormit-backend:latest
docker pull ghcr.io/kormit-panel/kormit/kormit-frontend:latest

# Services neu starten
docker-compose down
docker-compose up -d
``` 