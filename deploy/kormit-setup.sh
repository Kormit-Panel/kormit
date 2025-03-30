#!/bin/bash
# Kormit Installer Setup Script
# This script downloads and runs the Kormit Management Script
# Version 1.0.0

# Farbdefinitionen für bessere Lesbarkeit
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

# Logo und Intro anzeigen
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
echo "║                      Setup Script v1.0.0                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BOLD}Willkommen beim Kormit Setup-Skript!${RESET}"
echo -e "Dieses Skript lädt den Kormit Installer herunter und führt ihn aus.\n"

# Prüfen, ob das Skript als Root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}${BOLD}✘ Dieses Skript muss als Root ausgeführt werden.${RESET}"
    echo -e "${YELLOW}Bitte mit 'sudo' oder als Root-Benutzer ausführen, z.B.:${RESET}"
    echo -e "${BOLD}sudo curl -sSL https://example.com/setup.sh | sudo bash${RESET}"
    exit 1
fi

# Temporäres Verzeichnis für den Download
TMP_DIR=$(mktemp -d)
INSTALL_SCRIPT="$TMP_DIR/install.sh"

echo -e "${CYAN}▶ Überprüfe Voraussetzungen...${RESET}"

# Curl prüfen (sollte verfügbar sein, da wir das Skript mit curl ausführen)
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}⚠️ Curl scheint nicht verfügbar zu sein. Versuche, es zu installieren...${RESET}"
    
    # Betriebssystem erkennen und curl installieren
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        
        case $ID in
            ubuntu|debian)
                apt update
                apt install -y curl
                ;;
            centos|rhel|fedora)
                yum install -y curl
                ;;
            *)
                echo -e "${RED}❌ Nicht unterstütztes Betriebssystem für die automatische Installation von curl.${RESET}"
                echo -e "${YELLOW}Bitte installieren Sie curl manuell und führen Sie das Skript erneut aus.${RESET}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}❌ Konnte das Betriebssystem nicht erkennen.${RESET}"
        echo -e "${YELLOW}Bitte installieren Sie curl manuell und führen Sie das Skript erneut aus.${RESET}"
        exit 1
    fi
fi

echo -e "${CYAN}▶ Lade Kormit Installer herunter...${RESET}"

# Installationsskript-URL (beispielhaft)
INSTALL_URL="https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy/install.sh"

# Herunterladen des Installationsskripts
if curl -sSL "$INSTALL_URL" -o "$INSTALL_SCRIPT"; then
    echo -e "${GREEN}✅ Download erfolgreich.${RESET}"
else
    echo -e "${RED}❌ Fehler beim Herunterladen des Installationsskripts.${RESET}"
    echo -e "${YELLOW}Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.${RESET}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Ausführbar machen
chmod +x "$INSTALL_SCRIPT"

echo -e "\n${CYAN}▶ Einrichtungsoptionen${RESET}"
echo -e "${YELLOW}Möchten Sie das Installationsskript mit benutzerdefinierten Parametern ausführen?${RESET}"
echo -e "1) Standard-Installation (empfohlen)"
echo -e "2) Benutzerdefinierte Installation"
echo -e "3) Abbrechen"

read -p "Option wählen (1-3): " setup_option

case $setup_option in
    1)
        echo -e "\n${CYAN}▶ Starte Standard-Installation...${RESET}"
        "$INSTALL_SCRIPT"
        ;;
    2)
        echo -e "\n${CYAN}▶ Benutzerdefinierte Installation...${RESET}"
        
        # Installationsverzeichnis
        DEFAULT_INSTALL_DIR="/opt/kormit"
        read -p "Installationsverzeichnis [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
        INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
        
        # Domain-Name
        DEFAULT_DOMAIN="localhost"
        read -p "Domain-Name oder IP-Adresse [$DEFAULT_DOMAIN]: " DOMAIN_NAME
        DOMAIN_NAME=${DOMAIN_NAME:-$DEFAULT_DOMAIN}
        
        # HTTP-Port
        DEFAULT_HTTP_PORT="80"
        read -p "HTTP-Port [$DEFAULT_HTTP_PORT]: " HTTP_PORT
        HTTP_PORT=${HTTP_PORT:-$DEFAULT_HTTP_PORT}
        
        # HTTPS verwenden?
        read -p "HTTPS verwenden? (J/n): " use_https
        if [[ "$use_https" =~ ^[nN]$ ]]; then
            HTTP_ONLY="--http-only"
        else
            HTTP_ONLY=""
            # HTTPS-Port
            DEFAULT_HTTPS_PORT="443"
            read -p "HTTPS-Port [$DEFAULT_HTTPS_PORT]: " HTTPS_PORT
            HTTPS_PORT=${HTTPS_PORT:-$DEFAULT_HTTPS_PORT}
        fi
        
        echo -e "\n${CYAN}▶ Starte benutzerdefinierte Installation...${RESET}"
        
        # Argumente für das Installationsskript zusammenstellen
        INSTALL_ARGS="--install-dir=$INSTALL_DIR --domain=$DOMAIN_NAME --http-port=$HTTP_PORT"
        
        if [ -n "$HTTP_ONLY" ]; then
            INSTALL_ARGS="$INSTALL_ARGS $HTTP_ONLY"
        else
            INSTALL_ARGS="$INSTALL_ARGS --https-port=$HTTPS_PORT"
        fi
        
        "$INSTALL_SCRIPT" $INSTALL_ARGS
        ;;
    3)
        echo -e "\n${YELLOW}Installation abgebrochen.${RESET}"
        rm -rf "$TMP_DIR"
        exit 0
        ;;
    *)
        echo -e "\n${RED}Ungültige Option. Installation wird mit Standardoptionen fortgesetzt.${RESET}"
        "$INSTALL_SCRIPT"
        ;;
esac

# Aufräumen
rm -rf "$TMP_DIR"

# Kormit-Befehl erstellen
echo -e "\n${CYAN}▶ Erstelle 'kormit' Systembefehl...${RESET}"

# Den Pfad zum Installationsverzeichnis verwenden (falls angepasst)
MANAGE_SCRIPT="${INSTALL_DIR:-/opt/kormit}/manage.sh"

# Wrapper-Skript erstellen
KORMIT_WRAPPER="/usr/local/bin/kormit"

cat > "$KORMIT_WRAPPER" << EOL
#!/bin/bash
# Kormit-Befehl Wrapper
sudo ${MANAGE_SCRIPT} "\$@"
EOL

# Ausführbar machen
chmod +x "$KORMIT_WRAPPER"

echo -e "${GREEN}✅ Kormit-Befehl erfolgreich eingerichtet.${RESET}"

echo -e "\n${GREEN}${BOLD}Setup abgeschlossen!${RESET}"
echo -e "Sie können Kormit nun auf zwei Arten verwenden:"
echo -e "1. Über den globalen Befehl: ${BOLD}kormit${RESET}"
echo -e "2. Direkt über das Skript: ${BOLD}sudo ${MANAGE_SCRIPT}${RESET}"
echo -e "\nBitte beachten: Der 'kormit'-Befehl verwendet intern sudo."
echo -e "\nVielen Dank, dass Sie Kormit verwenden!"
