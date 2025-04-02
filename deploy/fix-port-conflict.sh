#!/bin/bash
# Port-Konflikt-Behebung für Kormit

# Farben für Ausgaben
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Überprüfen, ob das Skript als Root ausgeführt wird
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${RED}Dieses Skript muss als root ausgeführt werden.${RESET}"
  echo "Bitte mit 'sudo' erneut starten."
  exit 1
fi

echo -e "${CYAN}Kormit Port-Konflikt-Behebung${RESET}"
echo "=============================="
echo ""

# Prüfe, ob Port 80 bereits belegt ist
echo -e "${YELLOW}Prüfe, ob Port 80 bereits belegt ist...${RESET}"
if netstat -tulpn | grep -q ':80 '; then
    echo -e "${RED}Port 80 ist bereits belegt!${RESET}"
    echo "Folgende Prozesse verwenden Port 80:"
    netstat -tulpn | grep ':80 '
    
    # Frage, ob auf Port 8090 umgestellt werden soll
    echo ""
    echo -e "${YELLOW}Möchten Sie Kormit auf Port 8090 umstellen? (j/n)${RESET}"
    read -r response
    if [[ "$response" =~ ^[jJ]$ ]]; then
        # Installationsverzeichnis
        echo -e "${YELLOW}Geben Sie das Installationsverzeichnis ein (standardmäßig: /opt/kormit):${RESET}"
        read -r INSTALL_DIR
        INSTALL_DIR=${INSTALL_DIR:-/opt/kormit}
        
        # Prüfe, ob das Docker-Compose-Verzeichnis existiert
        DC_DIR="$INSTALL_DIR/docker/production"
        if [[ ! -d "$DC_DIR" ]]; then
            echo -e "${RED}Verzeichnis $DC_DIR existiert nicht.${RESET}"
            exit 1
        fi
        
        # Ändere Port in docker-compose.yml und .env
        echo -e "${YELLOW}Aktualisiere Port-Konfiguration...${RESET}"
        
        # .env-Datei aktualisieren oder erstellen
        ENV_FILE="$DC_DIR/.env"
        if [[ -f "$ENV_FILE" ]]; then
            # Aktualisiere vorhandene .env-Datei
            if grep -q "^HTTP_PORT=" "$ENV_FILE"; then
                sed -i 's/^HTTP_PORT=.*$/HTTP_PORT=8090/' "$ENV_FILE"
            else
                echo "HTTP_PORT=8090" >> "$ENV_FILE"
            fi
        else
            # Erstelle neue .env-Datei
            cat > "$ENV_FILE" << EOL
# Kormit Production Environment Variables
HTTP_PORT=8090
HTTPS_PORT=443
DB_USER=kormit_user
DB_PASSWORD=secure_password_change_me
DB_NAME=kormit_db
TIMEZONE=Europe/Berlin
SECRET_KEY=change_this_to_a_secure_random_string
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
EOL
        fi
        
        # Erstelle Neustart-Skript
        RESTART_SCRIPT="$DC_DIR/restart.sh"
        cat > "$RESTART_SCRIPT" << 'EOL'
#!/bin/bash
# Skript zum Neu-Starten der Kormit-Container mit neuer Konfiguration

set -e

# Farben für Ausgaben
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stoppe laufende Kormit-Container...${NC}"
docker-compose -f docker-compose.yml down || true

echo -e "${YELLOW}Starte Container mit neuer Konfiguration...${NC}"
docker-compose -f docker-compose.yml up -d

echo -e "${GREEN}Container wurden neu gestartet.${NC}"
echo -e "${YELLOW}Kormit ist nun erreichbar unter: http://localhost:$(grep HTTP_PORT .env | cut -d= -f2)${NC}"

# Ausgabe der Container-Status
echo -e "${YELLOW}Container-Status:${NC}"
docker-compose -f docker-compose.yml ps

echo -e "${YELLOW}Prüfe Logs für Fehler...${NC}"
docker-compose -f docker-compose.yml logs --tail=10

echo -e "${GREEN}Fertig! Überprüfe die Frontend-Verbindung im Browser unter http://localhost:$(grep HTTP_PORT .env | cut -d= -f2)${NC}"
EOL
        chmod +x "$RESTART_SCRIPT"
        
        echo -e "${GREEN}✓ Port-Konfiguration wurde aktualisiert. Kormit wird nun Port 8090 verwenden.${RESET}"
        
        # Frage, ob die Container neu gestartet werden sollen
        echo ""
        echo -e "${YELLOW}Möchten Sie die Container jetzt neu starten? (j/n)${RESET}"
        read -r restart
        if [[ "$restart" =~ ^[jJ]$ ]]; then
            cd "$DC_DIR" || exit
            bash ./restart.sh
        else
            echo -e "${CYAN}Um die Änderungen manuell anzuwenden, führen Sie folgende Befehle aus:${RESET}"
            echo "cd $DC_DIR"
            echo "bash ./restart.sh"
        fi
    else
        echo -e "${YELLOW}Keine Änderungen vorgenommen. Sie müssen den Port-Konflikt manuell lösen.${RESET}"
    fi
else
    echo -e "${GREEN}✓ Port 80 ist verfügbar.${RESET}"
fi

echo ""
echo -e "${GREEN}Skript abgeschlossen.${RESET}"