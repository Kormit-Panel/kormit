#!/bin/bash
# Kormit Installer Setup Script
# This script downloads and runs the Kormit Management Script
# Version 1.1.0 - Mit Uninstall-Funktionalität

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
echo "║                      Setup Script v1.1.0                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${BOLD}Willkommen beim Kormit Setup-Skript!${RESET}"

# Standard-Installationsverzeichnis
DEFAULT_INSTALL_DIR="/opt/kormit"

# Parameter verarbeiten
UNINSTALL=false
PURGE=false

for i in "$@"; do
    case $i in
        --help|-h)
            echo -e "Verwendung: $0 [Optionen]"
            echo -e ""
            echo -e "Optionen:"
            echo -e "  --uninstall       Kormit deinstallieren (Manager-Skript und Befehl entfernen)"
            echo -e "  --purge           Kormit vollständig entfernen (inkl. Daten und Konfiguration)"
            echo -e "  --dir=PFAD        Installationsverzeichnis (Standard: $DEFAULT_INSTALL_DIR)"
            echo -e "  --help, -h        Diese Hilfe anzeigen"
            echo -e ""
            exit 0
            ;;
        --uninstall)
            UNINSTALL=true
            ;;
        --purge)
            UNINSTALL=true
            PURGE=true
            ;;
        --dir=*)
            DEFAULT_INSTALL_DIR="${i#*=}"
            ;;
        *)
            echo -e "${YELLOW}Unbekannter Parameter: $i${RESET}"
            echo -e "Verwenden Sie --help für Hilfe."
            ;;
    esac
done

# Prüfen, ob das Skript als Root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}${BOLD}✘ Dieses Skript muss als Root ausgeführt werden.${RESET}"
    echo -e "${YELLOW}Bitte mit 'sudo' oder als Root-Benutzer ausführen, z.B.:${RESET}"
    echo -e "${BOLD}sudo curl -sSL https://github.com/Kormit-Panel/kormit/raw/refs/heads/main/deploy/kormit-setup.sh | sudo bash${RESET}"
    exit 1
fi

# Funktion zum Stoppen und Entfernen von Kormit
uninstall_kormit() {
    local install_dir="$1"
    local purge="$2"
    
    echo -e "${CYAN}▶ Deinstalliere Kormit...${RESET}"
    
    # Systemweiten Befehl entfernen
    echo -e "${YELLOW}→ Entferne systemweiten Befehl...${RESET}"
    if [ -L "/usr/local/bin/kormit" ]; then
        rm -f "/usr/local/bin/kormit"
        echo -e "${GREEN}✓ Systemweiter Befehl wurde entfernt.${RESET}"
    else
        echo -e "${YELLOW}! Systemweiter Befehl wurde nicht gefunden.${RESET}"
    fi
    
    # Stoppe Kormit, falls aktiv
    if [ -f "$install_dir/stop.sh" ]; then
        echo -e "${YELLOW}→ Stoppe Kormit-Dienste...${RESET}"
        "$install_dir/stop.sh" >/dev/null 2>&1 || true
    fi
    
    # Entferne Container und Images wenn PURGE aktiviert ist
    if [ "$purge" = true ]; then
        echo -e "${YELLOW}→ Bereinige Docker-Ressourcen...${RESET}"
        
        # Versuche, Docker-Compose-Datei zu finden und Container zu entfernen
        if [ -d "$install_dir/docker/production" ]; then
            cd "$install_dir/docker/production"
            if [ -f "docker-compose.yml" ]; then
                echo -e "${YELLOW}→ Entferne Container und Volumes...${RESET}"
                docker compose down -v --remove-orphans >/dev/null 2>&1 || true
            fi
        fi
        
        # Entferne Docker-Volumes mit Kormit-Prefix
        echo -e "${YELLOW}→ Entferne Docker-Volumes...${RESET}"
        docker volume ls --filter name=kormit -q | xargs -r docker volume rm >/dev/null 2>&1 || true
        
        # Entferne Docker-Netzwerk
        echo -e "${YELLOW}→ Entferne Docker-Netzwerk...${RESET}"
        docker network rm kormit-network >/dev/null 2>&1 || true
        
        # Optional: Images entfernen?
        read -p "Möchten Sie auch die Docker-Images entfernen? (j/N): " remove_images
        if [[ "$remove_images" =~ ^[jJ]$ ]]; then
            echo -e "${YELLOW}→ Entferne Docker-Images...${RESET}"
            docker images | grep "kormit" | awk '{print $3}' | xargs -r docker rmi -f >/dev/null 2>&1 || true
        fi
        
        # Entferne Installationsverzeichnis
        echo -e "${RED}→ Entferne Installationsverzeichnis: $install_dir${RESET}"
        rm -rf "$install_dir"
        echo -e "${GREEN}✓ Installationsverzeichnis wurde entfernt.${RESET}"
    else
        # Bei normaler Deinstallation nur das Manager-Skript entfernen
        if [ -f "$install_dir/kormit-manager.sh" ]; then
            echo -e "${YELLOW}→ Entferne Manager-Skript...${RESET}"
            rm -f "$install_dir/kormit-manager.sh"
            echo -e "${GREEN}✓ Manager-Skript wurde entfernt.${RESET}"
        else
            echo -e "${YELLOW}! Manager-Skript wurde nicht gefunden.${RESET}"
        fi
    fi
    
    echo -e "${GREEN}✅ Deinstallation abgeschlossen.${RESET}"
    exit 0
}

