#!/bin/bash
# Kormit Installation Script
# Installiert die Kormit-Anwendung mit Docker Compose
# Version 1.0.0

set -e

# Farbdefinitionen
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m' # No Color

# Standardwerte
INSTALL_DIR="/opt/kormit"
DOMAIN_NAME="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
HTTP_ONLY=true  # Standardmäßig nur HTTP verwenden

# Hilfefunktion
show_help() {
    echo "Verwendung: $0 [Optionen]"
    echo ""
    echo "Optionen:"
    echo "  --install-dir=DIR    Installationsverzeichnis (Standard: /opt/kormit)"
    echo "  --domain=DOMAIN      Domain-Name oder IP-Adresse (Standard: localhost)"
    echo "  --http-port=PORT     HTTP-Port (Standard: 80)"
    echo "  --https-port=PORT    HTTPS-Port (Standard: 443, nur mit --use-https)"
    echo "  --use-https          HTTPS aktivieren (Standard: deaktiviert)"
    echo "  --http-only          Nur HTTP verwenden (Standard: aktiviert)"
    echo "  --help               Diese Hilfe anzeigen"
    echo ""
    exit 0
}

# Parameter verarbeiten
for i in "$@"; do
    case $i in
        --install-dir=*)
            INSTALL_DIR="${i#*=}"
            ;;
        --domain=*)
            DOMAIN_NAME="${i#*=}"
            ;;
        --http-port=*)
            HTTP_PORT="${i#*=}"
            ;;
        --https-port=*)
            HTTPS_PORT="${i#*=}"
            ;;
        --use-https)
            HTTP_ONLY=false
            ;;
        --http-only)
            HTTP_ONLY=true
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unbekannte Option: $i"
            show_help
            ;;
    esac
done

echo -e "${BLUE}
   _  __                    _ _   
  | |/ /___  _ __ _ __ ___ (_) |_ 
  | ' // _ \| '__| '_ \` _ \| | __|
  | . \ (_) | |  | | | | | | | |_ 
  |_|\_\___/|_|  |_| |_| |_|_|\__|
${RESET}"

echo -e "${GREEN}Kormit Installation Tool${RESET}\n"

echo -e "${CYAN}▶ Installationsdetails:${RESET}"
echo -e "  - Installationsverzeichnis: ${INSTALL_DIR}"
echo -e "  - Domain-Name: ${DOMAIN_NAME}"
echo -e "  - HTTP-Port: ${HTTP_PORT}"
if [ "$HTTP_ONLY" = false ]; then
    echo -e "  - HTTPS-Port: ${HTTPS_PORT}"
    echo -e "  - Protokoll: HTTP & HTTPS"
else
    echo -e "  - Protokoll: Nur HTTP"
fi

# Verzeichnisstruktur erstellen
echo -e "\n${CYAN}▶ Erstelle Verzeichnisstruktur...${RESET}"
mkdir -p "${INSTALL_DIR}/docker/production"
mkdir -p "${INSTALL_DIR}/docker/production/logs"
mkdir -p "${INSTALL_DIR}/docker/production/ssl"

# Docker-Compose-Datei kopieren
echo -e "${CYAN}▶ Kopiere Docker-Compose-Konfiguration...${RESET}"
cp $(dirname "$0")/docker/production/docker-compose.yml "${INSTALL_DIR}/docker/production/"

# Nginx-Konfiguration kopieren
echo -e "${CYAN}▶ Kopiere Nginx-Konfiguration...${RESET}"
cp $(dirname "$0")/docker/production/nginx.conf "${INSTALL_DIR}/docker/production/"

# Erstelle .env-Datei
echo -e "${CYAN}▶ Erstelle Umgebungsvariablen-Datei...${RESET}"

# Generiere zufällige Passwörter
DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
SECRET_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)

# Bekannte korrekte Image-Pfade
BACKEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-backend:main"
FRONTEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-frontend:main"

# Erstelle .env-Datei
cat > "${INSTALL_DIR}/docker/production/.env" << EOL
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=kormit
SECRET_KEY=${SECRET_KEY}
DOMAIN_NAME=${DOMAIN_NAME}
TIMEZONE=UTC
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}

# Image-Konfiguration
BACKEND_IMAGE=${BACKEND_IMAGE}
FRONTEND_IMAGE=${FRONTEND_IMAGE}
EOL

