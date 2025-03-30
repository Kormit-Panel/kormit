#!/bin/bash
# Kormit Installationsskript für Linux
# Unterstützt: Ubuntu, Debian, CentOS, RHEL

# Version
VERSION="1.1.6"

# Parameter verarbeiten
INSTALL_DIR="/opt/kormit"
DOMAIN_NAME="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
AUTO_START=false
SKIP_CONFIRM=false
DEBUG=false
USE_HTTPS=true

# Parameter-Verarbeitung
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --install-dir=*)
      INSTALL_DIR="${key#*=}"
      shift
      ;;
    --domain=*)
      DOMAIN_NAME="${key#*=}"
      shift
      ;;
    --http-port=*)
      HTTP_PORT="${key#*=}"
      shift
      ;;
    --https-port=*)
      HTTPS_PORT="${key#*=}"
      shift
      ;;
    --auto-start)
      AUTO_START=true
      shift
      ;;
    --yes|-y)
      SKIP_CONFIRM=true
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    --http-only)
      USE_HTTPS=false
      shift
      ;;
    --help|-h)
      echo "Kormit Installer v${VERSION}"
      echo ""
      echo "Verwendung: $0 [Optionen]"
      echo "Optionen:"
      echo "  --install-dir=DIR        Installationsverzeichnis (Standard: /opt/kormit)"
      echo "  --domain=DOMAIN          Domain-Name (Standard: localhost)"
      echo "  --http-port=PORT         HTTP-Port (Standard: 80)"
      echo "  --https-port=PORT        HTTPS-Port (Standard: 443)"
      echo "  --auto-start             Kormit nach der Installation automatisch starten"
      echo "  --yes, -y                Alle Fragen automatisch mit Ja beantworten"
      echo "  --debug                  Aktiviere Debug-Ausgaben"
      echo "  --http-only              Nur HTTP verwenden, kein HTTPS"
      echo "  --help, -h               Diese Hilfe anzeigen"
      echo ""
      echo "Beispiel:"
      echo "  $0 --domain=example.com --install-dir=/var/kormit --auto-start"
      exit 0
      ;;
    *)
      echo "Unbekannte Option: $1"
      echo "Verwenden Sie --help für Hilfe."
      exit 1
      ;;
  esac
done

# Trap für Fehlerbehandlung hinzufügen
trap 'echo "Installation wurde unterbrochen. Überprüfen Sie die Fehlermeldungen."; exit 1' ERR

# Vorsichtige Fehlerbehandlung
set -e

# Farbige Ausgaben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}ℹ️  ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ ${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ${NC} $1"
}

log_section() {
    echo -e "${MAGENTA}▶️  $1 ${NC}"
    echo -e "${MAGENTA}   $(printf '─%.0s' {1..50}) ${NC}"
}

log_debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${CYAN}🔍 [DEBUG] ${NC} $1"
    fi
}

# Hilfsfunktion zur Überprüfung der Ausführung als Root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Dieses Skript muss als Root ausgeführt werden."
        exit 1
    fi
}

# Funktion für Eingaben mit Timeout
read_with_timeout() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local timeout=30
    
    # Wenn SKIP_CONFIRM gesetzt ist, direkt den Standardwert zurückgeben
    if [ "$SKIP_CONFIRM" = true ]; then
        eval "$var_name=\"$default\""
        return
    fi
    
    log_debug "Lese Benutzereingabe mit Timeout $timeout Sekunden"
    read -t $timeout -p "$prompt" input
    
    # Wenn Timeout erreicht oder leere Eingabe, Standardwert verwenden
    if [ $? -ne 0 ] || [ -z "$input" ]; then
        log_debug "Timeout oder leere Eingabe, verwende Standardwert: $default"
        eval "$var_name=\"$default\""
    else
        log_debug "Benutzereingabe: $input"
        eval "$var_name=\"$input\""
    fi
}

# Systemtyp erkennen
detect_os() {
    log_info "Betriebssystem wird erkannt..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_info "Erkanntes Betriebssystem: $OS $VERSION"
        log_debug "OS-Details: $(cat /etc/os-release | grep -E '^(NAME|VERSION)=')"
    else
        log_error "Betriebssystem konnte nicht erkannt werden."
        exit 1
    fi
}

