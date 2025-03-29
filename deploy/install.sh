#!/bin/bash
# Kormit Installationsskript für ein leeres Linux-System
# Unterstützt: Ubuntu, Debian, CentOS, RHEL
# Mit Unterstützung für private Repositories

set -e

# Farbige Ausgaben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
                apt install -y docker-ce docker-ce-cli containerd.io
                ;;
            centos|rhel|fedora)
                yum install -y yum-utils
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                yum install -y docker-ce docker-ce-cli containerd.io
                systemctl start docker
                systemctl enable docker
                ;;
            *)
                log_error "Unsupported OS: $OS"
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

# GitHub Container Registry-Authentifizierung konfigurieren
configure_ghcr_auth() {
    log_info "GitHub Container Registry Authentifizierung wird konfiguriert..."
    
    read -p "Möchten Sie sich bei GitHub Container Registry anmelden? (j/N): " github_auth
    if [[ "$github_auth" =~ ^[jJ]$ ]]; then
        log_info "GitHub Anmeldedaten werden eingerichtet..."
        
        read -p "GitHub Benutzername: " github_username
        read -sp "GitHub Personal Access Token (mit read:packages-Berechtigung): " github_token
        echo ""
        
        if [ -z "$github_username" ] || [ -z "$github_token" ]; then
            log_warning "Benutzername oder Token fehlt. Die Anmeldung wird übersprungen."
        else
            echo "$github_token" | docker login ghcr.io -u "$github_username" --password-stdin
            if [ $? -eq 0 ]; then
                log_success "GitHub Container Registry Anmeldung erfolgreich."
                GITHUB_AUTH_CONFIGURED=true
            else
                log_error "GitHub Container Registry Anmeldung fehlgeschlagen."
                log_warning "Die Installation wird fortgesetzt, aber Sie müssen möglicherweise manuell Anmeldedaten konfigurieren."
                GITHUB_AUTH_CONFIGURED=false
            fi
        fi
    else
        log_info "GitHub Anmeldung übersprungen. Wenn die Images privat sind, müssen Sie sich manuell anmelden."
        GITHUB_AUTH_CONFIGURED=false
    fi
}

# Firewall-Konfiguration
configure_firewall() {
    log_info "Firewall wird konfiguriert..."
    
    case $OS in
        ubuntu|debian)
            if command -v ufw &> /dev/null; then
                ufw allow 80/tcp
                ufw allow 443/tcp
                if ! ufw status | grep -q "Status: active"; then
                    log_warning "UFW ist nicht aktiv. Sie können es mit 'ufw enable' aktivieren."
                fi
                log_success "Firewall-Regeln wurden konfiguriert."
            else
                log_warning "UFW ist nicht installiert. Ports 80 und 443 müssen manuell geöffnet werden."
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-service=http
                firewall-cmd --permanent --add-service=https
                firewall-cmd --reload
                log_success "Firewall-Regeln wurden konfiguriert."
            else
                log_warning "firewalld ist nicht installiert. Ports 80 und 443 müssen manuell geöffnet werden."
            fi
            ;;
    esac
}

# Kormit-Installation
install_kormit() {
    log_info "Kormit wird installiert..."
    
    # Installationsverzeichnis erfragen
    read -p "Installationsverzeichnis [/opt/kormit]: " INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-/opt/kormit}
    
    # Domain erfragen
    read -p "Domain-Name (oder IP-Adresse) [localhost]: " DOMAIN_NAME
    DOMAIN_NAME=${DOMAIN_NAME:-localhost}
    
    # Installationsverzeichnis erstellen
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    
    # Produktionskonfiguration erstellen
    log_info "Konfigurationsdateien werden erstellt..."
    
    mkdir -p docker/production
    mkdir -p docker/production/ssl
    mkdir -p docker/production/logs
    
    # Docker Compose-Datei erstellen
    cat > docker/production/docker-compose.yml <<EOL
$(cat $SCRIPT_DIR/docker/production/docker-compose.yml)
EOL
    
    # Nginx-Konfiguration erstellen
    cat > docker/production/nginx.conf <<EOL
$(cat $SCRIPT_DIR/docker/production/nginx.conf)
EOL
    
    # Zufällige Passwörter generieren
    DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
    SECRET_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
    
    # Timezone ermitteln
    TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
    
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

# Image-Konfiguration
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:main
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:main
EOL
    
    # Self-signed Zertifikat für die erste Einrichtung erstellen
    log_info "Selbstsigniertes SSL-Zertifikat wird erstellt..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout docker/production/ssl/kormit.key \
        -out docker/production/ssl/kormit.crt \
        -subj "/C=DE/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME" \
        -addext "subjectAltName=DNS:$DOMAIN_NAME,IP:127.0.0.1"
    
    chmod 600 docker/production/ssl/kormit.key
    
    # Start-Skript erstellen
    cat > start.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist unter https://$DOMAIN_NAME erreichbar."
EOL
    
    chmod +x start.sh
    
    # Stop-Skript erstellen
    cat > stop.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose down
echo "Kormit wurde gestoppt."
EOL
    
    chmod +x stop.sh
    
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
    
    # Automatischen Start anbieten
    read -p "Möchten Sie Kormit jetzt starten? (j/N): " start_now
    if [[ "$start_now" =~ ^[jJ]$ ]]; then
        log_info "Kormit wird gestartet..."
        $INSTALL_DIR/start.sh
    fi
}

# Image-Test
test_images() {
    log_info "Teste den Zugriff auf die Docker-Images..."
    
    if docker pull ghcr.io/kormit-panel/kormit/kormit-backend:main >/dev/null 2>&1; then
        log_success "Backend-Image ist verfügbar."
    else
        log_warning "Backend-Image konnte nicht abgerufen werden. Überprüfen Sie Ihre Anmeldedaten."
    fi
    
    if docker pull ghcr.io/kormit-panel/kormit/kormit-frontend:main >/dev/null 2>&1; then
        log_success "Frontend-Image ist verfügbar."
    else
        log_warning "Frontend-Image konnte nicht abgerufen werden. Überprüfen Sie Ihre Anmeldedaten."
    fi
}

# Hauptfunktion
main() {
    log_info "Kormit-Installation wird gestartet..."
    
    # Skriptverzeichnis speichern
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    
    # Als Root ausführen
    check_root
    
    # Betriebssystem erkennen
    detect_os
    
    # Notwendige Software installieren
    install_docker
    install_docker_compose
    
    # GitHub Container Registry-Authentifizierung konfigurieren
    configure_ghcr_auth
    
    # Test der Images, wenn Authentifizierung konfiguriert wurde
    if [ "$GITHUB_AUTH_CONFIGURED" = true ]; then
        test_images
    fi
    
    # Firewall konfigurieren
    configure_firewall
    
    # Kormit installieren
    install_kormit
    
    log_success "Die Installation ist abgeschlossen!"
    log_info "Führen Sie '$INSTALL_DIR/start.sh' aus, um Kormit zu starten."
    log_info "Anschließend können Sie Kormit unter https://$DOMAIN_NAME aufrufen."
    log_warning "Ersetzen Sie das selbstsignierte SSL-Zertifikat für Produktionsumgebungen durch ein gültiges Zertifikat."
}

# Skript ausführen
main 