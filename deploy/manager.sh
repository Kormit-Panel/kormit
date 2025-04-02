#!/usr/bin/env bash
# Kormit Management Script v2.0
# Ein modernes Tool zur Installation und Verwaltung von Kormit
# Version 2.0.0 - Komplette Überarbeitung mit verbesserter Benutzerfreundlichkeit

# Strict Mode für bessere Fehlerhandhabung
set -eo pipefail

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
CONFIG_FILE="$HOME/.kormit_config"

# Globale Variablen
KORMIT_MANAGER_VERSION="2.0.0-Pro"
VERSION="2.0.0"
DOMAIN_NAME="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
USE_HTTPS=false # Standard: HTTP-only für einfachere Installation
DEBUG=false
ANIMATION_ENABLED=false # Standard: Animationen deaktiviert
AUTO_UPDATE_CHECK=true
LAST_CHECK_TIME=0

# Lese vorherige Konfiguration, falls vorhanden
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_debug "Lade Konfiguration aus $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

# Speichere aktuelle Konfiguration
save_config() {
    log_debug "Speichere Konfiguration in $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOL
# Kormit Manager Konfigurationsdatei
# Automatisch generiert - Manuelle Änderungen werden überschrieben
INSTALL_DIR="$INSTALL_DIR"
DOMAIN_NAME="$DOMAIN_NAME"
HTTP_PORT="$HTTP_PORT"
HTTPS_PORT="$HTTPS_PORT"
USE_HTTPS=$USE_HTTPS
DEBUG=$DEBUG
ANIMATION_ENABLED=$ANIMATION_ENABLED
AUTO_UPDATE_CHECK=$AUTO_UPDATE_CHECK
LAST_CHECK_TIME=$LAST_CHECK_TIME
EOL
}

# Überprüfen, ob das Skript als Root ausgeführt wird
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${RED}${BOLD}✘ Dieses Skript muss als Root ausgeführt werden.${RESET}"
        echo -e "${YELLOW}Bitte mit 'sudo' oder als Root-Benutzer ausführen.${RESET}"
        exit 1
    fi
}

# Ausgabe-Funktionen
print_logo() {
    # Statisches Logo
    clear
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
    echo -e "║     ${GREEN}Kormit Manager Version:${RESET} ${MAGENTA}$KORMIT_MANAGER_VERSION${CYAN}                    ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║                                                                ║"
    echo -e "║   ${MAGENTA}⚡ ${YELLOW}CONTROL CENTER${CYAN}                                           ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_header() {
    local title="$1"
    echo -e "\n${BLUE}${BOLD}▶ ${title} ${RESET}"
    echo -e "${BLUE}  $(printf '═%.0s' {1..60})${RESET}"
}

log_info() {
    echo -e "${CYAN}${BOLD}[ℹ️] ${RESET}$1"
}

log_success() {
    echo -e "${GREEN}${BOLD}[✅] ${RESET}$1"
}

log_warning() {
    echo -e "${YELLOW}${BOLD}[⚠️] ${RESET}$1"
}

log_error() {
    echo -e "${RED}${BOLD}[❌] ${RESET}$1"
}

log_debug() {
    if [[ "$DEBUG" = true ]]; then
        echo -e "${DIM}[🔍] ${RESET}$1"
    fi
}

# Fortschrittsbalken für lange Operationen
progress_bar() {
    local duration=$1
    local prefix=$2
    local size=40
    local char="▓"
    local empty="░"
    
    if [[ "$ANIMATION_ENABLED" = false ]]; then
        echo -e "${prefix} - Wird ausgeführt..."
        sleep "$duration"
        return
    fi
    
    for ((i = 0; i <= size; i++)); do
        local pct=$((i * 100 / size))
        local progress=""
        local remaining=""
        
        for ((j = 0; j <= i; j++)); do
            progress="${progress}${char}"
        done
        
        for ((j = i + 1; j <= size; j++)); do
            remaining="${remaining}${empty}"
        done
        
        sleep "$(echo "$duration/$size" | bc -l)"
        
        echo -ne "\r${prefix} [${progress}${remaining}] ${pct}%"
    done
    echo -e "\r${prefix} [$(printf "%${size}s" | tr ' ' "$char")] 100% ${GREEN}✓${RESET}"
}

# Verbesserte Spinner für lange Operationen
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    if [[ "$ANIMATION_ENABLED" = false ]]; then
        echo -e "${message} - Wird ausgeführt..."
        wait "$pid"
        return
    fi
    
    echo -n "${message} "
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "${CYAN}%c${RESET}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    
    wait "$pid"
    local exit_status=$?
    
    if [[ $exit_status -eq 0 ]]; then
        echo -e "${GREEN}✓${RESET}"
    else
        echo -e "${RED}✗${RESET}"
        return $exit_status
    fi
}

# Funktion zum Ausführen von Befehlen mit einem Spinner
run_with_spinner() {
    local cmd="$1"
    local msg="$2"
    
    log_debug "Führe aus: $cmd"
    
    eval "$cmd" > /dev/null 2>&1 &
    spinner $! "${BOLD}${msg}${RESET}"
    
    return $?
}

# Funktion zum Ausführen von Befehlen mit einem Fortschrittsbalken
run_with_progress() {
    local cmd="$1"
    local msg="$2"
    local time="$3"
    
    log_debug "Führe aus: $cmd"
    
    eval "$cmd" > /dev/null 2>&1 &
    local pid=$!
    
    progress_bar "$time" "${BOLD}${msg}${RESET}"
    
    wait $pid
    return $?
}

# Prüfen, ob Updates für das Skript verfügbar sind
check_for_updates() {
    if [[ "$AUTO_UPDATE_CHECK" = false ]]; then
        return
    fi
    
    # Prüfe nur einmal täglich
    local current_time
    current_time=$(date +%s)
    local one_day=86400
    
    if [[ $((current_time - LAST_CHECK_TIME)) -lt $one_day ]]; then
        log_debug "Letzter Update-Check war vor weniger als einem Tag - überspringe"
        return
    fi
    
    log_debug "Prüfe auf Updates für den Kormit Manager..."
    
    run_with_spinner "git ls-remote --tags $REPO_URL | grep -o 'refs/tags/v[0-9]*\.[0-9]*\.[0-9]*' | sort -V | tail -n 1 | cut -d'/' -f3 > /tmp/kormit_latest" "Prüfe auf Updates"
    
    if [[ -f /tmp/kormit_latest ]]; then
        local latest_version
        latest_version=$(cat /tmp/kormit_latest)
        rm /tmp/kormit_latest
        
        if [[ "v$VERSION" != "$latest_version" ]]; then
            log_warning "Eine neue Version des Kormit Managers ist verfügbar: ${YELLOW}${latest_version}${RESET} (aktuell: v${VERSION})"
            echo -e "Möchten Sie den Manager aktualisieren? (j/N): "
            read -rp "> " update_choice
            
            if [[ "$update_choice" =~ ^[jJ]$ ]]; then
                update_manager
            fi
        else
            log_debug "Der Kormit Manager ist aktuell (v${VERSION})"
        fi
    fi
    
    LAST_CHECK_TIME=$current_time
    save_config
}

# Update des Manager-Skripts
update_manager() {
    print_header "Manager-Update"
    
    log_info "Hole die neueste Version des Kormit Managers..."
    
    # Temporäres Verzeichnis erstellen
    TMP_UPDATE_DIR="/tmp/kormit-manager-update"
    mkdir -p "$TMP_UPDATE_DIR"
    
    # Repository klonen
    if run_with_spinner "git clone --depth 1 $REPO_URL $TMP_UPDATE_DIR" "Repository wird geklont"; then
        # Backup des aktuellen Skripts
        cp "$0" "$0.backup"
        
        # Manager-Skript ersetzen
        if cp "$TMP_UPDATE_DIR/deploy/manager.sh" "$0"; then
            chmod +x "$0"
            log_success "Der Kormit Manager wurde aktualisiert. Starte neu..."
            # Altes Temporärverzeichnis aufräumen
            rm -rf "$TMP_UPDATE_DIR"
            # Skript neu starten
            exec "$0" "$@"
        else
            log_error "Fehler beim Aktualisieren des Managers."
            log_info "Backup wiederhergestellt: $0.backup"
        fi
    else
        log_error "Fehler beim Klonen des Repositories."
        log_info "Der Manager wurde nicht aktualisiert."
        rm -rf "$TMP_UPDATE_DIR"
    fi
}

