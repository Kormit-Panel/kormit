#!/bin/bash
# Kormit Installationsskript für Linux
# Unterstützt: Ubuntu, Debian, CentOS, RHEL

# Version
VERSION="1.0.0"

# Parameter verarbeiten
INSTALL_DIR="/opt/kormit"
DOMAIN_NAME="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
AUTO_START=false
SKIP_CONFIRM=false
DEBUG=false

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

# Systemtyp erkennen
detect_os() {
    log_info "Betriebssystem wird erkannt..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_info "Erkanntes Betriebssystem: $OS $VERSION"
    else
        log_error "Betriebssystem konnte nicht erkannt werden."
        exit 1
    fi
}

# Docker-Installation
install_docker() {
    log_info "Docker wird installiert/überprüft..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker ist bereits installiert."
    else
        log_info "Docker wird installiert..."
        
        case $OS in
            ubuntu|debian)
                apt update
                apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
                curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt update
                apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                ;;
            centos|rhel|fedora)
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
        
        log_success "Docker wurde erfolgreich installiert."
    fi
}

# Docker Compose-Installation
install_docker_compose() {
    log_info "Docker Compose wird installiert/überprüft..."
    
    if docker compose version &> /dev/null; then
        log_success "Docker Compose Plugin ist bereits installiert."
    elif command -v docker-compose &> /dev/null; then
        log_success "Docker Compose Legacy ist bereits installiert."
    else
        log_info "Docker Compose wird installiert..."
        
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        
        mkdir -p /usr/local/lib/docker/cli-plugins
        curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
        chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
        
        log_success "Docker Compose wurde erfolgreich installiert."
    fi
}

# Firewall-Konfiguration
configure_firewall() {
    log_info "Firewall wird konfiguriert..."
    
    case $OS in
        ubuntu|debian)
            if command -v ufw &> /dev/null; then
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
    
    # Interaktive Konfiguration, falls nicht über Parameter übergeben und nicht --yes gesetzt
    if [ "$INSTALL_DIR" = "/opt/kormit" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "Installationsverzeichnis [/opt/kormit]: " user_install_dir
        if [ -n "$user_install_dir" ]; then
            INSTALL_DIR="$user_install_dir"
        fi
    fi
    
    if [ "$DOMAIN_NAME" = "localhost" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "Domain-Name (oder IP-Adresse) [localhost]: " user_domain
        if [ -n "$user_domain" ]; then
            DOMAIN_NAME="$user_domain"
        fi
    fi
    
    if [ "$HTTP_PORT" = "80" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "HTTP-Port [80]: " user_http_port
        if [ -n "$user_http_port" ]; then
            HTTP_PORT="$user_http_port"
        fi
    fi
    
    if [ "$HTTPS_PORT" = "443" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "HTTPS-Port [443]: " user_https_port
        if [ -n "$user_https_port" ]; then
            HTTPS_PORT="$user_https_port"
        fi
    fi
    
    log_debug "Installationsverzeichnis: $INSTALL_DIR"
    log_debug "Domain-Name: $DOMAIN_NAME"
    log_debug "HTTP-Port: $HTTP_PORT"
    log_debug "HTTPS-Port: $HTTPS_PORT"
    
    # Installationsverzeichnis erstellen
    log_debug "Erstelle Installationsverzeichnis $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    
    # Produktionskonfiguration erstellen
    log_info "Konfigurationsdateien werden erstellt..."
    
    log_debug "Erstelle Verzeichnisstruktur"
    mkdir -p docker/production
    mkdir -p docker/production/ssl
    mkdir -p docker/production/logs
    
    log_debug "Schritt: Erstelle docker-compose.yml"
    # Docker Compose-Datei erstellen
    cat > docker/production/docker-compose.yml <<EOL
$(cat $SCRIPT_DIR/docker/production/docker-compose.yml)
EOL
    
    log_debug "Schritt: Erstelle nginx.conf"
    # Nginx-Konfiguration erstellen
    cat > docker/production/nginx.conf <<EOL
$(cat $SCRIPT_DIR/docker/production/nginx.conf)
EOL
    
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
    log_info "Selbstsigniertes SSL-Zertifikat wird erstellt..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout docker/production/ssl/kormit.key \
        -out docker/production/ssl/kormit.crt \
        -subj "/C=DE/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME" \
        -addext "subjectAltName=DNS:$DOMAIN_NAME,IP:127.0.0.1"
    
    chmod 600 docker/production/ssl/kormit.key
    
    log_debug "Schritt: Erstelle Start-Skript"
    # Start-Skript erstellen
    cat > start.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist unter https://$DOMAIN_NAME erreichbar."
EOL
    
    chmod +x start.sh
    
    log_debug "Schritt: Erstelle Stop-Skript"
    # Stop-Skript erstellen
    cat > stop.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose down
echo "Kormit wurde gestoppt."
EOL
    
    chmod +x stop.sh
    
    log_debug "Schritt: Erstelle Update-Skript"
    # Update-Skript erstellen
    cat > update.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL
    
    chmod +x update.sh
    
    log_success "Kormit wurde erfolgreich installiert."
    log_info "Sie können Kormit mit dem Befehl '$INSTALL_DIR/start.sh' starten."
    
    # Automatischen Start ausführen, falls konfiguriert
    if [ "$AUTO_START" = true ]; then
        log_info "Kormit wird gestartet..."
        $INSTALL_DIR/start.sh
    else
        # Automatischen Start anbieten, wenn nicht bereits per Parameter festgelegt und nicht --yes gesetzt
        if [ "$SKIP_CONFIRM" = false ]; then
            read -p "Möchten Sie Kormit jetzt starten? (j/N): " start_now
            if [[ "$start_now" =~ ^[jJ]$ ]]; then
                log_info "Kormit wird gestartet..."
                $INSTALL_DIR/start.sh
            fi
        fi
    fi
}

# Hauptfunktion
main() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                 KORMIT INSTALLER v${VERSION}                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Skriptverzeichnis speichern
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    log_debug "Skriptverzeichnis: $SCRIPT_DIR"
    
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
    log_info "Führen Sie '$INSTALL_DIR/start.sh' aus, um Kormit zu starten."
    log_info "Anschließend können Sie Kormit unter https://$DOMAIN_NAME aufrufen."
    log_warning "Ersetzen Sie das selbstsignierte SSL-Zertifikat für Produktionsumgebungen durch ein gültiges Zertifikat."
}

# Skript ausführen
main 