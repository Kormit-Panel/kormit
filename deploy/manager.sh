#!/bin/bash
# Kormit Management Script
# Ein modernes Tool zur Installation und Verwaltung von Kormit
# Version 1.1.0 - Mit Image-Tag-Fix und erweiterten Reparaturfunktionen

# Farbdefinitionen für ein modernes Interface
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
UNDERLINE="\033[4m"
BLINK="\033[5m"
REVERSE="\033[7m"
HIDDEN="\033[8m"

# Textfarben
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

# Hintergrundfarben
BG_BLACK="\033[40m"
BG_RED="\033[41m"
BG_GREEN="\033[42m"
BG_YELLOW="\033[43m"
BG_BLUE="\033[44m"
BG_MAGENTA="\033[45m"
BG_CYAN="\033[46m"
BG_WHITE="\033[47m"

# Repository und Verzeichnisse
REPO_URL="https://github.com/kormit-panel/kormit.git"
DEFAULT_INSTALL_DIR="/opt/kormit"
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
TMP_DIR="/tmp/kormit-install"

# Globale Variablen
VERSION="1.1.0"
DOMAIN_NAME="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
USE_HTTPS=true
DEBUG=false

# Überprüfen, ob das Skript als Root ausgeführt wird
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}${BOLD}✘ Dieses Skript muss als Root ausgeführt werden.${RESET}"
    echo -e "${YELLOW}Bitte mit 'sudo' oder als Root-Benutzer ausführen.${RESET}"
    exit 1
  fi
}

# Ausgabe-Funktionen
print_logo() {
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║   ██╗  ██╗ ██████╗ ██████╗ ███╗   ███╗██╗████████╗            ║"
    echo "║   ██║ ██╔╝██╔═══██╗██╔══██╗████╗ ████║██║╚══██╔══╝            ║"
    echo "║   █████╔╝ ██║   ██║██████╔╝██╔████╔██║██║   ██║               ║"
    echo "║   ██╔═██╗ ██║   ██║██╔══██╗██║╚██╔╝██║██║   ██║               ║"
    echo "║   ██║  ██╗╚██████╔╝██║  ██║██║ ╚═╝ ██║██║   ██║               ║"
    echo "║   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝   ╚═╝               ║"
    echo "║                                                                ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                Management Tool v${VERSION}                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_header() {
    local title="$1"
    echo -e "${BLUE}${BOLD}▶ ${title} ${RESET}"
    echo -e "${BLUE}  $(printf '═%.0s' {1..50})${RESET}"
}

log_info() {
    echo -e "${CYAN}ℹ️  ${RESET}$1"
}

log_success() {
    echo -e "${GREEN}✅ ${RESET}$1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${RESET}$1"
}

log_error() {
    echo -e "${RED}❌ ${RESET}$1"
}

log_debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${DIM}🔍 [DEBUG] ${RESET}$1"
    fi
}

# Spinners für lange Operationen
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Systemprüfung und Voraussetzungen
detect_os() {
    log_info "Betriebssystem wird erkannt..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
        log_info "Erkanntes Betriebssystem: ${BOLD}$OS $VERSION_ID${RESET}"
    else
        log_error "Betriebssystem konnte nicht erkannt werden."
        exit 1
    fi
}

check_dependencies() {
    print_header "Abhängigkeiten werden überprüft"
    
    # Git überprüfen
    if command -v git &> /dev/null; then
        log_success "Git ist installiert: $(git --version)"
    else
        log_warning "Git ist nicht installiert und wird benötigt."
        install_git
    fi
    
    # Docker überprüfen
    if command -v docker &> /dev/null; then
        log_success "Docker ist installiert: $(docker --version)"
    else
        log_warning "Docker ist nicht installiert und wird benötigt."
        install_docker
    fi
    
    # Docker Compose überprüfen
    if docker compose version &> /dev/null; then
        log_success "Docker Compose Plugin ist installiert."
    elif command -v docker-compose &> /dev/null; then
        log_success "Docker Compose Legacy ist installiert."
    else
        log_warning "Docker Compose ist nicht installiert und wird benötigt."
        install_docker_compose
    fi
}

