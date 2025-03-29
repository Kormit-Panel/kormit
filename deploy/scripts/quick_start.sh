#!/bin/bash
# Kormit Schnellstart-Skript für Linux

# Basis-URL zum Kormit-Repository
REPO_URL="https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy"

# Farbige Ausgaben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funktion für die farbige Ausgabe
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

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 KORMIT SCHNELLSTART                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Prüfen, ob Kormit installiert ist
if [ ! -d "/opt/kormit" ] && [ ! -d "$HOME/kormit" ] && [ ! -d "/var/kormit" ]; then
    log_warning "Kormit scheint nicht installiert zu sein."
    log_info "Möchten Sie Kormit jetzt installieren? (j/N)"
    read -r install_now
    
    if [[ "$install_now" =~ ^[jJ]$ ]]; then
        log_info "Starte den Installer..."
        curl -sSL "${REPO_URL}/scripts/install_curl.sh" | bash
        exit 0
    else
        log_error "Installation abgebrochen."
        exit 1
    fi
fi

# Finde das Kormit-Installationsverzeichnis
if [ -d "/opt/kormit" ]; then
    INSTALL_DIR="/opt/kormit"
elif [ -d "$HOME/kormit" ]; then
    INSTALL_DIR="$HOME/kormit"
elif [ -d "/var/kormit" ]; then
    INSTALL_DIR="/var/kormit"
else
    log_info "Bitte geben Sie den Pfad zu Ihrem Kormit-Installationsverzeichnis ein:"
    read -r INSTALL_DIR
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log_error "Das angegebene Verzeichnis existiert nicht: $INSTALL_DIR"
        exit 1
    fi
fi

# Menü anzeigen
echo -e "${BLUE}Kormit-Verwaltung${NC}"
echo "1) Kormit starten"
echo "2) Kormit stoppen"
echo "3) Kormit aktualisieren"
echo "4) Status anzeigen"
echo "5) Beenden"

read -p "Wählen Sie eine Option (1-5): " option

case $option in
    1)
        log_info "Kormit wird gestartet..."
        bash "$INSTALL_DIR/start.sh"
        log_success "Kormit wurde gestartet."
        ;;
    2)
        log_info "Kormit wird gestoppt..."
        bash "$INSTALL_DIR/stop.sh"
        log_success "Kormit wurde gestoppt."
        ;;
    3)
        log_info "Kormit wird aktualisiert..."
        bash "$INSTALL_DIR/update.sh"
        log_success "Kormit wurde aktualisiert."
        ;;
    4)
        log_info "Kormit-Status wird angezeigt..."
        cd "$INSTALL_DIR/docker/production" || exit 1
        docker compose ps
        ;;
    5)
        log_info "Auf Wiedersehen!"
        exit 0
        ;;
    *)
        log_error "Ungültige Option."
        exit 1
        ;;
esac 