# Docker-Installation
install_docker() {
    log_info "Docker wird installiert/überprüft..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Unbekannt")
        log_success "Docker ist bereits installiert: $DOCKER_VERSION"
    else
        log_info "Docker wird installiert..."
        
        case $OS in
            ubuntu|debian)
                log_debug "Installiere Docker für $OS $VERSION"
                apt update
                apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
                curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt update
                apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                ;;
            centos|rhel|fedora)
                log_debug "Installiere Docker für $OS $VERSION"
                yum install -y yum-utils
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                systemctl start docker
                systemctl enable docker
                ;;
            *)
                log_error "Nicht unterstütztes Betriebssystem: $OS"
                exit 1
                ;;
        esac
        
        # Überprüfen, ob Docker nach der Installation verfügbar ist
        if command -v docker &> /dev/null; then
            DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Unbekannt")
            log_success "Docker wurde erfolgreich installiert: $DOCKER_VERSION"
        else
            log_error "Docker konnte nicht installiert werden."
            exit 1
        fi
    fi
}

# Docker Compose-Installation
install_docker_compose() {
    log_info "Docker Compose wird installiert/überprüft..."
    
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "Unbekannt")
        log_success "Docker Compose Plugin ist bereits installiert: $COMPOSE_VERSION"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version 2>/dev/null || echo "Unbekannt")
        log_success "Docker Compose Legacy ist bereits installiert: $COMPOSE_VERSION"
    else
        log_info "Docker Compose wird installiert..."
        
        log_debug "Lade neueste Docker Compose Version"
        COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        
        if [ -z "$COMPOSE_LATEST" ]; then
            log_warning "Konnte neueste Docker Compose Version nicht ermitteln, verwende 2.26.0"
            COMPOSE_VERSION="v2.26.0"
        else
            COMPOSE_VERSION="$COMPOSE_LATEST"
            log_debug "Neueste Docker Compose Version: $COMPOSE_VERSION"
        fi
        
        mkdir -p /usr/local/lib/docker/cli-plugins
        log_debug "Lade Docker Compose Binary herunter"
        if curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose; then
            chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
            
            # Überprüfen ob Installation erfolgreich war
            if docker compose version &> /dev/null; then
                INSTALLED_VERSION=$(docker compose version --short 2>/dev/null || echo "Unbekannt")
                log_success "Docker Compose wurde erfolgreich installiert: $INSTALLED_VERSION"
            else
                log_error "Docker Compose konnte nicht installiert werden."
                exit 1
            fi
        else
            log_error "Konnte Docker Compose nicht herunterladen."
            exit 1
        fi
    fi
}

# Firewall-Konfiguration
configure_firewall() {
    log_info "Firewall wird konfiguriert..."
    
    case $OS in
        ubuntu|debian)
            if command -v ufw &> /dev/null; then
                log_debug "Konfiguriere UFW: Port $HTTP_PORT und $HTTPS_PORT"
                ufw allow $HTTP_PORT/tcp
                ufw allow $HTTPS_PORT/tcp
                if ! ufw status | grep -q "Status: active"; then
                    log_warning "UFW ist nicht aktiv. Sie können es mit 'ufw enable' aktivieren."
                fi
                log_success "Firewall-Regeln wurden konfiguriert."
            else
                log_warning "UFW ist nicht installiert. Ports $HTTP_PORT und $HTTPS_PORT müssen manuell geöffnet werden."
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd &> /dev/null; then
                log_debug "Konfiguriere firewalld: Port $HTTP_PORT und $HTTPS_PORT"
                firewall-cmd --permanent --add-port=$HTTP_PORT/tcp
                firewall-cmd --permanent --add-port=$HTTPS_PORT/tcp
                firewall-cmd --reload
                log_success "Firewall-Regeln wurden konfiguriert."
            else
                log_warning "firewalld ist nicht installiert. Ports $HTTP_PORT und $HTTPS_PORT müssen manuell geöffnet werden."
            fi
            ;;
    esac
}