install_git() {
    log_info "Git wird installiert..."
    
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y git
            ;;
        centos|rhel|fedora)
            yum install -y git
            ;;
        *)
            log_error "Nicht unterstütztes Betriebssystem für die Git-Installation."
            exit 1
            ;;
    esac
    
    if command -v git &> /dev/null; then
        log_success "Git wurde erfolgreich installiert: $(git --version)"
    else
        log_error "Git konnte nicht installiert werden."
        exit 1
    fi
}

install_docker() {
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
            log_error "Nicht unterstütztes Betriebssystem für die Docker-Installation."
            exit 1
            ;;
    esac
    
    if command -v docker &> /dev/null; then
        log_success "Docker wurde erfolgreich installiert: $(docker --version)"
    else
        log_error "Docker konnte nicht installiert werden."
        exit 1
    fi
}

install_docker_compose() {
    log_info "Docker Compose wird installiert..."
    
    if docker compose version &> /dev/null; then
        log_success "Docker Compose Plugin ist bereits installiert."
        return
    fi
    
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose Legacy ist bereits installiert."
        return
    fi
    
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
        log_success "Docker Compose wurde erfolgreich installiert."
    else
        log_error "Docker Compose konnte nicht installiert werden."
        exit 1
    fi
}

# Funktionen für Repository-Management
clone_repository() {
    print_header "Repository wird geklont"
    
    # Prüfen, ob TMP_DIR existiert und löschen, falls ja
    if [ -d "$TMP_DIR" ]; then
        log_info "Vorhandenes temporäres Verzeichnis wird entfernt..."
        rm -rf "$TMP_DIR"
    fi
    
    # Repository klonen
    log_info "Kormit Repository wird geklont..."
    mkdir -p "$TMP_DIR"
    if git clone "$REPO_URL" "$TMP_DIR"; then
        log_success "Repository wurde erfolgreich geklont."
    else
        log_error "Repository konnte nicht geklont werden."
        exit 1
    fi
}

update_repository() {
    print_header "Repository wird aktualisiert"
    
    # Prüfen, ob TMP_DIR existiert
    if [ ! -d "$TMP_DIR" ]; then
        clone_repository
        return
    fi
    
    # Repository aktualisieren
    log_info "Kormit Repository wird aktualisiert..."
    cd "$TMP_DIR"
    if git pull; then
        log_success "Repository wurde erfolgreich aktualisiert."
    else
        log_error "Repository konnte nicht aktualisiert werden."
        exit 1
    fi
}

# Funktionen für Kormit-Installation
install_kormit() {
    print_header "Kormit wird installiert"
    
    # Repository klonen, falls noch nicht geschehen
    if [ ! -d "$TMP_DIR" ]; then
        clone_repository
    fi
    
    # Installationsverzeichnis erstellen
    log_info "Installationsverzeichnis wird vorbereitet: ${BOLD}$INSTALL_DIR${RESET}"
    mkdir -p "$INSTALL_DIR"
    
    # Installationsparameter interaktiv erfragen
    get_installation_params
    
    # Standard-Installations-Skript ausführen
    log_info "Kormit wird installiert..."
    
    # Stellen Sie sicher, dass das Installationsskript vorhanden ist
    if [ -f "$TMP_DIR/deploy/install.sh" ]; then
        chmod +x "$TMP_DIR/deploy/install.sh"
        
        # Argumente basierend auf gesetzten Optionen erstellen
        install_args="--install-dir=$INSTALL_DIR --domain=$DOMAIN_NAME"
        install_args="$install_args --http-port=$HTTP_PORT --https-port=$HTTPS_PORT"
        
        if [ "$USE_HTTPS" = false ]; then
            install_args="$install_args --http-only"
        fi
        
        # Installationsskript starten
        log_info "Führe aus: $TMP_DIR/deploy/install.sh $install_args"
        cd "$TMP_DIR"
        if ./deploy/install.sh $install_args; then
            log_success "Kormit wurde erfolgreich installiert."
            
            # Nach der Installation die Image-Tags korrigieren
            log_info "Korrigiere Image-Tags in der .env-Datei..."
            fix_image_tags
        else
            log_error "Es gab Probleme bei der Installation von Kormit."
            exit 1
        fi
    else
        log_error "Installationsskript konnte nicht gefunden werden: $TMP_DIR/deploy/install.sh"
        exit 1
    fi
}

