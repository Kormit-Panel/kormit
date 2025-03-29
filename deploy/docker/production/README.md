# Kormit Produktionsumgebung

Dieses Verzeichnis enthält die notwendigen Dateien, um Kormit in einer Produktionsumgebung zu betreiben.

## Voraussetzungen

- Linux-Server mit Docker und Docker Compose
- Offene Ports 80 und 443
- Gültiges SSL-Zertifikat (für HTTPS)

## Schnellstart

1. Führen Sie das Installationsskript aus:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/kormit/main/deploy/install.sh | sudo bash
```

2. Nach Abschluss der Installation starten Sie Kormit mit:

```bash
/opt/kormit/start.sh
```

3. Greifen Sie auf das Dashboard zu unter: https://your-server-ip

## Manuelle Installation

Wenn Sie die manuelle Installation bevorzugen, folgen Sie diesen Schritten:

1. Erstellen Sie ein .env-File mit den folgenden Umgebungsvariablen:

```
DB_USER=kormit_user
DB_PASSWORD=sichere_passwort_hier
DB_NAME=kormit
SECRET_KEY=sehr_sicherer_secret_key_hier
DOMAIN_NAME=ihre-domain.com
TIMEZONE=Europe/Berlin
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
```

2. Erstellen Sie ein SSL-Zertifikat für Ihre Domain (oder verwenden Sie Let's Encrypt):

```bash
# Selbstsigniertes Zertifikat (nur für Tests)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/kormit.key \
    -out ssl/kormit.crt
```

3. Erstellen Sie die notwendigen Verzeichnisse:

```bash
mkdir -p ssl logs
```

4. Starten Sie die Container:

```bash
docker-compose up -d
```

## Konfiguration

### Umgebungsvariablen

| Variable | Beschreibung | Standardwert |
|----------|--------------|--------------|
| `DB_USER` | PostgreSQL-Benutzername | user |
| `DB_PASSWORD` | PostgreSQL-Passwort | pass |
| `DB_NAME` | PostgreSQL-Datenbankname | kormit |
| `SECRET_KEY` | Geheimer Schlüssel für die Anwendung | production-secret-key-replace-this |
| `DOMAIN_NAME` | Domainname für Nginx | localhost |
| `TIMEZONE` | Zeitzone des Servers | UTC |
| `HTTP_PORT` | HTTP-Port | 80 |
| `HTTPS_PORT` | HTTPS-Port | 443 |
| `VOLUME_PREFIX` | Präfix für Docker-Volumes | kormit |
| `NETWORK_NAME` | Name des Docker-Netzwerks | kormit-network |

### SSL-Zertifikate

Legen Sie Ihre SSL-Zertifikate im Verzeichnis `ssl` ab:

- `ssl/kormit.crt`: Das Zertifikat
- `ssl/kormit.key`: Der private Schlüssel

Für Produktionsumgebungen empfehlen wir die Verwendung von Let's Encrypt.

## Wartung

### Updates

Um Kormit zu aktualisieren:

```bash
cd /opt/kormit/docker/production
docker-compose pull
docker-compose up -d
```

### Backups

Es wird empfohlen, regelmäßige Backups der Datenbank durchzuführen:

```bash
cd /opt/kormit/docker/production
docker-compose exec kormit-db pg_dump -U $DB_USER -d $DB_NAME -c -f /tmp/kormit_backup.sql
docker cp kormit-db:/tmp/kormit_backup.sql /path/to/backup/location/
```

### Logs

Die Logs befinden sich im Verzeichnis `logs`:

- `logs/access.log`: Nginx-Zugriffslogs
- `logs/error.log`: Nginx-Fehlerlogs
- `logs/access.ssl.log`: Nginx-Zugriffslogs für HTTPS
- `logs/error.ssl.log`: Nginx-Fehlerlogs für HTTPS

Um Container-Logs anzuzeigen:

```bash
docker-compose logs -f [service-name]
```

## Fehlerbehebung

### Container startet nicht

Überprüfen Sie die Logs:

```bash
docker-compose logs kormit-backend
docker-compose logs kormit-frontend
docker-compose logs kormit-proxy
```

### Datenbankverbindung fehlgeschlagen

Überprüfen Sie die Umgebungsvariablen in der .env-Datei und stellen Sie sicher, dass die Datenbankanmeldedaten korrekt sind.

### SSL-Fehler

Überprüfen Sie, ob die SSL-Zertifikate korrekt platziert sind und die Berechtigungen stimmen:

```bash
chmod 600 ssl/kormit.key
chmod 644 ssl/kormit.crt
```

## Support

Bei Fragen oder Problemen öffnen Sie bitte ein Issue auf GitHub oder kontaktieren Sie uns unter support@example.com. 