# Prüfe die Betriebssystemumgebung
detect_environment() {
    # Prüfe auf WSL/Windows-Umgebung
    if uname -r | grep -q "microsoft" || [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        OS_ENV="WSL"
        log_info "Windows Subsystem für Linux (WSL) erkannt"
    elif [[ "$(uname)" = "Darwin" ]]; then
        OS_ENV="MacOS"
        log_info "MacOS-Umgebung erkannt"
    elif [[ "$(uname)" = "Linux" ]]; then
        OS_ENV="Linux"
        log_info "Linux-Umgebung erkannt"
    else
        OS_ENV="Unbekannt"
        log_warning "Unbekannte Betriebssystemumgebung"
    fi
}

# Systemprüfung und Voraussetzungen
detect_os() {
    run_with_spinner "sleep 1" "Betriebssystem wird erkannt"
    
    # Systemumgebung erkennen
    detect_environment
    
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
        log_success "Erkanntes Betriebssystem: ${BOLD}$OS $VERSION_ID${RESET}"
    elif [[ "$OS_ENV" = "MacOS" ]]; then
        OS="macos"
        VERSION_ID=$(sw_vers -productVersion)
        log_success "Erkanntes Betriebssystem: ${BOLD}macOS $VERSION_ID${RESET}"
    elif [[ "$OS_ENV" = "WSL" ]]; then
        if [[ -f /etc/os-release ]]; then
            # shellcheck source=/dev/null
            source /etc/os-release
            OS="wsl-$ID"
            VERSION_ID=$VERSION_ID
            log_success "Erkanntes Betriebssystem: ${BOLD}WSL - $ID $VERSION_ID${RESET}"
        else
            OS="wsl-unknown"
            VERSION_ID="unknown"
            log_warning "WSL erkannt, aber Distribution konnte nicht bestimmt werden"
        fi
    else
        log_error "Betriebssystem konnte nicht erkannt werden."
        exit 1
    fi
}

check_dependencies() {
    print_header "Abhängigkeiten werden überprüft"
    
    # Systemvoraussetzungen als Array
    local dependencies=(
        "git:Git ist erforderlich für das Herunterladen des Codes:install_git"
        "docker:Docker ist erforderlich für die Container-Virtualisierung:install_docker"
        "docker-compose:Docker Compose oder das Plugin ist erforderlich für die Container-Orchestrierung:install_docker_compose"
        "curl:Curl ist für Downloads und API-Aufrufe erforderlich:install_curl"
        "dialog:Dialog wird für eine verbesserte Benutzeroberfläche empfohlen:install_dialog"
    )
    
    local all_passed=true
    
    for dep in "${dependencies[@]}"; do
        # Aufteilung des Strings in Command, Nachricht und Installationsfunktion
        IFS=':' read -r cmd msg install_func <<< "$dep"
        
        # Prüfe Docker Compose auch als Plugin
        if [[ "$cmd" = "docker-compose" ]] && docker compose version &> /dev/null; then
            log_success "Docker Compose Plugin ist installiert"
            continue
        fi
        
        # Prüfe, ob der Befehl verfügbar ist
        if command -v "$cmd" &> /dev/null; then
            case "$cmd" in
                git)
                    log_success "Git ist installiert: $(git --version | head -n 1)"
                    ;;
                docker)
                    log_success "Docker ist installiert: $(docker --version | head -n 1)"
                    if ! docker info &> /dev/null; then
                        log_warning "Docker ist installiert, aber der Docker-Daemon ist nicht aktiv"
                        log_info "Versuche den Docker-Dienst zu starten..."
                        if systemctl start docker &> /dev/null; then
                            log_success "Docker-Dienst erfolgreich gestartet"
                        else
                            log_error "Konnte den Docker-Dienst nicht starten. Bitte manuell starten."
                            all_passed=false
                        fi
                    fi
                    ;;
                docker-compose)
                    log_success "Docker Compose Legacy ist installiert: $(docker-compose --version | head -n 1)"
                    ;;
                *)
                    log_success "$cmd ist installiert"
                    ;;
            esac
        else
            log_warning "$msg"
            
            # Frage, ob die Abhängigkeit installiert werden soll
            echo -e "Möchten Sie $cmd jetzt installieren? (J/n): "
            read -rp "> " install_choice
            
            if [[ ! "$install_choice" =~ ^[nN]$ ]]; then
                # Rufe die Installationsfunktion auf
                if declare -F "$install_func" > /dev/null; then
                    "$install_func"
                    if command -v "$cmd" &> /dev/null; then
                        log_success "$cmd wurde erfolgreich installiert"
                    else
                        log_error "$cmd konnte nicht installiert werden"
                        all_passed=false
                    fi
                else
                    log_error "Installationsfunktion für $cmd nicht gefunden"
                    all_passed=false
                fi
            else
                log_warning "$cmd wird für den ordnungsgemäßen Betrieb benötigt"
                all_passed=false
            fi
        fi
    done
    
    if [[ "$all_passed" = true ]]; then
        log_success "Alle Abhängigkeiten sind erfüllt! 🚀"
        return 0
    else
        log_warning "Einige Abhängigkeiten fehlen. Einige Funktionen könnten eingeschränkt sein."
        return 1
    fi
}

install_git() {
    log_info "Git wird installiert..."
    
    run_with_spinner "case $OS in
        ubuntu|debian)
            apt update && apt install -y git
            ;;
        centos|rhel|fedora)
            yum install -y git
            ;;
        alpine)
            apk add --no-cache git
            ;;
        *)
            exit 1
            ;;
    esac" "Git wird installiert"
    
    if [[ $? -ne 0 ]]; then
        log_error "Git-Installation fehlgeschlagen. Bitte manuell installieren."
        return 1
    fi
}

install_docker() {
    log_info "Docker wird installiert..."
    
    case $OS in
        ubuntu|debian)
            run_with_spinner "apt update && apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg" "Abhängigkeiten werden installiert"
            run_with_spinner "curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" "Repository-Schlüssel werden heruntergeladen"
            run_with_spinner "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null" "Repository wird hinzugefügt"
            run_with_spinner "apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin" "Docker wird installiert"
            run_with_spinner "systemctl start docker && systemctl enable docker" "Docker-Dienst wird aktiviert"
            ;;
        centos|rhel|fedora)
            run_with_spinner "yum install -y yum-utils" "Abhängigkeiten werden installiert"
            run_with_spinner "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo" "Repository wird hinzugefügt"
            run_with_spinner "yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin" "Docker wird installiert"
            run_with_spinner "systemctl start docker && systemctl enable docker" "Docker-Dienst wird aktiviert"
            ;;
        alpine)
            run_with_spinner "apk add --no-cache docker docker-compose" "Docker wird installiert"
            run_with_spinner "service docker start" "Docker-Dienst wird gestartet"
            ;;
        *)
            log_error "Nicht unterstütztes Betriebssystem für die Docker-Installation."
            return 1
            ;;
    esac
    
    # Prüfen, ob Docker erfolgreich installiert wurde
    if command -v docker &> /dev/null; then
        log_success "Docker wurde erfolgreich installiert: $(docker --version)"
        
        # Füge den aktuellen Benutzer zur docker-Gruppe hinzu, falls nicht root
        if [[ "$(id -u)" -ne 0 ]]; then
            log_info "Füge den Benutzer $(whoami) zur docker-Gruppe hinzu..."
            if getent group docker &> /dev/null; then
                usermod -aG docker "$(whoami)"
                log_info "Benutzer wurde zur docker-Gruppe hinzugefügt. Ein Neustart der Shell könnte erforderlich sein."
            else
                log_warning "Docker-Gruppe existiert nicht - könnte Probleme verursachen."
            fi
        fi
        
        return 0
    else
        log_error "Docker konnte nicht installiert werden."
        return 1
    fi
}

install_docker_compose() {
    # Prüfen, ob Docker Compose bereits als Plugin installiert ist
    if docker compose version &> /dev/null; then
        log_success "Docker Compose Plugin ist bereits installiert."
        return 0
    fi
    
    # Prüfen, ob Docker Compose Legacy bereits installiert ist
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose Legacy ist bereits installiert."
        return 0
    fi
    
    log_info "Docker Compose wird installiert..."
    
    # Neueste Version ermitteln
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$COMPOSE_VERSION" ]]; then
        log_warning "Konnte die neueste Docker Compose-Version nicht ermitteln. Verwende Standardversion."
        COMPOSE_VERSION="v2.18.1"
    fi
    
    run_with_spinner "
    mkdir -p /usr/local/lib/docker/cli-plugins
        curl -SL \"https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    " "Docker Compose wird installiert"
    
    # Prüfen, ob die Installation erfolgreich war
    if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
        log_success "Docker Compose wurde erfolgreich installiert."
        return 0
    else
        log_error "Docker Compose konnte nicht installiert werden."
        return 1
    fi
}

install_curl() {
    log_info "Curl wird installiert..."
    
    run_with_spinner "case $OS in
        ubuntu|debian)
            apt update && apt install -y curl
            ;;
        centos|rhel|fedora)
            yum install -y curl
            ;;
        alpine)
            apk add --no-cache curl
            ;;
        *)
        exit 1
            ;;
    esac" "Curl wird installiert"
    
    if [[ $? -ne 0 ]]; then
        log_error "Curl-Installation fehlgeschlagen. Bitte manuell installieren."
        return 1
    fi
}

# Dialog-Tool installieren für bessere UI (wenn verfügbar)
install_dialog() {
    # Prüfen, ob Dialog bereits installiert ist
    if command -v dialog &> /dev/null; then
        return 0
    fi
    
    log_info "Dialog wird installiert für eine verbesserte Benutzeroberfläche..."
    
    run_with_spinner "case $OS in
        ubuntu|debian)
            apt update && apt install -y dialog
            ;;
        centos|rhel|fedora)
            yum install -y dialog
            ;;
        alpine)
            apk add --no-cache dialog
            ;;
        *)
            exit 1
            ;;
    esac" "Dialog wird installiert"
    
    if command -v dialog &> /dev/null; then
        log_success "Dialog wurde erfolgreich installiert."
        return 0
    else
        log_warning "Dialog konnte nicht installiert werden. Fallback auf Text-UI."
        return 1
    fi
}

# Funktionen für Repository-Management
clone_repository() {
    print_header "Repository wird geklont"
    
    # Prüfen, ob TMP_DIR existiert und löschen, falls ja
    if [[ -d "$TMP_DIR" ]]; then
        log_info "Vorhandenes temporäres Verzeichnis wird entfernt..."
        rm -rf "$TMP_DIR"
    fi
    
    # Repository klonen
    log_info "Kormit Repository wird geklont..."
    
    mkdir -p "$TMP_DIR"
    
    if run_with_spinner "git clone --depth 1 $REPO_URL $TMP_DIR" "Kormit Repository wird geklont"; then
        log_success "Repository wurde erfolgreich geklont."
        return 0
    else
        log_error "Repository konnte nicht geklont werden."
        
        # Prüfen, ob es ein Netzwerkproblem ist
        if ! curl -s --head https://github.com | grep "HTTP/" > /dev/null; then
            log_error "Netzwerkverbindung zu GitHub fehlgeschlagen. Bitte überprüfen Sie Ihre Internetverbindung."
        fi
        
        return 1
    fi
}

update_repository() {
    print_header "Repository wird aktualisiert"
    
    # Prüfen, ob TMP_DIR existiert
    if [[ ! -d "$TMP_DIR" ]]; then
        log_info "Temporäres Verzeichnis nicht gefunden, Repository wird frisch geklont..."
        clone_repository
        return $?
    fi
    
    # Repository aktualisieren
    log_info "Kormit Repository wird aktualisiert..."
    
    cd "$TMP_DIR" || { 
        log_error "Konnte nicht in das Verzeichnis $TMP_DIR wechseln"; 
        return 1; 
    }
    
    # Prüfen, ob es sich um ein Git-Repository handelt
    if [[ ! -d ".git" ]]; then
        log_warning "Das Verzeichnis $TMP_DIR ist kein Git-Repository."
        log_info "Repository wird neu geklont..."
        cd - > /dev/null || { 
            log_error "Konnte nicht zurückwechseln"; 
            return 1; 
        }
        clone_repository
        return $?
    fi
    
    if run_with_spinner "git pull" "Repository wird aktualisiert"; then
        log_success "Repository wurde erfolgreich aktualisiert."
        cd - > /dev/null || { 
            log_error "Konnte nicht zurückwechseln"; 
            return 1; 
        }
        return 0
    else
        log_error "Repository konnte nicht aktualisiert werden."
        
        # Versuche, lokale Änderungen zu verwerfen
        log_info "Versuche, lokale Änderungen zurückzusetzen..."
        if run_with_spinner "git reset --hard && git clean -fd && git pull" "Repository wird zurückgesetzt"; then
            log_success "Repository wurde erfolgreich zurückgesetzt und aktualisiert."
            cd - > /dev/null || { 
                log_error "Konnte nicht zurückwechseln"; 
                return 1; 
            }
            return 0
        else
            log_error "Repository konnte nicht zurückgesetzt werden."
            cd - > /dev/null || { 
                log_error "Konnte nicht zurückwechseln"; 
                return 1; 
            }
            
            # Als letzten Ausweg neu klonen
            log_info "Versuche, Repository neu zu klonen..."
            clone_repository
            return $?
        fi
    fi
}