get_installation_params() {
    echo -e "${CYAN}${BOLD}Installationsparameter konfigurieren:${RESET}"
    echo -e "${DIM}Drücken Sie einfach Enter, um die Standardwerte zu verwenden.${RESET}"
    
    # Domain-Name
    read -p "Domain-Name oder IP-Adresse [$DOMAIN_NAME]: " user_domain
    if [ -n "$user_domain" ]; then
        DOMAIN_NAME="$user_domain"
    fi
    
    # HTTPS verwenden?
    if [ "$USE_HTTPS" = true ]; then
        read -p "HTTPS verwenden? (J/n): " use_https
        if [[ "$use_https" =~ ^[nN]$ ]]; then
            USE_HTTPS=false
            log_info "HTTP-only-Modus aktiviert."
        fi
    else
        read -p "HTTPS verwenden? (j/N): " use_https
        if [[ "$use_https" =~ ^[jJ]$ ]]; then
            USE_HTTPS=true
            log_info "HTTPS-Modus aktiviert."
        fi
    fi
    
    # HTTP-Port
    read -p "HTTP-Port [$HTTP_PORT]: " user_http_port
    if [ -n "$user_http_port" ]; then
        HTTP_PORT="$user_http_port"
    fi
    
    # HTTPS-Port (nur wenn HTTPS aktiviert ist)
    if [ "$USE_HTTPS" = true ]; then
        read -p "HTTPS-Port [$HTTPS_PORT]: " user_https_port
        if [ -n "$user_https_port" ]; then
            HTTPS_PORT="$user_https_port"
        fi
    fi
    
    # Bestätigen
    echo -e "${CYAN}Ausgewählte Konfiguration:${RESET}"
    echo -e "- Installationsverzeichnis: ${BOLD}$INSTALL_DIR${RESET}"
    echo -e "- Domain-Name: ${BOLD}$DOMAIN_NAME${RESET}"
    echo -e "- HTTP-Port: ${BOLD}$HTTP_PORT${RESET}"
    if [ "$USE_HTTPS" = true ]; then
        echo -e "- HTTPS-Port: ${BOLD}$HTTPS_PORT${RESET}"
        echo -e "- Protokoll: ${BOLD}HTTPS${RESET}"
    else
        echo -e "- Protokoll: ${BOLD}HTTP only${RESET}"
    fi
    
    read -p "Ist die Konfiguration korrekt? (J/n): " confirm
    if [[ "$confirm" =~ ^[nN]$ ]]; then
        get_installation_params
    fi
}

# Funktionen für Kormit-Management
start_kormit() {
    print_header "Kormit wird gestartet"
    
    if [ -f "$INSTALL_DIR/start.sh" ]; then
        log_info "Starte Kormit..."
        chmod +x "$INSTALL_DIR/start.sh"
        if "$INSTALL_DIR/start.sh"; then
            log_success "Kormit wurde erfolgreich gestartet."
        else
            log_error "Es gab Probleme beim Starten von Kormit."
            offer_repair_scripts
        fi
    else
        log_error "Start-Skript konnte nicht gefunden werden: $INSTALL_DIR/start.sh"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
        offer_repair_scripts
    fi
}

stop_kormit() {
    print_header "Kormit wird gestoppt"
    
    if [ -f "$INSTALL_DIR/stop.sh" ]; then
        log_info "Stoppe Kormit..."
        chmod +x "$INSTALL_DIR/stop.sh"
        if "$INSTALL_DIR/stop.sh"; then
            log_success "Kormit wurde erfolgreich gestoppt."
        else
            log_error "Es gab Probleme beim Stoppen von Kormit."
            offer_repair_scripts
        fi
    else
        log_error "Stop-Skript konnte nicht gefunden werden: $INSTALL_DIR/stop.sh"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
        offer_repair_scripts
    fi
}