# HTTPS-Konfiguration
if [ "$HTTP_ONLY" = false ]; then
    echo -e "${CYAN}▶ Aktiviere HTTPS und erstelle SSL-Zertifikat...${RESET}"
    
    # Erstelle selbstsigniertes Zertifikat
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${INSTALL_DIR}/docker/production/ssl/kormit.key" \
        -out "${INSTALL_DIR}/docker/production/ssl/kormit.crt" \
        -subj "/CN=${DOMAIN_NAME}" -addext "subjectAltName=DNS:${DOMAIN_NAME}"
    
    # Modifiziere die HTTP-Konfiguration, um auf HTTPS weiterzuleiten
    # Ersetze den HTTP-Standort-Block mit einer Umleitung zu HTTPS
    sed -i '/# HTTP-Handling - wird durch das Installationsskript konfiguriert/,/location \/ {/!b; /location \/ {/a\
        return 301 https://$host$request_uri;' "${INSTALL_DIR}/docker/production/nginx.conf"
    
    # Entferne alle Zeilen zwischen "location / {" und dem nächsten "}"
    sed -i '/# HTTP-Handling.*konfiguriert/,/location \/ {/!b; /location \/ {/,/}/{//!d}' "${INSTALL_DIR}/docker/production/nginx.conf"
    
    echo -e "${GREEN}✅ HTTPS wurde aktiviert und ein selbstsigniertes SSL-Zertifikat wurde erstellt.${RESET}"
    echo -e "${YELLOW}⚠️ Hinweis: Da es sich um ein selbstsigniertes Zertifikat handelt, werden Browser eine Warnung anzeigen.${RESET}"
else
    echo -e "${CYAN}▶ Verwende nur HTTP (kein HTTPS)...${RESET}"
    
    # Erstelle leere Zertifikatsdateien für Nginx
    touch "${INSTALL_DIR}/docker/production/ssl/kormit.key"
    touch "${INSTALL_DIR}/docker/production/ssl/kormit.crt"
    
    # Entferne den HTTPS-Port aus der docker-compose.yml
    sed -i '/- "${HTTPS_PORT:-443}:443"/d' "${INSTALL_DIR}/docker/production/docker-compose.yml"
    
    echo -e "${GREEN}✅ HTTP-only Modus wurde konfiguriert.${RESET}"
fi

# Erstelle Hilfsskripte
echo -e "${CYAN}▶ Erstelle Management-Skripte...${RESET}"

# Start-Skript
cat > "${INSTALL_DIR}/start.sh" << 'EOL'
#!/bin/bash
cd $(dirname $0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist erreichbar."
EOL
chmod +x "${INSTALL_DIR}/start.sh"

# Stop-Skript
cat > "${INSTALL_DIR}/stop.sh" << 'EOL'
#!/bin/bash
cd $(dirname $0)/docker/production
docker compose down
echo "Kormit wurde gestoppt."
EOL
chmod +x "${INSTALL_DIR}/stop.sh"

# Update-Skript
cat > "${INSTALL_DIR}/update.sh" << 'EOL'
#!/bin/bash
cd $(dirname $0)/docker/production
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL
chmod +x "${INSTALL_DIR}/update.sh"

echo -e "${GREEN}✅ Management-Skripte wurden erstellt.${RESET}"

# Frage, ob Kormit direkt gestartet werden soll
echo -e "\n${CYAN}▶ Installation abgeschlossen!${RESET}"
echo -e "${YELLOW}Möchten Sie Kormit jetzt starten? (J/n)${RESET}"
read -p "> " start_now

if [[ ! "$start_now" =~ ^[nN]$ ]]; then
    echo -e "${CYAN}▶ Starte Kormit...${RESET}"
    "${INSTALL_DIR}/start.sh"
    
    # Server-IP oder Domain anzeigen
    if [ "$DOMAIN_NAME" = "localhost" ]; then
        SERVER_IP=$(hostname -I | awk '{print $1}')
        ACCESS_URL="$SERVER_IP"
    else
        ACCESS_URL="$DOMAIN_NAME"
    fi
    
    echo -e "\n${GREEN}✅ Kormit wurde erfolgreich installiert und gestartet!${RESET}"
    echo -e "${CYAN}Sie können nun auf Kormit zugreifen unter:${RESET}"
    
    if [ "$HTTP_ONLY" = true ]; then
        echo -e "  http://${ACCESS_URL}:${HTTP_PORT}"
    else
        echo -e "  https://${ACCESS_URL}:${HTTPS_PORT}"
    fi
else
    echo -e "\n${GREEN}✅ Kormit wurde erfolgreich installiert!${RESET}"
    echo -e "${CYAN}Verwenden Sie '${INSTALL_DIR}/start.sh', um Kormit zu starten.${RESET}"
fi

echo -e "\n${YELLOW}Hinweis: Das Standard-Admin-Passwort finden Sie in der ersten Log-Ausgabe nach dem Start.${RESET}"
echo -e "${YELLOW}Verwenden Sie '${INSTALL_DIR}/update.sh', um Kormit in Zukunft zu aktualisieren.${RESET}"

exit 0