# Kormit-Installation
install_kormit() {
    log_section "Kormit wird installiert"
    
    # Interaktive Konfiguration mit Timeout
    local user_install_dir
    local user_domain
    local user_http_port
    local user_https_port
    local use_https
    local start_now
    
    if [ "$INSTALL_DIR" = "/opt/kormit" ] && [ "$SKIP_CONFIRM" = false ]; then
        read_with_timeout "Installationsverzeichnis [/opt/kormit]: " "/opt/kormit" "user_install_dir"
        if [ -n "$user_install_dir" ] && [ "$user_install_dir" != "/opt/kormit" ]; then
            INSTALL_DIR="$user_install_dir"
        fi
    fi
    
    if [ "$DOMAIN_NAME" = "localhost" ] && [ "$SKIP_CONFIRM" = false ]; then
        read_with_timeout "Domain-Name (oder IP-Adresse) [localhost]: " "localhost" "user_domain"
        if [ -n "$user_domain" ] && [ "$user_domain" != "localhost" ]; then
            DOMAIN_NAME="$user_domain"
        fi
    fi
    
    if [ "$HTTP_PORT" = "80" ] && [ "$SKIP_CONFIRM" = false ]; then
        read_with_timeout "HTTP-Port [80]: " "80" "user_http_port"
        if [ -n "$user_http_port" ] && [ "$user_http_port" != "80" ]; then
            HTTP_PORT="$user_http_port"
        fi
    fi
    
    if [ "$USE_HTTPS" = true ] && [ "$SKIP_CONFIRM" = false ]; then
        read_with_timeout "HTTPS verwenden? (j/N): " "N" "use_https"
        if [[ "$use_https" =~ ^[jJ]$ ]]; then
            if [ "$HTTPS_PORT" = "443" ]; then
                read_with_timeout "HTTPS-Port [443]: " "443" "user_https_port"
                if [ -n "$user_https_port" ] && [ "$user_https_port" != "443" ]; then
                    HTTPS_PORT="$user_https_port"
                fi
            fi
        else
            USE_HTTPS=false
            log_info "HTTP-only-Modus wurde aktiviert."
        fi
    fi
    
    log_debug "Installationsverzeichnis: $INSTALL_DIR"
    log_debug "Domain-Name: $DOMAIN_NAME"
    log_debug "HTTP-Port: $HTTP_PORT"
    if [ "$USE_HTTPS" = true ]; then
        log_debug "HTTPS-Port: $HTTPS_PORT"
    else
        log_debug "HTTP-only-Modus aktiviert"
    fi
    
    # Installationsverzeichnis erstellen
    log_debug "Erstelle Installationsverzeichnis $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR || {
        log_error "Konnte nicht in Installationsverzeichnis wechseln: $INSTALL_DIR"
        exit 1
    }
    
    # Produktionskonfiguration erstellen
    log_info "Konfigurationsdateien werden erstellt..."
    
    log_debug "Erstelle Verzeichnisstruktur"
    mkdir -p docker/production
    if [ "$USE_HTTPS" = true ]; then
        mkdir -p docker/production/ssl
    fi
    mkdir -p docker/production/logs
    
    log_debug "Schritt: Erstelle docker-compose.yml"
    # Docker Compose-Datei direkt erstellen
    if [ "$USE_HTTPS" = true ]; then
        # Standard-Konfiguration mit HTTPS
        cat > docker/production/docker-compose.yml <<EOL