restart_kormit() {
    print_header "Kormit wird neu gestartet"
    
    stop_kormit
    start_kormit
}

update_kormit() {
    print_header "Kormit wird aktualisiert"
    
    if [ -f "$INSTALL_DIR/update.sh" ]; then
        log_info "Aktualisiere Kormit..."
        chmod +x "$INSTALL_DIR/update.sh"
        if "$INSTALL_DIR/update.sh"; then
            log_success "Kormit wurde erfolgreich aktualisiert."
        else
            log_error "Es gab Probleme beim Aktualisieren von Kormit."
            offer_repair_scripts
        fi
    else
        log_error "Update-Skript konnte nicht gefunden werden: $INSTALL_DIR/update.sh"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
        offer_repair_scripts
    fi
}

show_logs() {
    print_header "Kormit Logs"
    
    if [ -d "$INSTALL_DIR/docker/production" ]; then
        cd "$INSTALL_DIR/docker/production"
        docker compose logs | less
    else
        log_error "Kormit-Verzeichnis konnte nicht gefunden werden: $INSTALL_DIR/docker/production"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
    fi
}

check_status() {
    print_header "Kormit Status"
    
    if [ -d "$INSTALL_DIR/docker/production" ]; then
        cd "$INSTALL_DIR/docker/production"
        docker compose ps
    else
        log_error "Kormit-Verzeichnis konnte nicht gefunden werden: $INSTALL_DIR/docker/production"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
    fi
}