# Wenn --uninstall oder --purge gesetzt ist, führe die Deinstallation durch
if [ "$UNINSTALL" = true ]; then
    if [ "$PURGE" = true ]; then
        echo -e "${RED}${BOLD}ACHTUNG: Sie sind dabei, Kormit vollständig zu entfernen!${RESET}"
        echo -e "${RED}Dies wird alle Container, Volumes und Konfigurationsdaten löschen.${RESET}"
    else
        echo -e "${YELLOW}${BOLD}ACHTUNG: Sie sind dabei, das Kormit-Managementtool zu deinstallieren.${RESET}"
        echo -e "${YELLOW}Die Daten und Container bleiben erhalten.${RESET}"
    fi
    
    echo -e "Installationsverzeichnis: ${BOLD}$DEFAULT_INSTALL_DIR${RESET}"
    read -p "Sind Sie sicher, dass Sie fortfahren möchten? (j/N): " confirm
    
    if [[ "$confirm" =~ ^[jJ]$ ]]; then
        uninstall_kormit "$DEFAULT_INSTALL_DIR" "$PURGE"
    else
        echo -e "${YELLOW}Deinstallation abgebrochen.${RESET}"
        exit 0
    fi
fi

# Normale Installation fortsetzen
echo -e "Dieses Skript lädt den Kormit Installer herunter und führt ihn aus.\n"

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
echo -e "1) Standard-Installation nach $DEFAULT_INSTALL_DIR (empfohlen)"
echo -e "2) Benutzerdefiniertes Installationsverzeichnis"
echo -e "3) Abbrechen"

read -p "Option wählen (1-3): " setup_option

# Installationsverzeichnis festlegen
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

# Systemweiten Befehl einrichten
KORMIT_SCRIPT_ORIG="$REAL_INSTALL_DIR/kormit-manager.sh"
KORMIT_COMMAND="/usr/local/bin/kormit"

# Dann erstellen wir einen symbolischen Link
ln -sf "$KORMIT_SCRIPT_ORIG" "$KORMIT_COMMAND"

echo -e "${GREEN}✅ Kormit-Befehl erfolgreich eingerichtet.${RESET}"

# Aufräumen
rm -rf "$TMP_DIR"

echo -e "\n${GREEN}${BOLD}Setup abgeschlossen!${RESET}"
echo -e "Sie können Kormit nun auf zwei Arten verwenden:"
echo -e "1. Über den globalen Befehl: ${BOLD}sudo kormit${RESET}"
echo -e "2. Direkt über das Skript: ${BOLD}sudo $REAL_INSTALL_DIR/kormit-manager.sh${RESET}"
echo -e "\nBitte beachten: Beide Befehle benötigen Root-Rechte (sudo)."
echo -e "\nUm Kormit später zu deinstallieren, verwenden Sie:"
echo -e "${BOLD}sudo $0 --uninstall${RESET} oder ${BOLD}sudo $0 --purge${RESET} (vollständige Entfernung)"
echo -e "\nVielen Dank, dass Sie Kormit verwenden!"