# Funktionen für Kormit-Installation
install_kormit() {
    print_header "Kormit wird installiert"
    
    # Repository klonen, falls noch nicht geschehen
    if [[ ! -d "$TMP_DIR" ]] || [[ ! -d "$TMP_DIR/.git" ]]; then
        if ! clone_repository; then
            log_error "Installation kann nicht fortgesetzt werden, da das Repository nicht geklont werden konnte."
            return 1
        fi
    fi
    
    # Installationsverzeichnis erstellen
    log_info "Installationsverzeichnis wird vorbereitet: ${BOLD}$INSTALL_DIR${RESET}"
    mkdir -p "$INSTALL_DIR"
    
    # Installationsparameter interaktiv erfragen
    if ! get_installation_params; then
        log_warning "Installation wurde abgebrochen."
        return 1
    fi
    
    # Zeige Zusammenfassung und starte Installation
    show_installation_summary
    
    # Frage nach Bestätigung, entweder mit Dialog oder textbasiert
    if command -v dialog &> /dev/null; then
        if ! dialog --clear --backtitle "Kormit Management Tool v$KORMIT_MANAGER_VERSION" \
              --title "Installation starten" \
              --yesno "Möchten Sie mit der Installation fortfahren?" \
              7 60; then
            log_warning "Installation wurde abgebrochen."
            return 1
        fi
        clear
    else
        echo -e "\n${YELLOW}Möchten Sie mit der Installation fortfahren? (J/n)${RESET}"
        read -rp "> " confirm
        if [[ "$confirm" =~ ^[nN]$ ]]; then
            log_warning "Installation wurde abgebrochen."
            return 1
        fi
    fi
    
    # Standard-Installations-Skript ausführen
    log_info "Kormit wird installiert..."
    
    # Erstelle Befehlszeile
    local cmd="$TMP_DIR/deploy/install.sh --install-dir=$INSTALL_DIR --domain=$DOMAIN_NAME --http-port=$HTTP_PORT --https-port=$HTTPS_PORT"
    
    if [[ "$USE_HTTPS" = true ]]; then
        cmd="$cmd --use-https"
    else
        cmd="$cmd --http-only"
    fi
    
    log_debug "Ausführen: $cmd"
    
    # Mache das Skript ausführbar
    chmod +x "$TMP_DIR/deploy/install.sh"
        
    # Führe das Skript aus
    if ! $cmd; then
        log_error "Installation fehlgeschlagen. Überprüfen Sie die Fehlermeldungen."
        
        # Biete Möglichkeit zur Fehlerdiagnose
        echo -e "\n${YELLOW}Möchten Sie die detaillierte Fehlerdiagnose starten? (j/N)${RESET}"
        read -rp "> " debug_choice
        if [[ "$debug_choice" =~ ^[jJ]$ ]]; then
            run_diagnostics
        fi
        
        return 1
    fi
    
    log_success "Kormit wurde erfolgreich installiert."
    
    # Nach der Installation die Image-Tags korrigieren
    log_info "Korrigiere Image-Tags in der .env-Datei..."
    fix_image_tags
    
    # Zeige Zugriffsinformationen
    show_access_info
    
    # Konfiguration speichern
    save_config
    
    return 0
}

# Zeigt eine Zusammenfassung der Installationseinstellungen
show_installation_summary() {
    print_header "Installationszusammenfassung"
    
    echo -e "${BOLD}System:${RESET}"
    echo -e "  - Betriebssystem: ${CYAN}$OS $VERSION_ID${RESET}"
    echo -e "  - Hostname: ${CYAN}$(hostname)${RESET}"
    
    echo -e "\n${BOLD}Installationskonfiguration:${RESET}"
    echo -e "  - Verzeichnis: ${CYAN}$INSTALL_DIR${RESET}"
    echo -e "  - Domain: ${CYAN}$DOMAIN_NAME${RESET}"
    echo -e "  - HTTP-Port: ${CYAN}$HTTP_PORT${RESET}"
    
    if [[ "$USE_HTTPS" = true ]]; then
        echo -e "  - HTTPS-Port: ${CYAN}$HTTPS_PORT${RESET}"
        echo -e "  - SSL: ${GREEN}Aktiviert${RESET} (Selbstsigniertes Zertifikat)"
    else
        echo -e "  - SSL: ${YELLOW}Deaktiviert${RESET} (Nur HTTP)"
    fi
    
    # Speicherplatz prüfen
    local available_space
    available_space=$(df -h "$INSTALL_DIR" | awk 'NR==2 {print $4}')
    echo -e "\n${BOLD}Systemvoraussetzungen:${RESET}"
    echo -e "  - Verfügbarer Speicherplatz: ${CYAN}$available_space${RESET}"
    echo -e "  - Benötigter Speicherplatz: ${CYAN}~500MB${RESET}"
    
    # RAM-Nutzung prüfen
    local total_ram
    total_ram=$(free -h | awk 'NR==2 {print $2}')
    echo -e "  - Verfügbarer RAM: ${CYAN}$total_ram${RESET}"
    echo -e "  - Empfohlener RAM: ${CYAN}≥ 2GB${RESET}"
}

# Zeigt Zugriffsinformationen nach erfolgreicher Installation
show_access_info() {
    print_header "Zugriffsinformationen"
    
    # Server-IP oder Domain anzeigen
    local ACCESS_URL
    if [[ "$DOMAIN_NAME" = "localhost" ]]; then
        # Versuche, die öffentliche IP zu ermitteln
        local SERVER_IP
        SERVER_IP=$(hostname -I | awk '{print $1}')
        if [[ -z "$SERVER_IP" ]]; then
            SERVER_IP="localhost"
        fi
        ACCESS_URL="$SERVER_IP"
    else
        ACCESS_URL="$DOMAIN_NAME"
    fi
    
    echo -e "${GREEN}${BOLD}Kormit wurde erfolgreich installiert und ist nun erreichbar unter:${RESET}"
    
    if [[ "$USE_HTTPS" = true ]]; then
        echo -e "  ${CYAN}${UNDERLINE}https://${ACCESS_URL}:${HTTPS_PORT}${RESET}"
        
        # Hinweis für selbstsignierte Zertifikate
        echo -e "\n${YELLOW}Hinweis: Da ein selbstsigniertes Zertifikat verwendet wird, werden Browser eine Sicherheitswarnung anzeigen.${RESET}"
        echo -e "${YELLOW}Sie können diese Warnung bestätigen, um fortzufahren.${RESET}"
    else
        echo -e "  ${CYAN}${UNDERLINE}http://${ACCESS_URL}:${HTTP_PORT}${RESET}"
    fi
    
    echo -e "\n${BOLD}Management-Befehle:${RESET}"
    echo -e "  ${GREEN}Starten:${RESET}    $INSTALL_DIR/start.sh"
    echo -e "  ${RED}Stoppen:${RESET}     $INSTALL_DIR/stop.sh"
    echo -e "  ${BLUE}Aktualisieren:${RESET} $INSTALL_DIR/update.sh"
    
    echo -e "\n${BOLD}Anmeldeinformationen:${RESET}"
    echo -e "  Das ${BOLD}Admin-Passwort${RESET} finden Sie in der ersten Log-Ausgabe nach dem Start."
    echo -e "  Verwenden Sie den Befehl: ${CYAN}docker logs \$(docker ps | grep kormit-backend | awk '{print \$1}') | grep -A 1 'Admin-Passwort'${RESET}"
}

get_installation_params() {
    # Dialog verwenden, wenn verfügbar
    if command -v dialog &> /dev/null; then
        # Dialog-basierte Eingabe
        get_installation_params_dialog
    else
        # Textbasierte Eingabe
        get_installation_params_text
    fi
    
    return 0
}

