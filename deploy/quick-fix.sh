#!/usr/bin/env bash
# Kormit Quick-Fix-Skript
# Behebt häufige Probleme mit der Kormit-Installation
# Version 1.0.0

# Fehlerbehandlung aktivieren
set -eo pipefail

# Farbdefinitionen
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Standardwerte
INSTALL_DIR="/opt/kormit"

# Prüfe, ob ein anderes Installationsverzeichnis angegeben wurde
if [[ "$1" != "" ]]; then
    INSTALL_DIR="$1"
fi

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║                                                                ║${RESET}"
echo -e "${CYAN}║                  Kormit Quick-Fix-Tool                         ║${RESET}"
echo -e "${CYAN}║                                                                ║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
echo -e "${CYAN}▶ Installationsverzeichnis: ${RESET}${INSTALL_DIR}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${RESET}"

# Prüfe, ob das Installationsverzeichnis existiert
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${RED}❌ Das Installationsverzeichnis existiert nicht.${RESET}"
    echo -e "${YELLOW}Bitte überprüfen Sie den Pfad oder installieren Sie Kormit.${RESET}"
    exit 1
fi

# 1. SSL-Probleme beheben
echo -e "${BLUE}▶ SSL-Probleme werden behoben...${RESET}"

# Stelle sicher, dass das SSL-Verzeichnis existiert
mkdir -p "$INSTALL_DIR/docker/production/ssl"

# Stelle sicher, dass leere SSL-Zertifikate vorhanden sind
touch "$INSTALL_DIR/docker/production/ssl/kormit.key"
touch "$INSTALL_DIR/docker/production/ssl/kormit.crt"

# Sicherungskopie der nginx.conf erstellen, falls noch nicht vorhanden
if [[ ! -f "$INSTALL_DIR/docker/production/nginx.conf.bak" ]]; then
    cp "$INSTALL_DIR/docker/production/nginx.conf" "$INSTALL_DIR/docker/production/nginx.conf.bak"
    echo -e "${GREEN}✅ Sicherungskopie der Nginx-Konfiguration erstellt.${RESET}"
fi

# Nginx-Konfiguration auf HTTP-only umstellen
echo -e "${BLUE}▶ Nginx-Konfiguration wird auf HTTP-only umgestellt...${RESET}"

# Neue HTTP-only Konfiguration
cat > "$INSTALL_DIR/docker/production/nginx.conf" << 'EOL'
# Kormit Nginx Konfiguration
# HTTP-only Version

log_format kormit_log '$remote_addr - $remote_user [$time_local] '
                     '"$request" $status $body_bytes_sent '
                     '"$http_referer" "$http_user_agent" "$http_x_forwarded_for"';

# Upstream-Definitionen für Load Balancing
upstream kormit_backend {
    server kormit-backend:8080;
}

upstream kormit_frontend {
    server kormit-frontend:80;
}

# HTTP-Server
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    
    access_log /var/log/nginx/access.log kormit_log;
    error_log /var/log/nginx/error.log warn;
    
    # Client-Body-Größe erhöhen für Uploads
    client_max_body_size 50M;
    
    # Gzip-Kompression aktivieren
    gzip on;
    gzip_types text/plain text/css application/javascript application/json application/xml;
    gzip_min_length 1000;
    
    # Cache-Header für statische Assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        access_log off;
        
        # Erst Frontend für statische Assets prüfen
        proxy_pass http://kormit_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend-Routing (Vue Router History Mode)
    location / {
        proxy_pass http://kormit_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Wichtig für Vue Router History Mode
        try_files $uri $uri/ /index.html;
    }
    
    # API-Anfragen zum Backend weiterleiten
    location /api/ {
        proxy_pass http://kormit_backend/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS-Header hinzufügen
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Preflight-Anfragen behandeln
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Origin, X-Requested-With, Content-Type, Accept, Authorization' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Timeout-Einstellungen für API-Anfragen
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }
    
    # Websocket-Support für Live-Updates
    location /ws {
        proxy_pass http://kormit_backend/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Gesundheitscheck-Endpunkt
    location /health {
        add_header Content-Type text/plain;
        return 200 'OK';
    }
}
EOL

echo -e "${GREEN}✅ Nginx-Konfiguration wurde auf HTTP-only umgestellt.${RESET}"

# Entferne HTTPS-Port aus der docker-compose.yml
echo -e "${BLUE}▶ Docker-Compose-Konfiguration wird angepasst...${RESET}"

# Sichere docker-compose.yml, falls nicht bereits gesichert
if [[ ! -f "$INSTALL_DIR/docker/production/docker-compose.yml.bak" ]]; then
    cp "$INSTALL_DIR/docker/production/docker-compose.yml" "$INSTALL_DIR/docker/production/docker-compose.yml.bak"
    echo -e "${GREEN}✅ Sicherungskopie der Docker-Compose-Datei erstellt.${RESET}"
fi

# Kommentiere den HTTPS-Port aus
sed -i 's/- "${HTTPS_PORT:-443}:443"/#- "${HTTPS_PORT:-443}:443"/' "$INSTALL_DIR/docker/production/docker-compose.yml"

echo -e "${GREEN}✅ Docker-Compose-Konfiguration wurde angepasst.${RESET}"

# 2. Container neustarten
echo -e "${BLUE}▶ Container werden neugestartet...${RESET}"

cd "$INSTALL_DIR/docker/production" || {
    echo -e "${RED}❌ Konnte nicht in das Verzeichnis $INSTALL_DIR/docker/production wechseln.${RESET}"
    exit 1
}

# Stoppe und starte die Container neu
docker compose down
docker compose up -d

echo -e "${GREEN}✅ Container wurden neugestartet.${RESET}"

echo -e "${CYAN}════════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}✅ Reparatur abgeschlossen!${RESET}"
echo -e "${CYAN}▶ Überprüfen Sie den Status mit:${RESET} cd $INSTALL_DIR/docker/production && docker compose ps"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${RESET}"

exit 0