services:
  db:
    image: postgres:15-alpine
    container_name: \${VOLUME_PREFIX}-db
    restart: always
    environment:
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: \${DB_NAME}
      TZ: \${TIMEZONE}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - kormit-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER} -d \${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: \${BACKEND_IMAGE}
    container_name: \${VOLUME_PREFIX}-backend
    restart: always
    environment:
      DATABASE_URL: postgresql://\${DB_USER}:\${DB_PASSWORD}@db:5432/\${DB_NAME}
      SECRET_KEY: \${SECRET_KEY}
      DOMAIN_NAME: \${DOMAIN_NAME}
      TZ: \${TIMEZONE}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - kormit-net

  frontend:
    image: \${FRONTEND_IMAGE}
    container_name: \${VOLUME_PREFIX}-frontend
    restart: always
    environment:
      BACKEND_URL: http://backend:8000
      TZ: \${TIMEZONE}
    depends_on:
      - backend
    networks:
      - kormit-net

  nginx:
    image: nginx:alpine
    container_name: \${VOLUME_PREFIX}-nginx
    restart: always
    ports:
      - "\${HTTP_PORT}:80"
      - "\${HTTPS_PORT}:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
      - ./logs:/var/log/nginx
    depends_on:
      - frontend
      - backend
    networks:
      - kormit-net

networks:
  kormit-net:
    name: \${NETWORK_NAME}

volumes:
  db_data:
    name: \${VOLUME_PREFIX}-db-data
EOL
    else
        # HTTP-only Konfiguration
        cat > docker/production/docker-compose.yml <<EOL
services:
  db:
    image: postgres:15-alpine
    container_name: \${VOLUME_PREFIX}-db
    restart: always
    environment:
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: \${DB_NAME}
      TZ: \${TIMEZONE}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - kormit-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER} -d \${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: \${BACKEND_IMAGE}
    container_name: \${VOLUME_PREFIX}-backend
    restart: always
    environment:
      DATABASE_URL: postgresql://\${DB_USER}:\${DB_PASSWORD}@db:5432/\${DB_NAME}
      SECRET_KEY: \${SECRET_KEY}
      DOMAIN_NAME: \${DOMAIN_NAME}
      TZ: \${TIMEZONE}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - kormit-net

  frontend:
    image: \${FRONTEND_IMAGE}
    container_name: \${VOLUME_PREFIX}-frontend
    restart: always
    environment:
      BACKEND_URL: http://backend:8000
      TZ: \${TIMEZONE}
    depends_on:
      - backend
    networks:
      - kormit-net

  nginx:
    image: nginx:alpine
    container_name: \${VOLUME_PREFIX}-nginx
    restart: always
    ports:
      - "\${HTTP_PORT}:80"
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
    name: \${NETWORK_NAME}

volumes:
  db_data:
    name: \${VOLUME_PREFIX}-db-data
EOL
    fi
    
    log_debug "Schritt: Erstelle nginx.conf"
    # Nginx-Konfiguration direkt erstellen
    if [ "$USE_HTTPS" = true ]; then
        # Standard-Konfiguration mit HTTPS
        cat > docker/production/nginx.conf <<EOL
server {
    listen 80;
    server_name \${DOMAIN_NAME};
    
    # HTTP zu HTTPS umleiten
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name \${DOMAIN_NAME};

    # SSL-Konfiguration
    ssl_certificate /etc/nginx/ssl/kormit.crt;
    ssl_certificate_key /etc/nginx/ssl/kormit.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;

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
    else
        # HTTP-only Konfiguration
        cat > docker/production/nginx.conf <<EOL
server {
    listen 80;
    server_name \${DOMAIN_NAME};

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
    fi
    
    log_debug "Schritt: Generiere Passwörter"
    # Zufällige Passwörter generieren
    DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
    SECRET_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
    
    log_debug "Schritt: Ermittle Timezone"
    # Timezone ermitteln
    TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
    
    log_debug "Schritt: Erstelle .env"
    # Umgebungsvariablen-Datei erstellen
    cat > docker/production/.env <<EOL
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=$DB_PASSWORD
DB_NAME=kormit
SECRET_KEY=$SECRET_KEY
DOMAIN_NAME=$DOMAIN_NAME
TIMEZONE=$TIMEZONE
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT

# Image-Konfiguration
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:latest
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:latest
EOL
    
    log_debug "Schritt: Erstelle SSL-Zertifikat"
    # Self-signed Zertifikat für die erste Einrichtung erstellen
    if [ "$USE_HTTPS" = true ]; then
        log_info "Selbstsigniertes SSL-Zertifikat wird erstellt..."
        
        # Verzeichnis erstellen, falls es nicht existiert
        mkdir -p docker/production/ssl
        
        # Prüfen ob OpenSSL verfügbar ist
        if ! command -v openssl &> /dev/null; then
            log_error "OpenSSL ist nicht installiert. Das SSL-Zertifikat kann nicht erstellt werden."
            log_info "Bitte installieren Sie OpenSSL mit 'apt install openssl' oder dem entsprechenden Befehl für Ihre Distribution."
            exit 1
        fi
        
        # Prüfen ob OpenSSL-Version > 1.1.1
        OPENSSL_VERSION=$(openssl version | awk '{print $2}')
        log_debug "OpenSSL Version: $OPENSSL_VERSION"
        
        # Immer die Konfigurationsdatei-Methode verwenden, da sie am zuverlässigsten ist
        log_debug "Verwende Konfigurationsdatei-Methode für OpenSSL"
        
        # Konfiguration erstellen
        cat > docker/production/ssl/openssl.cnf <<EOL
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = DE
ST = State
L = City
O = Organization
CN = $DOMAIN_NAME

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN_NAME
DNS.2 = localhost
IP.1 = 127.0.0.1
EOL
        
        # Zertifikat mit Konfigurationsdatei erstellen
        if openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout docker/production/ssl/kormit.key \
            -out docker/production/ssl/kormit.crt \
            -config docker/production/ssl/openssl.cnf \
            -sha256; then
            
            log_success "SSL-Zertifikat erfolgreich erstellt."
        else
            log_error "Fehler beim Erstellen des SSL-Zertifikats."
            log_info "Versuche alternative Methode..."
            
            # Alternative Methode ohne Extensions
            if openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout docker/production/ssl/kormit.key \
                -out docker/production/ssl/kormit.crt \
                -subj "/C=DE/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME"; then
                
                log_warning "SSL-Zertifikat ohne Subject Alternative Names erstellt."
                log_info "Das Zertifikat funktioniert möglicherweise nicht in allen Browsern korrekt."
            else
                log_error "Konnte kein SSL-Zertifikat erstellen. Die Installation wird fortgesetzt, aber HTTPS funktioniert möglicherweise nicht."
                touch docker/production/ssl/kormit.key
                touch docker/production/ssl/kormit.crt
            fi
        fi
        
        # Konfigurationsdatei entfernen
        rm -f docker/production/ssl/openssl.cnf
        
        chmod 600 docker/production/ssl/kormit.key
    else
        log_info "HTTP-only-Modus aktiviert, überspringt SSL-Zertifikatserstellung."
    fi
    
    log_debug "Schritt: Erstelle Start-Skript"
    # Start-Skript erstellen
    if [ "$USE_HTTPS" = true ]; then
        cat > start.sh <<'EOL'
#!/bin/bash
cd "$(dirname "$0")"/docker/production || { echo "Fehler: Konnte nicht in das Verzeichnis wechseln"; exit 1; }
docker compose up -d
echo "Kormit wurde gestartet und ist unter https://DOMAIN_NAME erreichbar."
EOL
        sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" start.sh
    else
        cat > start.sh <<'EOL'
#!/bin/bash
cd "$(dirname "$0")"/docker/production || { echo "Fehler: Konnte nicht in das Verzeichnis wechseln"; exit 1; }
docker compose up -d
echo "Kormit wurde gestartet und ist unter http://DOMAIN_NAME erreichbar."
EOL
        sed -i "s/DOMAIN_NAME/$DOMAIN_NAME/g" start.sh
    fi
    
    chmod +x start.sh
    
    log_debug "Schritt: Erstelle Stop-Skript"
    # Stop-Skript erstellen
    cat > stop.sh <<'EOL'
#!/bin/bash
cd "$(dirname "$0")"/docker/production || { echo "Fehler: Konnte nicht in das Verzeichnis wechseln"; exit 1; }
docker compose down
echo "Kormit wurde gestoppt."
EOL
    
    chmod +x stop.sh
    
    log_debug "Schritt: Erstelle Update-Skript"
    # Update-Skript erstellen
    cat > update.sh <<'EOL'
#!/bin/bash
cd "$(dirname "$0")"/docker/production || { echo "Fehler: Konnte nicht in das Verzeichnis wechseln"; exit 1; }
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL
    
    chmod +x update.sh
    
    log_success "Kormit wurde erfolgreich installiert."
    
    # Zeige den absoluten Pfad an, nicht die relativen Pfade
    # FULL_PATH="$INSTALL_DIR"
    
    log_info "Führen Sie '$INSTALL_DIR/start.sh' aus, um Kormit zu starten."
    
    # Automatischen Start ausführen, falls konfiguriert
    if [ "$AUTO_START" = true ]; then
        log_info "Kormit wird gestartet..."
        "$INSTALL_DIR/start.sh"
    else
        # Automatischen Start anbieten, wenn nicht bereits per Parameter festgelegt und nicht --yes gesetzt
        if [ "$SKIP_CONFIRM" = false ]; then
            read_with_timeout "Möchten Sie Kormit jetzt starten? (j/N): " "N" "start_now"
            if [[ "$start_now" =~ ^[jJ]$ ]]; then
                log_info "Kormit wird gestartet..."
                "$INSTALL_DIR/start.sh"
            fi
        fi
    fi
}

# Hauptfunktion
main() {
    # Banner anzeigen
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                 KORMIT INSTALLER v${VERSION}                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Systemumgebung anzeigen
    if [ "$DEBUG" = true ]; then
        log_debug "Betriebssystem: $(uname -a)"
        log_debug "CPU-Architektur: $(uname -m)"
        log_debug "Skript-Ausführungspfad: $(pwd)"
    fi
    
    # Als Root ausführen
    check_root
    
    # Betriebssystem erkennen
    log_section "System-Vorbereitung"
    detect_os
    
    # Notwendige Software installieren
    install_docker
    install_docker_compose
    
    # Firewall konfigurieren
    configure_firewall
    
    # Kormit installieren
    install_kormit
    
    log_section "Installation abgeschlossen"
    log_success "Kormit wurde erfolgreich installiert!"
    
    # Zeige den absoluten Pfad an, nicht die relativen Pfade
    # FULL_PATH="$INSTALL_DIR"
    
    log_info "Führen Sie '$INSTALL_DIR/start.sh' aus, um Kormit zu starten."
    if [ "$USE_HTTPS" = true ]; then
        log_info "Anschließend können Sie Kormit unter https://$DOMAIN_NAME aufrufen."
        log_warning "Ersetzen Sie das selbstsignierte SSL-Zertifikat für Produktionsumgebungen durch ein gültiges Zertifikat."
    else
        log_info "Anschließend können Sie Kormit unter http://$DOMAIN_NAME aufrufen."
    fi
}

# Skript ausführen
main