# Dialog-basierte Parametereingabe
get_installation_params_dialog() {
    local BACKTITLE="Kormit Management Tool v$KORMIT_MANAGER_VERSION"
    local TITLE="Installationsparameter"
    
    # Domain-Name mit Validierung
    while true; do
        local user_domain=$(dialog --clear --backtitle "$BACKTITLE" \
                           --title "$TITLE" \
                           --inputbox "Domain-Name oder IP-Adresse\n(z.B. example.com oder 192.168.1.10):" \
                           10 60 "$DOMAIN_NAME" \
                           2>&1 >/dev/tty)
        
        # Abbruch bei ESC oder Cancel
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        if [[ -n "$user_domain" ]]; then
            # Prüfe, ob es ein gültiger Domainname oder eine IP ist
            if [[ "$user_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]] || [[ "$user_domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                DOMAIN_NAME="$user_domain"
                break
            else
                dialog --clear --backtitle "$BACKTITLE" \
                       --title "Fehler" \
                       --msgbox "Ungültiger Domain-Name oder IP-Adresse. Bitte erneut eingeben." \
                       7 60
            fi
        else
            break
        fi
    done
    
    # HTTPS verwenden?
    if dialog --clear --backtitle "$BACKTITLE" \
              --title "$TITLE" \
              --yesno "HTTPS verwenden?\n\nJa - HTTPS mit SSL/TLS aktivieren\nNein - Nur HTTP verwenden (einfachere Konfiguration)" \
              10 60; then
        USE_HTTPS=true
        
        # Überprüfe, ob OpenSSL installiert ist
        if ! command -v openssl &> /dev/null; then
            if dialog --clear --backtitle "$BACKTITLE" \
                      --title "OpenSSL nicht gefunden" \
                      --yesno "OpenSSL ist für HTTPS erforderlich, aber nicht installiert. Möchten Sie es jetzt installieren?" \
                      7 60; then
                install_openssl
                
                if ! command -v openssl &> /dev/null; then
                    dialog --clear --backtitle "$BACKTITLE" \
                           --title "Fehler" \
                           --msgbox "OpenSSL konnte nicht installiert werden. Fallback auf HTTP-only." \
                           7 60
                    USE_HTTPS=false
                fi
            else
                dialog --clear --backtitle "$BACKTITLE" \
                       --title "HTTPS deaktiviert" \
                       --msgbox "HTTPS wurde deaktiviert, da OpenSSL nicht installiert ist." \
                       7 60
                USE_HTTPS=false
            fi
        fi
    else
        USE_HTTPS=false
    fi
    
    # HTTP-Port mit Validierung
    while true; do
        local user_http_port=$(dialog --clear --backtitle "$BACKTITLE" \
                               --title "$TITLE" \
                               --inputbox "HTTP-Port:" \
                               10 60 "$HTTP_PORT" \
                               2>&1 >/dev/tty)
        
        # Abbruch bei ESC oder Cancel
        if [[ $? -ne 0 ]]; then
            break  # Standardwert verwenden
        fi
        
        if [[ -n "$user_http_port" ]]; then
            # Prüfe, ob es sich um eine gültige Portnummer handelt
            if [[ "$user_http_port" =~ ^[0-9]+$ ]] && [[ "$user_http_port" -ge 1 ]] && [[ "$user_http_port" -le 65535 ]]; then
                # Prüfe, ob der Port bereits belegt ist
                if check_port "$user_http_port"; then
                    HTTP_PORT="$user_http_port"
                    break
                else
                    dialog --clear --backtitle "$BACKTITLE" \
                           --title "Fehler" \
                           --msgbox "Port $user_http_port ist bereits belegt. Bitte wählen Sie einen anderen Port." \
                           7 60
                fi
            else
                dialog --clear --backtitle "$BACKTITLE" \
                       --title "Fehler" \
                       --msgbox "Ungültige Portnummer. Bitte geben Sie eine Zahl zwischen 1 und 65535 ein." \
                       7 60
            fi
        else
            break  # Standardwert verwenden
        fi
    done
    
    # Prüfe, ob der Standardport verfügbar ist
    if ! check_port "$HTTP_PORT"; then
        # Suche nach einem freien Port
        for try_port in 8080 8000 8888 9000 3000; do
            if check_port "$try_port"; then
                dialog --clear --backtitle "$BACKTITLE" \
                       --title "Port geändert" \
                       --msgbox "Der Standardport $HTTP_PORT ist bereits belegt.\nPort $try_port ist verfügbar und wird verwendet." \
                       8 60
                HTTP_PORT="$try_port"
                break
            fi
        done
    fi
    
    # HTTPS-Port (nur wenn HTTPS aktiviert ist)
    if [[ "$USE_HTTPS" = true ]]; then
        while true; do
            local user_https_port=$(dialog --clear --backtitle "$BACKTITLE" \
                                   --title "$TITLE" \
                                   --inputbox "HTTPS-Port:" \
                                   10 60 "$HTTPS_PORT" \
                                   2>&1 >/dev/tty)
            
            # Abbruch bei ESC oder Cancel
            if [[ $? -ne 0 ]]; then
                break  # Standardwert verwenden
            fi
            
            if [[ -n "$user_https_port" ]]; then
                # Prüfe, ob es sich um eine gültige Portnummer handelt
                if [[ "$user_https_port" =~ ^[0-9]+$ ]] && [[ "$user_https_port" -ge 1 ]] && [[ "$user_https_port" -le 65535 ]]; then
                    # Stelle sicher, dass HTTP- und HTTPS-Ports unterschiedlich sind
                    if [[ "$user_https_port" = "$HTTP_PORT" ]]; then
                        dialog --clear --backtitle "$BACKTITLE" \
                               --title "Fehler" \
                               --msgbox "HTTPS-Port und HTTP-Port dürfen nicht identisch sein." \
                               7 60
                    elif check_port "$user_https_port"; then
                        HTTPS_PORT="$user_https_port"
                        break
                    else
                        dialog --clear --backtitle "$BACKTITLE" \
                               --title "Fehler" \
                               --msgbox "Port $user_https_port ist bereits belegt. Bitte wählen Sie einen anderen Port." \
                               7 60
                    fi
                else
                    dialog --clear --backtitle "$BACKTITLE" \
                           --title "Fehler" \
                           --msgbox "Ungültige Portnummer. Bitte geben Sie eine Zahl zwischen 1 und 65535 ein." \
                           7 60
                fi
            else
                break  # Standardwert verwenden
            fi
        done
        
        # Prüfe, ob der Standardport verfügbar ist
        if ! check_port "$HTTPS_PORT"; then
            # Suche nach einem freien Port
            for try_port in 8443 4443 9443 10443; do
                if check_port "$try_port"; then
                    dialog --clear --backtitle "$BACKTITLE" \
                           --title "Port geändert" \
                           --msgbox "Der Standardport $HTTPS_PORT ist bereits belegt.\nPort $try_port ist verfügbar und wird verwendet." \
                           8 60
                    HTTPS_PORT="$try_port"
                    break
                fi
            done
        fi
    fi
    
    # Frage nach erweiterten Optionen
    if dialog --clear --backtitle "$BACKTITLE" \
              --title "$TITLE" \
              --yesno "Möchten Sie erweiterte Installationsoptionen konfigurieren?" \
              7 60; then
        configure_advanced_options_dialog
    fi
    
    # Zeige Zusammenfassung
    local SUMMARY="Domain: $DOMAIN_NAME\n"
    SUMMARY+="HTTP-Port: $HTTP_PORT\n"
    
    if [[ "$USE_HTTPS" = true ]]; then
        SUMMARY+="HTTPS-Port: $HTTPS_PORT\n"
        SUMMARY+="HTTPS: Aktiviert"
    else
        SUMMARY+="HTTPS: Deaktiviert"
    fi
    
    dialog --clear --backtitle "$BACKTITLE" \
           --title "Zusammenfassung" \
           --msgbox "$SUMMARY" \
           10 60
    
    # Dialog schließen
    clear
}

# Textbasierte Parametereingabe (alte Methode)
get_installation_params_text() {
    echo -e "\n${CYAN}${BOLD}Installationsparameter konfigurieren:${RESET}"
    echo -e "${DIM}Drücken Sie einfach Enter, um die Standardwerte zu verwenden.${RESET}"
    
    # Domain-Name mit Validierung
    while true; do
        read -rp "Domain-Name oder IP-Adresse [$DOMAIN_NAME]: " user_domain
        if [[ -n "$user_domain" ]]; then
            # Prüfe, ob es ein gültiger Domainname oder eine IP ist
            if [[ "$user_domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]] || [[ "$user_domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                DOMAIN_NAME="$user_domain"
                break
            else
                log_error "Ungültiger Domain-Name oder IP-Adresse. Bitte erneut eingeben."
            fi
        else
            break
        fi
    done
    
    # HTTPS verwenden?
    if [[ "$USE_HTTPS" = true ]]; then
        read -rp "HTTPS verwenden? (J/n): " use_https
        if [[ "$use_https" =~ ^[nN]$ ]]; then
            USE_HTTPS=false
            log_info "HTTP-only-Modus aktiviert"
        fi
    else
        read -rp "HTTPS verwenden? (j/N): " use_https
        if [[ "$use_https" =~ ^[jJ]$ ]]; then
            USE_HTTPS=true
            log_info "HTTPS-Modus aktiviert"
            
            # Überprüfe, ob OpenSSL installiert ist, falls HTTPS gewählt wurde
            if ! command -v openssl &> /dev/null; then
                log_warning "OpenSSL ist für HTTPS erforderlich, aber nicht installiert."
                echo -e "Möchten Sie OpenSSL jetzt installieren? (J/n): "
                read -rp "> " install_openssl
                
                if [[ ! "$install_openssl" =~ ^[nN]$ ]]; then
                    install_openssl
                    
                    if ! command -v openssl &> /dev/null; then
                        log_error "OpenSSL konnte nicht installiert werden. Fallback auf HTTP-only."
                        USE_HTTPS=false
                    fi
                else
                    log_warning "HTTPS wurde deaktiviert, da OpenSSL nicht installiert ist."
                    USE_HTTPS=false
                fi
            fi
        fi
    fi
    
    # HTTP-Port mit Validierung
    while true; do
        read -rp "HTTP-Port [$HTTP_PORT]: " user_http_port
        if [[ -n "$user_http_port" ]]; then
            # Prüfe, ob es sich um eine gültige Portnummer handelt
            if [[ "$user_http_port" =~ ^[0-9]+$ ]] && [[ "$user_http_port" -ge 1 ]] && [[ "$user_http_port" -le 65535 ]]; then
                # Prüfe, ob der Port bereits belegt ist
                if check_port "$user_http_port"; then
                    HTTP_PORT="$user_http_port"
                    break
                else
                    log_warning "Port $user_http_port ist bereits belegt. Bitte wählen Sie einen anderen Port."
                fi
            else
                log_error "Ungültige Portnummer. Bitte geben Sie eine Zahl zwischen 1 und 65535 ein."
            fi
        else
            # Prüfe, ob der Standardport verfügbar ist
            if ! check_port "$HTTP_PORT"; then
                log_warning "Der Standardport $HTTP_PORT ist bereits belegt."
                # Suche nach einem freien Port
                for try_port in 8080 8000 8888 9000 3000; do
                    if check_port "$try_port"; then
                        log_info "Port $try_port ist verfügbar und wird verwendet."
                        HTTP_PORT="$try_port"
                        break
                    fi
                done
            fi
            break
        fi
    done
    
    # HTTPS-Port (nur wenn HTTPS aktiviert ist)
    if [[ "$USE_HTTPS" = true ]]; then
        while true; do
            read -rp "HTTPS-Port [$HTTPS_PORT]: " user_https_port
            if [[ -n "$user_https_port" ]]; then
                # Prüfe, ob es sich um eine gültige Portnummer handelt
                if [[ "$user_https_port" =~ ^[0-9]+$ ]] && [[ "$user_https_port" -ge 1 ]] && [[ "$user_https_port" -le 65535 ]]; then
                    # Stelle sicher, dass HTTP- und HTTPS-Ports unterschiedlich sind
                    if [[ "$user_https_port" = "$HTTP_PORT" ]]; then
                        log_error "HTTPS-Port und HTTP-Port dürfen nicht identisch sein."
                    elif check_port "$user_https_port"; then
                        HTTPS_PORT="$user_https_port"
                        break
                    else
                        log_warning "Port $user_https_port ist bereits belegt. Bitte wählen Sie einen anderen Port."
                    fi
                else
                    log_error "Ungültige Portnummer. Bitte geben Sie eine Zahl zwischen 1 und 65535 ein."
                fi
            else
                # Prüfe, ob der Standardport verfügbar ist
                if ! check_port "$HTTPS_PORT"; then
                    log_warning "Der Standardport $HTTPS_PORT ist bereits belegt."
                    # Suche nach einem freien Port
                    for try_port in 8443 4443 9443 10443; do
                        if check_port "$try_port"; then
                            log_info "Port $try_port ist verfügbar und wird verwendet."
                            HTTPS_PORT="$try_port"
                            break
                        fi
                    done
                fi
                break
            fi
        done
    fi
    
    # Frage nach erweiterten Optionen
    echo -e "\n${YELLOW}Möchten Sie erweiterte Installationsoptionen konfigurieren? (j/N)${RESET}"
    read -rp "> " advanced_choice
    
    if [[ "$advanced_choice" =~ ^[jJ]$ ]]; then
        configure_advanced_options
    fi
}

# Funktion zur Installation von OpenSSL
install_openssl() {
    log_info "OpenSSL wird installiert..."
    
    run_with_spinner "case $OS in
        ubuntu|debian)
            apt update && apt install -y openssl
            ;;
        centos|rhel|fedora)
            yum install -y openssl
            ;;
        alpine)
            apk add --no-cache openssl
            ;;
        *)
            exit 1
            ;;
    esac" "OpenSSL wird installiert"
}

