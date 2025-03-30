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
MANAGER_SCRIPT="$TMP_DIR/manager.sh"

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

echo -e "${CYAN}▶ Lade Kormit Manager herunter...${RESET}"

# Installationsskript-URL
INSTALL_URL="https://github.com/Kormit-Panel/kormit/raw/refs/heads/main/deploy/manager.sh"

# Herunterladen des Manager-Skripts
if curl -sSL "$INSTALL_URL" -o "$MANAGER_SCRIPT"; then
    echo -e "${GREEN}✅ Download erfolgreich.${RESET}"
else
    echo -e "${RED}❌ Fehler beim Herunterladen des Manager-Skripts.${RESET}"
    echo -e "${YELLOW}Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.${RESET}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Ausführbar machen
chmod +x "$MANAGER_SCRIPT"

echo -e "\n${CYAN}▶ Einrichtungsoptionen${RESET}"
echo -e "${YELLOW}Möchten Sie das Installationsverzeichnis anpassen?${RESET}"
echo -e "1) Standard-Installation nach /opt/kormit (empfohlen)"
echo -e "2) Benutzerdefiniertes Installationsverzeichnis"
echo -e "3) Abbrechen"

read -p "Option wählen (1-3): " setup_option

# Standardpfad definieren
DEFAULT_INSTALL_DIR="/opt/kormit"
REAL_INSTALL_DIR="$DEFAULT_INSTALL_DIR"

case $setup_option in
    1)
        echo -e "\n${CYAN}▶ Verwende Standardpfad: $DEFAULT_INSTALL_DIR${RESET}"
        ;;
    2)
        echo -e "\n${CYAN}▶ Benutzerdefinierte Installation...${RESET}"
        
        # Installationsverzeichnis
        read -p "Installationsverzeichnis [$DEFAULT_INSTALL_DIR]: " INSTALL_DIR
        REAL_INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
        
        echo -e "Installationsverzeichnis: ${BOLD}$REAL_INSTALL_DIR${RESET}"
        ;;
    3)
        echo -e "\n${YELLOW}Installation abgebrochen.${RESET}"
        rm -rf "$TMP_DIR"
        exit 0
        ;;
    *)
        echo -e "\n${RED}Ungültige Option. Verwende Standardpfad: $DEFAULT_INSTALL_DIR${RESET}"
        ;;
esac

# Zielverzeichnis erstellen, falls es nicht existiert
mkdir -p "$REAL_INSTALL_DIR"

# Manager-Skript in das Zielverzeichnis kopieren
echo -e "\n${CYAN}▶ Installiere Manager-Skript in $REAL_INSTALL_DIR...${RESET}"
cp "$MANAGER_SCRIPT" "$REAL_INSTALL_DIR/kormit-manager.sh"
chmod +x "$REAL_INSTALL_DIR/kormit-manager.sh"

# Aufräumen
rm -rf "$TMP_DIR"

# Kormit-Befehl erstellen
echo -e "\n${CYAN}▶ Erstelle 'kormit' Systembefehl...${RESET}"

# Systemweiten Befehl einrichten
KORMIT_SCRIPT_ORIG="$REAL_INSTALL_DIR/kormit-manager.sh"
KORMIT_COMMAND="/usr/local/bin/kormit"

# Dann erstellen wir einen symbolischen Link
ln -sf "$KORMIT_SCRIPT_ORIG" "$KORMIT_COMMAND"

echo -e "${GREEN}✅ Kormit-Befehl erfolgreich eingerichtet.${RESET}"

echo -e "\n${GREEN}${BOLD}Setup abgeschlossen!${RESET}"
echo -e "Sie können Kormit nun auf zwei Arten verwenden:"
echo -e "1. Über den globalen Befehl: ${BOLD}sudo kormit${RESET}"
echo -e "2. Direkt über das Skript: ${BOLD}sudo $REAL_INSTALL_DIR/kormit-manager.sh${RESET}"
echo -e "\nBitte beachten: Beide Befehle benötigen Root-Rechte (sudo)."
echo -e "\nVielen Dank, dass Sie Kormit verwenden!"