# Wartungsfunktionen
repair_scripts() {
    print_header "Skripte werden repariert"
    
    log_info "Start-Skript wird repariert..."
    cat > "$INSTALL_DIR/start.sh" <<'EOL'
#!/bin/bash
cd $(dirname $0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist erreichbar."
EOL
    chmod +x "$INSTALL_DIR/start.sh"
    
    log_info "Stop-Skript wird repariert..."
    cat > "$INSTALL_DIR/stop.sh" <<'EOL'
#!/bin/bash
cd $(dirname $0)/docker/production
docker compose down
echo "Kormit wurde gestoppt."
EOL
    chmod +x "$INSTALL_DIR/stop.sh"
    
    log_info "Update-Skript wird repariert..."
    cat > "$INSTALL_DIR/update.sh" <<'EOL'
#!/bin/bash
cd $(dirname $0)/docker/production
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL
    chmod +x "$INSTALL_DIR/update.sh"
    
    log_success "Skripte wurden erfolgreich repariert."
    
    # Auch die Image-Tags reparieren
    log_info "Image-Tags werden auch repariert..."
    fix_image_tags
}

fix_image_tags() {
    print_header "Image-Tags werden korrigiert"
    
    ENV_FILE="$INSTALL_DIR/docker/production/.env"
    
    if [ -f "$ENV_FILE" ]; then
        log_info ".env-Datei wird aktualisiert..."
        
        # Backup erstellen
        cp "$ENV_FILE" "${ENV_FILE}.bak"
        
        # Image-Namen mit korrekten Tags aktualisieren
        sed -i 's|:latest|:main|g' "$ENV_FILE"
        
        # Sicherstellen, dass die korrekten Image-Pfade verwendet werden
        sed -i 's|^BACKEND_IMAGE=.*$|BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:main|g' "$ENV_FILE"
        sed -i 's|^FRONTEND_IMAGE=.*$|FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:main|g' "$ENV_FILE"
        
        log_success ".env-Datei wurde aktualisiert."
        
        # Fragen, ob die Container neu gestartet werden sollen
        read -p "Möchten Sie die Container mit den korrekten Images neu starten? (J/n): " restart
        if [[ ! "$restart" =~ ^[nN]$ ]]; then
            restart_kormit
        fi
    else
        log_error ".env-Datei nicht gefunden: $ENV_FILE"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
    fi
}

pull_images() {
    print_header "Images werden manuell gezogen"
    
    log_info "Docker-Images werden manuell heruntergeladen..."
    
    # Bekannte korrekte Image-Pfade
    BACKEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-backend:main"
    FRONTEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-frontend:main"
    
    # Versuchen, die Images zu ziehen
    if docker pull "$BACKEND_IMAGE"; then
        log_success "Backend-Image erfolgreich heruntergeladen: $BACKEND_IMAGE"
    else
        log_error "Konnte Backend-Image nicht herunterladen: $BACKEND_IMAGE"
    fi
    
    if docker pull "$FRONTEND_IMAGE"; then
        log_success "Frontend-Image erfolgreich heruntergeladen: $FRONTEND_IMAGE"
    else
        log_error "Konnte Frontend-Image nicht herunterladen: $FRONTEND_IMAGE"
    fi
    
    # .env-Datei aktualisieren
    ENV_FILE="$INSTALL_DIR/docker/production/.env"
    
    if [ -f "$ENV_FILE" ]; then
        log_info ".env-Datei wird mit den korrekten Images aktualisiert..."
        
        # Backup erstellen
        cp "$ENV_FILE" "${ENV_FILE}.bak"
        
        # Image-Namen aktualisieren
        sed -i "s|^BACKEND_IMAGE=.*$|BACKEND_IMAGE=$BACKEND_IMAGE|g" "$ENV_FILE"
        sed -i "s|^FRONTEND_IMAGE=.*$|FRONTEND_IMAGE=$FRONTEND_IMAGE|g" "$ENV_FILE"
        
        log_success ".env-Datei wurde aktualisiert."
    else
        log_warning ".env-Datei nicht gefunden: $ENV_FILE"
        log_info "Es wird eine neue .env-Datei erstellt..."
        
        mkdir -p "$INSTALL_DIR/docker/production"
        
        # Zufällige Passwörter generieren
        DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
        SECRET_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
        
        # Neue .env-Datei erstellen
        cat > "$ENV_FILE" << EOL
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=$DB_PASSWORD
DB_NAME=kormit
SECRET_KEY=$SECRET_KEY
DOMAIN_NAME=localhost
TIMEZONE=UTC
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=80
HTTPS_PORT=443

# Image-Konfiguration
BACKEND_IMAGE=$BACKEND_IMAGE
FRONTEND_IMAGE=$FRONTEND_IMAGE
EOL
        
        log_success "Neue .env-Datei wurde erstellt."
    fi
    
    # Fragen, ob die Container neu gestartet werden sollen
    read -p "Möchten Sie die Container mit den korrekten Images neu starten? (J/n): " restart
    if [[ ! "$restart" =~ ^[nN]$ ]]; then
        restart_kormit
    fi
}

repair_installation() {
    print_header "Installation wird repariert"
    
    echo -e "${YELLOW}Bitte wählen Sie eine Reparaturoption:${RESET}"
    echo -e "1) ${BOLD}Nur Skripte reparieren${RESET} - Start-, Stop- und Update-Skripte"
    echo -e "2) ${BOLD}Image-Tags korrigieren${RESET} - Falsche Tags in der .env-Datei beheben"
    echo -e "3) ${BOLD}Images manuell ziehen${RESET} - Korrekte Docker-Images herunterladen"
    echo -e "4) ${BOLD}Komplette Reparatur${RESET} - Alle oben genannten Optionen ausführen"
    echo -e "0) ${BOLD}Zurück${RESET} - Zum Hauptmenü zurückkehren"
    
    read -p "Option (0-4): " repair_option
    
    case $repair_option in
        1)
            repair_scripts
            ;;
        2)
            fix_image_tags
            ;;
        3)
            pull_images
            ;;
        4)
            repair_scripts
            pull_images
            ;;
        0)
            return
            ;;
        *)
            log_error "Ungültige Option."
            repair_installation
            ;;
    esac
}

offer_repair_scripts() {
    echo -e "${YELLOW}Möchten Sie eine Reparatur durchführen? (j/N)${RESET}"
    read -p "> " repair
    if [[ "$repair" =~ ^[jJ]$ ]]; then
        repair_installation
    fi
}