# Funktion zur Konfiguration erweiterter Installationsoptionen (textbasiert)
configure_advanced_options() {
    print_header "Erweiterte Installationsoptionen"
    
    # Speicherbegrenzung für Docker-Container
    echo -e "Speicherbegrenzung für Container (leer für keine Begrenzung): "
    read -rp "> " memory_limit
    
    if [[ -n "$memory_limit" ]]; then
        log_info "Container-Speicherbegrenzung auf $memory_limit gesetzt."
        MEMORY_LIMIT="$memory_limit"
    fi
    
    # Datenbank-Passwort manuell festlegen
    echo -e "Benutzerdefiniertes Datenbank-Passwort (leer für automatisch generiertes Passwort): "
    read -rp "> " db_password
    
    if [[ -n "$db_password" ]]; then
        log_info "Benutzerdefiniertes Datenbank-Passwort festgelegt."
        DB_PASSWORD="$db_password"
    fi
    
    # Zeitzone konfigurieren
    echo -e "Zeitzone (Standard: UTC): "
    read -rp "> " timezone
    
    if [[ -n "$timezone" ]]; then
        log_info "Zeitzone auf $timezone gesetzt."
        TIMEZONE="$timezone"
    else
        TIMEZONE="UTC"
    fi
}

# Dialog-basierte Konfiguration erweiterter Installationsoptionen
configure_advanced_options_dialog() {
    local BACKTITLE="Kormit Management Tool v$KORMIT_MANAGER_VERSION"
    local TITLE="Erweiterte Installationsoptionen"
    
    # Speicherbegrenzung für Docker-Container
    local memory_limit=$(dialog --clear --backtitle "$BACKTITLE" \
                      --title "$TITLE" \
                      --inputbox "Speicherbegrenzung für Container\n(leer für keine Begrenzung, z.B. 1g, 512m):" \
                      10 60 \
                      2>&1 >/dev/tty)
    
    if [[ -n "$memory_limit" ]]; then
        MEMORY_LIMIT="$memory_limit"
    fi
    
    # Datenbank-Passwort manuell festlegen
    local db_password=$(dialog --clear --backtitle "$BACKTITLE" \
                      --title "$TITLE" \
                      --insecure --passwordbox "Benutzerdefiniertes Datenbank-Passwort\n(leer für automatisch generiertes Passwort):" \
                      10 60 \
                      2>&1 >/dev/tty)
    
    if [[ -n "$db_password" ]]; then
        DB_PASSWORD="$db_password"
    fi
    
    # Liste von gängigen Zeitzonen erstellen
    local TIMEZONES=(
        "UTC" "Koordinierte Weltzeit"
        "Europe/Berlin" "Deutschland"
        "Europe/Vienna" "Österreich"
        "Europe/Zurich" "Schweiz"
        "Europe/London" "Großbritannien"
        "Europe/Paris" "Frankreich"
        "America/New_York" "USA (Ostküste)"
        "America/Los_Angeles" "USA (Westküste)"
        "Australia/Sydney" "Australien (Sydney)"
        "Asia/Tokyo" "Japan"
    )
    
    # Zeitzone mit Menü auswählen
    local timezone=$(dialog --clear --backtitle "$BACKTITLE" \
                   --title "$TITLE" \
                   --menu "Wählen Sie eine Zeitzone:" \
                   15 60 10 \
                   "${TIMEZONES[@]}" \
                   2>&1 >/dev/tty)
    
    if [[ -n "$timezone" ]]; then
        TIMEZONE="$timezone"
    else
        TIMEZONE="UTC"
    fi
    
    # Zusammenfassung anzeigen
    local SUMMARY="Die folgenden erweiterten Einstellungen wurden konfiguriert:\n\n"
    
    if [[ -n "$MEMORY_LIMIT" ]]; then
        SUMMARY+="Container-Speicherbegrenzung: $MEMORY_LIMIT\n"
    else
        SUMMARY+="Container-Speicherbegrenzung: Keine\n"
    fi
    
    if [[ -n "$DB_PASSWORD" ]]; then
        SUMMARY+="Datenbank-Passwort: Benutzerdefiniert\n"
    else
        SUMMARY+="Datenbank-Passwort: Automatisch generiert\n"
    fi
    
    SUMMARY+="Zeitzone: $TIMEZONE"
    
    dialog --clear --backtitle "$BACKTITLE" \
           --title "Erweiterte Einstellungen" \
           --msgbox "$SUMMARY" \
           10 60
    
    clear
}

# Funktion zum Überprüfen, ob ein Port frei ist
check_port() {
    local port=$1
    
    # Verwende netstat oder ss, um zu prüfen, ob der Port bereits verwendet wird
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$port "; then
            return 1  # Port ist belegt
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$port "; then
            return 1  # Port ist belegt
        fi
    else
        # Wenn weder netstat noch ss verfügbar sind, versuche es mit einem temporären Socket
        if ! (echo > /dev/tcp/127.0.0.1/$port) 2>/dev/null; then
            # Socket konnte nicht geöffnet werden, also ist der Port wahrscheinlich frei
            return 0
        else
            # Socket konnte geöffnet werden, also ist der Port belegt
            return 1
        fi
    fi
    
    return 0  # Port ist frei
}

# Diagnosefunktion für Fehlersuche
run_diagnostics() {
    print_header "Fehlerdiagnose"
    
    log_info "Führe Systemdiagnose durch..."
    
    # Systeminfos ausgeben
    echo -e "\n${BOLD}Systeminformationen:${RESET}"
    run_with_spinner "uname -a > /tmp/kormit_diag_system.txt" "Systeminformationen werden gesammelt"
    
    # Docker-Status prüfen
    echo -e "\n${BOLD}Docker-Status:${RESET}"
    if docker info &> /dev/null; then
        log_success "Docker-Dienst läuft"
        run_with_spinner "docker info > /tmp/kormit_diag_docker.txt" "Docker-Informationen werden gesammelt"
    else
        log_error "Docker-Dienst läuft nicht"
    fi
    
    # Installationsverzeichnis prüfen
    echo -e "\n${BOLD}Installationsverzeichnis:${RESET}"
    if [[ -d "$INSTALL_DIR" ]]; then
        log_success "Installationsverzeichnis existiert: $INSTALL_DIR"
        run_with_spinner "ls -la $INSTALL_DIR > /tmp/kormit_diag_install_dir.txt" "Verzeichnisinhalt wird analysiert"
        
        # Prüfe, ob die Docker Compose-Datei existiert
        if [[ -f "$INSTALL_DIR/docker/production/docker-compose.yml" ]]; then
            log_success "Docker Compose-Konfiguration gefunden"
        else
            log_error "Docker Compose-Konfiguration nicht gefunden"
        fi
        
        # Prüfe, ob Nginx-Konfiguration existiert
        if [[ -f "$INSTALL_DIR/docker/production/nginx.conf" ]]; then
            log_success "Nginx-Konfiguration gefunden"
        else
            log_error "Nginx-Konfiguration nicht gefunden"
        fi
        
        # Prüfe, ob .env-Datei existiert
        if [[ -f "$INSTALL_DIR/docker/production/.env" ]]; then
            log_success ".env-Datei gefunden"
        else
            log_error ".env-Datei nicht gefunden"
        fi
    else
        log_error "Installationsverzeichnis existiert nicht: $INSTALL_DIR"
    fi
    
    # Netzwerkprüfung
    echo -e "\n${BOLD}Netzwerkdiagnose:${RESET}"
    run_with_spinner "ping -c 2 github.com > /tmp/kormit_diag_network.txt" "Netzwerkverbindung wird geprüft"
    
    # Portprüfung
    echo -e "\n${BOLD}Portprüfung:${RESET}"
    if check_port "$HTTP_PORT"; then
        log_success "HTTP-Port $HTTP_PORT ist verfügbar"
    else
        log_warning "HTTP-Port $HTTP_PORT ist bereits belegt"
        run_with_spinner "netstat -tuln | grep $HTTP_PORT > /tmp/kormit_diag_port_http.txt" "Port-Belegung wird analysiert"
    fi
    
    if [[ "$USE_HTTPS" = true ]] && ! check_port "$HTTPS_PORT"; then
        log_warning "HTTPS-Port $HTTPS_PORT ist bereits belegt"
        run_with_spinner "netstat -tuln | grep $HTTPS_PORT > /tmp/kormit_diag_port_https.txt" "Port-Belegung wird analysiert"
    fi
    
    # Sammle alle Diagnosedateien in eine Zip-Datei
    if command -v zip &> /dev/null; then
        run_with_spinner "zip -j /tmp/kormit_diagnostics.zip /tmp/kormit_diag_*.txt" "Diagnose-Informationen werden gesammelt"
        log_success "Diagnose-Informationen wurden in /tmp/kormit_diagnostics.zip gespeichert"
    else
        log_success "Diagnose-Informationen wurden in /tmp/ gespeichert (kormit_diag_*.txt)"
    fi
    
    # Tipps zur Fehlerbehebung
    echo -e "\n${BOLD}Mögliche Lösungen:${RESET}"
    echo -e "1. Stellen Sie sicher, dass Docker aktiv ist: ${CYAN}systemctl start docker${RESET}"
    echo -e "2. Prüfen Sie, ob die Ports frei sind: ${CYAN}netstat -tuln | grep $HTTP_PORT${RESET}"
    echo -e "3. Überprüfen Sie den Speicherplatz: ${CYAN}df -h${RESET}"
    echo -e "4. Versuchen Sie die Reparaturoptionen: ${CYAN}sudo $0${RESET} → Option ${CYAN}9${RESET}"
    echo -e "5. Bei anhaltenden Problemen: Besuchen Sie ${CYAN}https://github.com/kormit-panel/kormit/issues${RESET}"
}

