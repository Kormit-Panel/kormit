#!/bin/bash
# Kormit manuelle Installation für Ubuntu
# Dieses Skript umgeht mögliche Probleme mit dem Hauptinstallationsskript

# Farbige Ausgaben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           KORMIT MANUELLE INSTALLATION                     ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Prüfen, ob das Skript als Root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Dieses Skript muss als Root ausgeführt werden.${NC}"
    exit 1
fi

# Installationsverzeichnis
INSTALL_DIR="/opt/kormit"
# Domain-Name
DOMAIN_NAME="localhost"
# HTTP-Port
HTTP_PORT="80"
# DB-Passwort generieren
DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1 || echo "kormit_password")
# Secret Key generieren
SECRET_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1 || echo "kormit_secret_key")
# Zeitzone ermitteln
TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")

echo -e "${BLUE}ℹ️ Installiere Kormit in ${INSTALL_DIR}${NC}"
echo -e "${BLUE}ℹ️ Domain: ${DOMAIN_NAME}${NC}"
echo -e "${BLUE}ℹ️ HTTP-Port: ${HTTP_PORT}${NC}"
echo -e "${BLUE}ℹ️ Timezone: ${TIMEZONE}${NC}"

# Installationsverzeichnis erstellen
mkdir -p ${INSTALL_DIR}
cd ${INSTALL_DIR}

# Verzeichnisstruktur erstellen
mkdir -p docker/production/logs

echo -e "${BLUE}ℹ️ Erstelle Docker Compose-Datei${NC}"
# Docker Compose-Datei direkt erstellen
cat > docker/production/docker-compose.yml <<EOL
services:
  db:
    image: postgres:15-alpine
    container_name: kormit-db
    restart: always
    environment:
      POSTGRES_USER: kormit_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: kormit
      TZ: ${TIMEZONE}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - kormit-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U kormit_user -d kormit"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: ghcr.io/kormit-panel/kormit/kormit-backend:latest
    container_name: kormit-backend
    restart: always
    environment:
      DATABASE_URL: postgresql://kormit_user:${DB_PASSWORD}@db:5432/kormit
      SECRET_KEY: ${SECRET_KEY}
      DOMAIN_NAME: ${DOMAIN_NAME}
      TZ: ${TIMEZONE}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - kormit-net

  frontend:
    image: ghcr.io/kormit-panel/kormit/kormit-frontend:latest
    container_name: kormit-frontend
    restart: always
    environment:
      BACKEND_URL: http://backend:8000
      TZ: ${TIMEZONE}
    depends_on:
      - backend
    networks:
      - kormit-net

  nginx:
    image: nginx:alpine
    container_name: kormit-nginx
    restart: always
    ports:
      - "${HTTP_PORT}:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./logs:/var/log/nginx
    depends_on:
      - frontend
      - backend
    networks:
      - kormit-net

networks:
  kormit-net:
    name: kormit-network

volumes:
  db_data:
    name: kormit-db-data
EOL

echo -e "${BLUE}ℹ️ Erstelle Nginx-Konfiguration${NC}"
# Nginx-Konfiguration direkt erstellen
cat > docker/production/nginx.conf <<EOL
server {
    listen 80;
    server_name ${DOMAIN_NAME};

    # Frontend
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Backend API
    location /api {
        proxy_pass http://backend:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Für WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOL

echo -e "${BLUE}ℹ️ Erstelle Start-Skript${NC}"
# Start-Skript erstellen
cat > start.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist unter http://${DOMAIN_NAME} erreichbar."
EOL

chmod +x start.sh

echo -e "${BLUE}ℹ️ Erstelle Stop-Skript${NC}"
# Stop-Skript erstellen
cat > stop.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose down
echo "Kormit wurde gestoppt."
EOL

chmod +x stop.sh

echo -e "${BLUE}ℹ️ Erstelle Update-Skript${NC}"
# Update-Skript erstellen
cat > update.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL

chmod +x update.sh

# Umgebungsvariablen speichern
cat > docker/production/.env <<EOL
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=kormit
SECRET_KEY=${SECRET_KEY}
DOMAIN_NAME=${DOMAIN_NAME}
TIMEZONE=${TIMEZONE}
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=${HTTP_PORT}

# Image-Konfiguration
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:latest
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:latest
EOL

echo -e "${GREEN}✅ Kormit wurde erfolgreich installiert!${NC}"
echo -e "${BLUE}ℹ️ Führen Sie '${INSTALL_DIR}/start.sh' aus, um Kormit zu starten.${NC}"
echo -e "${BLUE}ℹ️ Anschließend können Sie Kormit unter http://${DOMAIN_NAME} aufrufen.${NC}"

# Fragen, ob Kormit jetzt gestartet werden soll
read -p "Möchten Sie Kormit jetzt starten? (j/N): " start_now
if [[ "$start_now" =~ ^[jJ]$ ]]; then
    echo -e "${BLUE}ℹ️ Kormit wird gestartet...${NC}"
    ${INSTALL_DIR}/start.sh
fi 