# Interaktives Menü
show_menu() {
    print_logo
    echo -e "${CYAN}${BOLD}HAUPTMENÜ${RESET}"
    echo -e "${CYAN}═════════${RESET}"
    echo -e "1) ${BOLD}Abhängigkeiten prüfen${RESET} - Docker, Git, etc."
    echo -e "2) ${BOLD}Repository klonen/aktualisieren${RESET} - Neueste Code-Version holen"
    echo -e "3) ${BOLD}Kormit installieren${RESET} - Neue Installation durchführen"
    echo -e "${CYAN}───────────────────────────${RESET}"
    echo -e "4) ${BOLD}Kormit starten${RESET} - Dienst starten"
    echo -e "5) ${BOLD}Kormit stoppen${RESET} - Dienst anhalten"
    echo -e "6) ${BOLD}Kormit neustarten${RESET} - Dienst neu starten"
    echo -e "7) ${BOLD}Kormit aktualisieren${RESET} - Auf neue Version aktualisieren"
    echo -e "${CYAN}───────────────────────────${RESET}"
    echo -e "8) ${BOLD}Logs anzeigen${RESET} - Container-Logs einsehen"
    echo -e "9) ${BOLD}Status anzeigen${RESET} - Aktuellen Dienststatus prüfen"
    echo -e "10) ${BOLD}Installation reparieren${RESET} - Erweiterte Reparaturfunktionen"
    echo -e "11) ${BOLD}Image-Tags korrigieren${RESET} - Manifest-unknown-Fehler beheben"
    echo -e "${CYAN}───────────────────────────${RESET}"
    echo -e "12) ${BOLD}Debug-Modus${RESET} - Toggle Debug (aktuell: $([ "$DEBUG" = true ] && echo "AN" || echo "AUS"))"
    echo -e "13) ${BOLD}Installationsverzeichnis ändern${RESET} - (aktuell: $INSTALL_DIR)"
    echo -e "${CYAN}───────────────────────────${RESET}"
    echo -e "0) ${BOLD}Beenden${RESET} - Programm beenden"
    echo ""
    echo -e "Wählen Sie eine Option (0-13):"
    read -p "> " choice
    
    case $choice in
        1)
            check_dependencies
            press_enter_to_continue
            ;;
        2)
            update_repository
            press_enter_to_continue
            ;;
        3)
            install_kormit
            press_enter_to_continue
            ;;
        4)
            start_kormit
            press_enter_to_continue
            ;;
        5)
            stop_kormit
            press_enter_to_continue
            ;;
        6)
            restart_kormit
            press_enter_to_continue
            ;;
        7)
            update_kormit
            press_enter_to_continue
            ;;
        8)
            show_logs
            # Nach less brauchen wir keinen press_enter
            ;;
        9)
            check_status
            press_enter_to_continue
            ;;
        10)
            repair_installation
            press_enter_to_continue
            ;;
        11)
            fix_image_tags
            press_enter_to_continue
            ;;
        12)
            if [ "$DEBUG" = true ]; then
                DEBUG=false
                log_info "Debug-Modus deaktiviert."
            else
                DEBUG=true
                log_info "Debug-Modus aktiviert."
            fi
            press_enter_to_continue
            ;;
        13)
            echo -e "Aktuelles Installationsverzeichnis: ${BOLD}$INSTALL_DIR${RESET}"
            read -p "Neues Installationsverzeichnis eingeben: " new_dir
            if [ -n "$new_dir" ]; then
                INSTALL_DIR="$new_dir"
                log_info "Installationsverzeichnis geändert auf: ${BOLD}$INSTALL_DIR${RESET}"
            fi
            press_enter_to_continue
            ;;
        0)
            echo -e "${GREEN}Auf Wiedersehen!${RESET}"
            exit 0
            ;;
        *)
            log_error "Ungültige Option. Bitte wählen Sie eine Zahl zwischen 0 und 13."
            press_enter_to_continue
            ;;
    esac
}

press_enter_to_continue() {
    echo ""
    read -p "Drücken Sie Enter, um fortzufahren..."
}

# Hauptfunktion
main() {
    # Root-Rechte prüfen
    check_root
    
    # Betriebssystem erkennen
    detect_os
    
    # Menü in Schleife anzeigen
    while true; do
        clear
        show_menu
    done
}

# Skript starten
main