# Funktionen für Kormit-Management
start_kormit() {
    print_header "Kormit wird gestartet"
    
    if [[ -f "$INSTALL_DIR/start.sh" ]]; then
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
    
    if [[ -f "$INSTALL_DIR/stop.sh" ]]; then
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
    
    if [[ -f "$INSTALL_DIR/update.sh" ]]; then
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
    
    if [[ -d "$INSTALL_DIR/docker/production" ]]; then
        cd "$INSTALL_DIR/docker/production" || { 
            log_error "Konnte nicht in das Verzeichnis $INSTALL_DIR/docker/production wechseln";
            return 1;
        }
        
        # Prüfen, ob docker-compose oder docker compose verfügbar ist
        if command -v docker-compose &> /dev/null; then
            docker-compose logs | less
        elif docker compose version &> /dev/null; then
            docker compose logs | less
        else
            log_error "Weder docker-compose noch docker compose Plugin sind verfügbar."
            log_info "Bitte installieren Sie Docker Compose und versuchen Sie es erneut."
        fi
    else
        log_error "Kormit-Verzeichnis konnte nicht gefunden werden: $INSTALL_DIR/docker/production"
        log_info "Ist Kormit installiert? Versuchen Sie zuerst 'Kormit installieren'."
    fi
}

check_status() {
    print_header "Kormit Status"
    
    if [[ -d "$INSTALL_DIR/docker/production" ]]; then
        cd "$INSTALL_DIR/docker/production" || { 
            log_error "Konnte nicht in das Verzeichnis $INSTALL_DIR/docker/production wechseln";
            return 1;
        }
        
        # Prüfen, ob docker-compose oder docker compose verfügbar ist
        if command -v docker-compose &> /dev/null; then
            docker-compose ps
        elif docker compose version &> /dev/null; then
            docker compose ps
        else
            log_error "Weder docker-compose noch docker compose Plugin sind verfügbar."
            log_info "Bitte installieren Sie Docker Compose und versuchen Sie es erneut."
        fi
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
#!/usr/bin/env bash
cd "$(dirname "$0")/docker/production" || { echo "Konnte nicht ins Verzeichnis wechseln"; exit 1; }
docker compose up -d
echo "Kormit wurde gestartet und ist erreichbar."
EOL
    chmod +x "$INSTALL_DIR/start.sh"
    
    log_info "Stop-Skript wird repariert..."
    cat > "$INSTALL_DIR/stop.sh" <<'EOL'
#!/usr/bin/env bash
cd "$(dirname "$0")/docker/production" || { echo "Konnte nicht ins Verzeichnis wechseln"; exit 1; }
docker compose down
echo "Kormit wurde gestoppt."
EOL
    chmod +x "$INSTALL_DIR/stop.sh"
    
    log_info "Update-Skript wird repariert..."
    cat > "$INSTALL_DIR/update.sh" <<'EOL'
#!/usr/bin/env bash
cd "$(dirname "$0")/docker/production" || { echo "Konnte nicht ins Verzeichnis wechseln"; exit 1; }
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
    
    if [[ -f "$ENV_FILE" ]]; then
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
        read -rp "Möchten Sie die Container mit den korrekten Images neu starten? (J/n): " restart
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
    
    if [[ -f "$ENV_FILE" ]]; then
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
    read -rp "Möchten Sie die Container mit den korrekten Images neu starten? (J/n): " restart
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
    
    read -rp "Option (0-4): " repair_option
    
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
    read -rp "> " repair
    if [[ "$repair" =~ ^[jJ]$ ]]; then
        repair_installation
    fi
}

# Neue Reparaturfunktion für SSL-Probleme
fix_nginx_ssl() {
    print_header "Nginx SSL-Konfiguration wird repariert"
    
    # Stelle sicher, dass das SSL-Verzeichnis existiert
    mkdir -p "$INSTALL_DIR/docker/production/ssl"
    
    # Überprüfen, ob SSL-Zertifikate vorhanden sind
    if [[ ! -s "$INSTALL_DIR/docker/production/ssl/kormit.crt" ]] || [[ ! -s "$INSTALL_DIR/docker/production/ssl/kormit.key" ]]; then
        log_warning "SSL-Zertifikate fehlen oder sind leer."
        
        # Frage, ob HTTP-only-Modus verwendet werden soll
        echo -e "${YELLOW}Möchten Sie den HTTP-only-Modus verwenden (empfohlen für Entwicklung)? [J/n]${RESET}"
        read -rp "> " use_http_only
        
        if [[ "$use_http_only" =~ ^[Nn]$ ]]; then
            # Erstelle selbstsignierte Zertifikate für HTTPS
            log_info "Erstelle selbstsignierte SSL-Zertifikate..."
            
            # Stelle sicher, dass OpenSSL installiert ist
            if ! command -v openssl &> /dev/null; then
                log_error "OpenSSL ist nicht installiert. Bitte installieren Sie es und versuchen Sie es erneut."
                return 1
            fi
            
            # Erstelle die Zertifikate
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout "$INSTALL_DIR/docker/production/ssl/kormit.key" \
                -out "$INSTALL_DIR/docker/production/ssl/kormit.crt" \
                -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"
            
            log_success "Selbstsignierte SSL-Zertifikate wurden erstellt."
        else
            # Konfiguriere für HTTP-only und erstelle leere Zertifikatsdateien
            log_info "Konfiguriere für HTTP-only-Modus..."
            
            # Erstelle leere Zertifikatsdateien
            touch "$INSTALL_DIR/docker/production/ssl/kormit.key"
            touch "$INSTALL_DIR/docker/production/ssl/kormit.crt"
            
            # Passe die Nginx-Konfiguration an (entferne HTTPS)
            log_info "Passe Nginx-Konfiguration an..."
            
            # Sicherungskopie erstellen
            cp "$INSTALL_DIR/docker/production/nginx.conf" "$INSTALL_DIR/docker/production/nginx.conf.bak"
            
            # Erzeuge eine neue Konfiguration ohne HTTPS
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
            
            # Entferne den HTTPS-Port aus der docker-compose.yml
            sed -i 's/- "${HTTPS_PORT:-443}:443"/#- "${HTTPS_PORT:-443}:443"/' "$INSTALL_DIR/docker/production/docker-compose.yml"
            
            log_success "Nginx wurde auf HTTP-only konfiguriert."
        fi
    else
        log_success "SSL-Zertifikate sind vorhanden."
    fi
    
    log_success "Nginx-Konfiguration wurde repariert."
}

# Hilfsfunktion für die Statusanzeige im Menü
is_enabled() {
    local status="$1"
    if [[ "$status" = true ]]; then
        echo -e "${GREEN}Aktiviert${RESET}"
    else
        echo -e "${DIM}Deaktiviert${RESET}"
    fi
}

# Verbesserte Tastatureingabe für Menüs
read_menu_choice() {
    echo -e "\nWählen Sie eine Option [0-9, d, a, u, p]:"
    read -rp "> " choice
    echo "$choice"
}

# Interaktives Menü
show_menu() {
    clear
    print_logo
    
    # Prüfen, ob Updates verfügbar sind, falls aktiviert
    if [[ "$AUTO_UPDATE_CHECK" = true ]]; then
        check_for_updates
    fi
    
    # Status der Kormit-Installation prüfen
    local is_installed=false
    local is_running=false
    
    if [[ -d "$INSTALL_DIR/docker/production" ]]; then
        is_installed=true
        
        # Überprüfe, ob Kormit läuft
        if [[ -f "$INSTALL_DIR/docker/production/.env" ]] && docker ps | grep -q "kormit-proxy"; then
            is_running=true
        fi
    fi
    
    # Systeminfo anzeigen
    KERNEL_VERSION=$(uname -r)
    echo -e "\n${CYAN}${BOLD}⚙️ SYSTEM:${RESET}"
    
    if [[ "$OS_ENV" = "WSL" ]]; then
        echo -e "  ${CYAN}${BOLD}●${RESET} Betriebssystem: ${GREEN}Windows (WSL) - $KERNEL_VERSION${RESET}"
    elif [[ "$OS_ENV" = "MacOS" ]]; then
        echo -e "  ${CYAN}${BOLD}●${RESET} Betriebssystem: ${GREEN}macOS $(sw_vers -productVersion)${RESET}"
    else
        echo -e "  ${CYAN}${BOLD}●${RESET} Betriebssystem: ${GREEN}Linux $KERNEL_VERSION${RESET}"
    fi
    
    # Statusanzeige
    echo -e "\n${CYAN}${BOLD}📡 STATUS:${RESET}"
    if [[ "$is_installed" = true ]]; then
        if [[ "$is_running" = true ]]; then
            echo -e "  ${GREEN}${BOLD}●${RESET} Kormit ist ${GREEN}aktiv${RESET} und läuft auf ${CYAN}${DOMAIN_NAME}:${HTTP_PORT}${RESET}"
        else
            echo -e "  ${YELLOW}${BOLD}●${RESET} Kormit ist ${YELLOW}installiert${RESET}, aber derzeit ${DIM}nicht aktiv${RESET}"
        fi
    else
        echo -e "  ${RED}${BOLD}●${RESET} Kormit ist ${RED}nicht installiert${RESET}"
    fi
    
    # Hauptmenü
    echo -e "\n${CYAN}${BOLD}🔷 HAUPTMENÜ${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${RESET}"
    
    # Setup-Bereich
    echo -e "${BOLD}🔧 Setup:${RESET}"
    echo -e " ${GREEN}1${RESET}) ${BOLD}Abhängigkeiten prüfen${RESET} - Docker, Git, etc."
    echo -e " ${GREEN}2${RESET}) ${BOLD}Repository klonen/aktualisieren${RESET} - Neueste Code-Version holen"
    echo -e " ${GREEN}3${RESET}) ${BOLD}Kormit installieren${RESET} - Neue Installation durchführen"
    
    # Trennlinie
    echo -e "${CYAN}──────────────────────────────────────────────────────────${RESET}"
    
    # Service-Bereich mit Status-Symbolen
    echo -e "${BOLD}🚀 Verwaltung:${RESET}"
    if [[ "$is_running" = true ]]; then
        echo -e " ${GREEN}4${RESET}) ${BOLD}Kormit ${RED}stoppen${RESET} - Dienst anhalten"
    else
        echo -e " ${GREEN}4${RESET}) ${BOLD}Kormit ${GREEN}starten${RESET} - Dienst starten"
    fi
    echo -e " ${GREEN}5${RESET}) ${BOLD}Kormit neustarten${RESET} - Dienst neu starten"
    echo -e " ${GREEN}6${RESET}) ${BOLD}Kormit aktualisieren${RESET} - Auf neue Version aktualisieren"
    
    # Trennlinie
    echo -e "${CYAN}──────────────────────────────────────────────────────────${RESET}"
    
    # Monitoring- und Wartungsbereich
    echo -e "${BOLD}📊 Monitoring & Wartung:${RESET}"
    echo -e " ${GREEN}7${RESET}) ${BOLD}Logs anzeigen${RESET} - Container-Logs einsehen"
    echo -e " ${GREEN}8${RESET}) ${BOLD}Status anzeigen${RESET} - Aktuellen Dienststatus prüfen"
    echo -e " ${GREEN}9${RESET}) ${BOLD}Installation reparieren${RESET} - Erweiterte Reparaturfunktionen"
    
    # Trennlinie
    echo -e "${CYAN}──────────────────────────────────────────────────────────${RESET}"
    
    # Weitere Optionen
    echo -e "${BOLD}⚙️ Weitere Optionen:${RESET}"
    echo -e " ${GREEN}d${RESET}) ${BOLD}Debug-Modus${RESET} - $(is_enabled "$DEBUG")"
    echo -e " ${GREEN}a${RESET}) ${BOLD}Animationen${RESET} - $(is_enabled "$ANIMATION_ENABLED")"
    echo -e " ${GREEN}u${RESET}) ${BOLD}Auto-Update-Check${RESET} - $(is_enabled "$AUTO_UPDATE_CHECK")"
    echo -e " ${GREEN}p${RESET}) ${BOLD}Installationspfad ändern${RESET} - (aktuell: ${CYAN}$INSTALL_DIR${RESET})"
    
    # Trennlinie
    echo -e "${CYAN}──────────────────────────────────────────────────────────${RESET}"
    echo -e " ${RED}0${RESET}) ${RED}${BOLD}Beenden${RESET} - Programm beenden"
    
    # Schnellzugriff für laufende Instanz
    if [[ "$is_running" = true ]]; then
        echo -e "\n${BOLD}🌐 Schnellzugriff:${RESET} ${UNDERLINE}http://${DOMAIN_NAME}:${HTTP_PORT}${RESET}"
    fi
    
    # Fußzeile
    if [[ "$OS_ENV" = "WSL" ]]; then
        VERSION_INFO="${KORMIT_MANAGER_VERSION} (Windows/WSL)"
    elif [[ "$OS_ENV" = "MacOS" ]]; then
        VERSION_INFO="${KORMIT_MANAGER_VERSION} (macOS)"
    else
        VERSION_INFO="${KORMIT_MANAGER_VERSION} (Linux)"
    fi
    echo -e "\n${DIM}Kormit Control Center ${VERSION_INFO} | $(date '+%d.%m.%Y %H:%M')${RESET}"
    
    # Eingabeaufforderung 
    echo -e "\nWählen Sie eine Option [0-9, d, a, u, p]:"
    read -rp "> " choice
    
    case "$choice" in
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
            if [[ "$is_running" = true ]]; then
                stop_kormit
            else
                start_kormit
            fi
            press_enter_to_continue
            ;;
        5)
            restart_kormit
            press_enter_to_continue
            ;;
        6)
            update_kormit
            press_enter_to_continue
            ;;
        7)
            show_logs
            # Nach less brauchen wir keinen press_enter
            ;;
        8)
            check_status
            press_enter_to_continue
            ;;
        9)
            repair_menu
            # Das Reparaturmenü hat seine eigene Navigation
            ;;
        d|D)
            toggle_debug
            ;;
        a|A)
            toggle_animations
            ;;
        u|U)
            toggle_auto_update
            ;;
        p|P)
            change_install_path
            ;;
        0)
            clear
            echo -e "${GREEN}${BOLD}"
            echo "╔════════════════════════════════════════════════════════════════╗"
            echo "║                                                                ║"
            echo "║   Vielen Dank für die Nutzung des Kormit Control Centers!      ║"
            echo "║                                                                ║"
            echo "║   Besuchen Sie uns unter: https://github.com/kormit-panel      ║"
            echo "║                                                                ║"
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo -e "${RESET}"
            sleep 1
            exit 0
            ;;
        *)
            log_error "Ungültige Option. Bitte wählen Sie eine gültige Option [0-9, d, a, u, p]."
            press_enter_to_continue
            ;;
    esac
    
    # Zurück zum Hauptmenü
    show_menu
}

# Helper function to pause execution until user presses Enter
press_enter_to_continue() {
    echo -e "\n${YELLOW}Drücken Sie Enter, um fortzufahren...${RESET}"
    read -r
}

# Verbesserte Reparaturmenüfunktion
repair_menu() {
    clear
    print_header "Reparatur & Wartung"
    
    echo -e "${BOLD}Wählen Sie eine Option:${RESET}"
    echo -e " ${GREEN}1${RESET}) ${BOLD}Komplettüberprüfung${RESET} - Vollständige Systemdiagnose"
    echo -e " ${GREEN}2${RESET}) ${BOLD}Management-Skripte reparieren${RESET} - Start-, Stop- und Update-Skripte"
    echo -e " ${GREEN}3${RESET}) ${BOLD}Image-Tags korrigieren${RESET} - Manifest-unknown-Fehler beheben"
    echo -e " ${GREEN}4${RESET}) ${BOLD}Container neustarten${RESET} - Alle Container neu starten"
    echo -e " ${GREEN}5${RESET}) ${BOLD}Container-Images aktualisieren${RESET} - Neueste Images beziehen"
    echo -e " ${GREEN}6${RESET}) ${BOLD}Nginx-Konfiguration reparieren${RESET} - SSL/HTTP-Probleme beheben"
    echo -e " ${GREEN}7${RESET}) ${BOLD}Datenbank sichern${RESET} - Backup der Kormit-Datenbank erstellen"
    echo -e " ${GREEN}8${RESET}) ${BOLD}Neuinstallation vorbereiten${RESET} - Alle Daten löschen"
    echo -e " ${RED}0${RESET}) ${BOLD}Zurück${RESET} - Zum Hauptmenü zurückkehren"
    
    echo -e "\nWählen Sie eine Option [0-8]:"
    read -rp "> " repair_option
    
    case $repair_option in
        1)
            run_diagnostics
            press_enter_to_continue
            ;;
        2)
            repair_scripts
            press_enter_to_continue
            ;;
        3)
            fix_image_tags
            press_enter_to_continue
            ;;
        4)
            restart_kormit
            press_enter_to_continue
            ;;
        5)
            pull_images
            press_enter_to_continue
            ;;
        6)
            fix_nginx_ssl
            press_enter_to_continue
            ;;
        7)
            backup_database
            press_enter_to_continue
            ;;
        8)
            prepare_reinstall
            press_enter_to_continue
            ;;
        0)
            # Zurück zum Hauptmenü
            return
            ;;
        *)
            log_error "Ungültige Option. Bitte wählen Sie eine Option zwischen 0 und 8."
            press_enter_to_continue
            ;;
    esac
    
    # Zurück zum Reparaturmenü
    repair_menu
}

# Toggle-Funktionen für Menüoptionen
toggle_debug() {
    if [[ "$DEBUG" = true ]]; then
        DEBUG=false
        log_info "Debug-Modus wurde deaktiviert."
    else
        DEBUG=true
        log_info "Debug-Modus wurde aktiviert."
    fi
    save_config
    press_enter_to_continue
}

toggle_animations() {
    if [[ "$ANIMATION_ENABLED" = true ]]; then
        ANIMATION_ENABLED=false
        log_info "Animationen wurden deaktiviert."
    else
        ANIMATION_ENABLED=true
        log_info "Animationen wurden aktiviert."
    fi
    save_config
    press_enter_to_continue
}

toggle_auto_update() {
    if [[ "$AUTO_UPDATE_CHECK" = true ]]; then
        AUTO_UPDATE_CHECK=false
        log_info "Auto-Update-Check wurde deaktiviert."
    else
        AUTO_UPDATE_CHECK=true
        log_info "Auto-Update-Check wurde aktiviert."
    fi
    save_config
    press_enter_to_continue
}

change_install_path() {
    echo -e "Aktuelles Installationsverzeichnis: ${BOLD}$INSTALL_DIR${RESET}"
    echo -e "Geben Sie ein neues Installationsverzeichnis ein (oder [Enter] für keine Änderung):"
    read -rp "> " new_dir
    
    if [[ -n "$new_dir" ]]; then
        INSTALL_DIR="$new_dir"
        log_success "Installationsverzeichnis geändert auf: ${BOLD}$INSTALL_DIR${RESET}"
        save_config
    fi
    press_enter_to_continue
}

# Unterstützung für Datenbank-Backups
backup_database() {
    print_header "Datenbank-Backup"
   
    # Prüfen, ob Kormit installiert ist
    if [[ ! -d "$INSTALL_DIR/docker/production" ]]; then
        log_error "Kormit scheint nicht installiert zu sein. Nichts zu sichern."
        return 1
    fi
   
    # Backup-Verzeichnis erstellen
    BACKUP_DIR="$INSTALL_DIR/backups"
    mkdir -p "$BACKUP_DIR"
   
    # Aktuelles Datum für den Dateinamen
    BACKUP_DATE=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_FILE="$BACKUP_DIR/kormit_db_$BACKUP_DATE.sql"
   
    log_info "Erstelle Backup der Kormit-Datenbank..."
   
    # Prüfen, ob der Container läuft
    if ! docker ps | grep -q "kormit-db"; then
        log_warning "Datenbank-Container läuft nicht. Starte Container für das Backup..."
        cd "$INSTALL_DIR/docker/production" || {
            log_error "Konnte nicht in das Verzeichnis $INSTALL_DIR/docker/production wechseln";
            return 1;
        }
       
        # Prüfen, ob docker-compose oder docker compose verfügbar ist
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d kormit-db
        elif docker compose version &> /dev/null; then
            docker compose up -d kormit-db
        else
            log_error "Weder docker-compose noch docker compose Plugin sind verfügbar."
            return 1
        fi
       
        # Warte, bis der Container bereit ist
        sleep 10
    fi
   
    # Database Dump durchführen
    cd "$INSTALL_DIR/docker/production" || {
        log_error "Konnte nicht in das Verzeichnis $INSTALL_DIR/docker/production wechseln";
        return 1;
    }
   
    if run_with_spinner "
        export PGPASSWORD=\$(grep DB_PASSWORD .env | cut -d'=' -f2)
        docker exec kormit-db pg_dump -U \$(grep DB_USER .env | cut -d'=' -f2) \$(grep DB_NAME .env | cut -d'=' -f2) > \"$BACKUP_FILE\"
    " "Datenbank wird gesichert"; then
        log_success "Datenbank wurde erfolgreich gesichert: $BACKUP_FILE"
       
        # Komprimiere die Backup-Datei
        if command -v gzip &> /dev/null; then
            run_with_spinner "gzip -f \"$BACKUP_FILE\"" "Backup wird komprimiert"
            log_success "Backup wurde komprimiert: ${BACKUP_FILE}.gz"
            BACKUP_FILE="${BACKUP_FILE}.gz"
        fi
    else
        log_error "Fehler beim Sichern der Datenbank."
        return 1
    fi
   
    # Größe des Backups anzeigen
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_info "Backup-Größe: $BACKUP_SIZE"
   
    return 0
}

# Funktion zur Vorbereitung einer Neuinstallation
prepare_reinstall() {
    print_header "Neuinstallation vorbereiten"
    
    echo -e "${RED}${BOLD}ACHTUNG! Diese Funktion wird alle Kormit-Daten löschen!${RESET}"
    echo -e "${RED}Alle Container, Images, Volumes und Konfigurationsdaten werden entfernt.${RESET}"
    echo -e "${RED}Diese Aktion kann nicht rückgängig gemacht werden!${RESET}"
    
    echo -e "\n${YELLOW}${BOLD}Möchten Sie wirklich fortfahren? (j/N)${RESET}"
    read -rp "> " confirm
    
    if [[ ! "$confirm" =~ ^[jJ]$ ]]; then
        log_warning "Aktion abgebrochen."
        return 1
    fi
    
    # Zweite Bestätigung für zusätzliche Sicherheit
    echo -e "\n${RED}${BOLD}Dies ist Ihre letzte Chance abzubrechen.${RESET}"
    echo -e "${RED}Bitte geben Sie 'LÖSCHEN' ein, um zu bestätigen:${RESET}"
    read -rp "> " confirm_text
    
    if [[ "$confirm_text" != "LÖSCHEN" ]]; then
        log_warning "Aktion abgebrochen."
        return 1
    fi
    
    log_info "Beginne mit der Bereinigung..."
    
    # 1. Container stoppen und entfernen
    log_info "Stoppe und entferne Container..."
    if [[ -d "$INSTALL_DIR/docker/production" ]]; then
        cd "$INSTALL_DIR/docker/production" || {
            log_error "Konnte nicht in das Verzeichnis $INSTALL_DIR/docker/production wechseln";
            return 1;
        }
        
        if [[ -f "docker-compose.yml" ]]; then
            run_with_spinner "docker compose down -v --remove-orphans" "Container werden gestoppt und entfernt"
        fi
    fi
    
    # 2. Docker-Ressourcen bereinigen
    log_info "Bereinige Docker-Ressourcen..."
    
    # Volumes mit kormit im Namen entfernen
    run_with_spinner "docker volume ls --filter name=kormit -q | xargs -r docker volume rm" "Volumes werden entfernt"
    
    # Netzwerke mit kormit im Namen entfernen
    run_with_spinner "docker network ls --filter name=kormit -q | xargs -r docker network rm" "Netzwerke werden entfernt"
    
    # Images entfernen
    log_info "Möchten Sie auch die Docker-Images entfernen? (j/N)"
    read -rp "> " remove_images
    if [[ "$remove_images" =~ ^[jJ]$ ]]; then
        run_with_spinner "docker images | grep -E 'kormit|ghcr.io/kormit-panel' | awk '{print \$3}' | xargs -r docker rmi -f" "Images werden entfernt"
    fi
    
    # 3. Installationsverzeichnis bereinigen
    log_info "Bereinige Installationsverzeichnis..."
    
    # Sichere Konfigurationsdateien, falls gewünscht
    log_info "Möchten Sie die Konfigurationsdateien sichern? (J/n)"
    read -rp "> " backup_config
    if [[ ! "$backup_config" =~ ^[nN]$ ]]; then
        BACKUP_DIR="$HOME/kormit-backup-$(date +%Y%m%d%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        if [[ -f "$INSTALL_DIR/docker/production/.env" ]]; then
            cp "$INSTALL_DIR/docker/production/.env" "$BACKUP_DIR/"
            log_success "Konfiguration gesichert in: $BACKUP_DIR"
        fi
    fi
    
    # Lösche das Installationsverzeichnis
    run_with_spinner "rm -rf $INSTALL_DIR/*" "Installationsverzeichnis wird bereinigt"
    
    log_success "Neuinstallation vorbereitet."
    log_info "Sie können jetzt Kormit neu installieren mit der Option '3) Kormit installieren'."
    
    return 0
}

# Dialog-basiertes Menü, falls Dialog installiert ist
show_dialog_menu() {
    local HEIGHT=20
    local WIDTH=70
    local CHOICE_HEIGHT=13
    local BACKTITLE="Kormit Management Tool v$KORMIT_MANAGER_VERSION"
    local TITLE="Hauptmenü"
    local MENU="Wählen Sie eine Option:"
    local OPTIONS=(
        1 "Abhängigkeiten prüfen - Docker, Git, etc."
        2 "Repository klonen/aktualisieren - Neueste Code-Version holen"
        3 "Kormit installieren - Neue Installation durchführen"
        4 "Kormit starten/stoppen - Dienst verwalten"
        5 "Kormit neustarten - Dienst neu starten"
        6 "Kormit aktualisieren - Auf neue Version aktualisieren"
        7 "Logs anzeigen - Container-Logs einsehen"
        8 "Status anzeigen - Aktuellen Dienststatus prüfen"
        9 "Installation reparieren - Erweiterte Reparaturfunktionen"
        d "Debug-Modus umschalten - Aktueller Status: $(is_enabled "$DEBUG")"
        a "Animationen umschalten - Aktueller Status: $(is_enabled "$ANIMATION_ENABLED")"
        u "Auto-Update-Check umschalten - Aktueller Status: $(is_enabled "$AUTO_UPDATE_CHECK")"
        p "Installationspfad ändern - (aktuell: $INSTALL_DIR)"
        0 "Beenden - Programm beenden"
    )
    
    local CHOICE=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)
    
    clear  # Dialog-Ausgabe löschen
    
    case $CHOICE in
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
            local is_running=false
            if [[ -d "$INSTALL_DIR/docker/production" ]] && [[ -f "$INSTALL_DIR/docker/production/.env" ]] && docker ps | grep -q "kormit-proxy"; then
                is_running=true
                stop_kormit
            else
                start_kormit
            fi
            press_enter_to_continue
            ;;
        5)
            restart_kormit
            press_enter_to_continue
            ;;
        6)
            update_kormit
            press_enter_to_continue
            ;;
        7)
            show_logs
            ;;
        8)
            check_status
            press_enter_to_continue
            ;;
        9)
            show_dialog_repair_menu
            ;;
        d)
            toggle_debug
            ;;
        a)
            toggle_animations
            ;;
        u)
            toggle_auto_update
            ;;
        p)
            # Installationspfad-Dialog anzeigen
            local NEW_DIR=$(dialog --clear --backtitle "$BACKTITLE" \
                           --title "Installationspfad ändern" \
                           --inputbox "Aktueller Pfad: $INSTALL_DIR\n\nNeuer Pfad:" \
                           10 60 "$INSTALL_DIR" \
                           2>&1 >/dev/tty)
            
            if [[ -n "$NEW_DIR" ]]; then
                INSTALL_DIR="$NEW_DIR"
                log_success "Installationsverzeichnis geändert auf: ${BOLD}$INSTALL_DIR${RESET}"
                save_config
            fi
            ;;
        0)
            clear
            echo -e "${GREEN}${BOLD}"
            echo "╔════════════════════════════════════════════════════════════════╗"
            echo "║                                                                ║"
            echo "║   Vielen Dank für die Nutzung des Kormit Control Centers!      ║"
            echo "║                                                                ║"
            echo "║   Besuchen Sie uns unter: https://github.com/kormit-panel      ║"
            echo "║                                                                ║"
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo -e "${RESET}"
            sleep 1
            exit 0
            ;;
        *)
            # Bei Abbruch oder unerwarteter Eingabe (z.B. ESC-Taste)
            exit 0
            ;;
    esac
    
    # Zurück zum Menü
    show_dialog_menu
}

# Dialog-basiertes Reparaturmenü
show_dialog_repair_menu() {
    local HEIGHT=20
    local WIDTH=70
    local CHOICE_HEIGHT=9
    local BACKTITLE="Kormit Management Tool v$KORMIT_MANAGER_VERSION"
    local TITLE="Reparatur & Wartung"
    local MENU="Wählen Sie eine Option:"
    local OPTIONS=(
        1 "Komplettüberprüfung - Vollständige Systemdiagnose"
        2 "Management-Skripte reparieren - Start-, Stop- und Update-Skripte"
        3 "Image-Tags korrigieren - Manifest-unknown-Fehler beheben"
        4 "Container neustarten - Alle Container neu starten"
        5 "Container-Images aktualisieren - Neueste Images beziehen"
        6 "Nginx-Konfiguration reparieren - SSL/HTTP-Probleme beheben"
        7 "Datenbank sichern - Backup der Kormit-Datenbank erstellen"
        8 "Neuinstallation vorbereiten - Alle Daten löschen"
        0 "Zurück - Zum Hauptmenü zurückkehren"
    )
    
    local CHOICE=$(dialog --clear \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)
    
    clear  # Dialog-Ausgabe löschen
    
    case $CHOICE in
        1)
            run_diagnostics
            press_enter_to_continue
            ;;
        2)
            repair_scripts
            press_enter_to_continue
            ;;
        3)
            fix_image_tags
            press_enter_to_continue
            ;;
        4)
            restart_kormit
            press_enter_to_continue
            ;;
        5)
            pull_images
            press_enter_to_continue
            ;;
        6)
            fix_nginx_ssl
            press_enter_to_continue
            ;;
        7)
            backup_database
            press_enter_to_continue
            ;;
        8)
            prepare_reinstall
            press_enter_to_continue
            ;;
        0|"")
            # Zurück zum Hauptmenü
            return
            ;;
    esac
    
    # Zurück zum Reparaturmenü
    show_dialog_repair_menu
}

# Hauptfunktion
main() {
    # Lade gespeicherte Konfiguration
    load_config
    
    # Root-Rechte prüfen
    check_root
    
    # Betriebssystem erkennen
    detect_os
    
    # Prüfen, ob Updates verfügbar sind, falls aktiviert
    if [[ "$AUTO_UPDATE_CHECK" = true ]]; then
        check_for_updates
    fi
    
    # Prüfen, ob Dialog verfügbar ist
    if command -v dialog &> /dev/null; then
        # Dialog-basiertes Menü anzeigen
        show_dialog_menu
    else
        # Textbasiertes Menü anzeigen
        show_menu
    fi
}

# Skript starten
main "$@"