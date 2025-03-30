#!/bin/bash
# Kormit Installer Setup Script
# This script downloads and runs the Kormit Management Script
# Version 1.2.1 - Mit korrigiertem interaktivem Menü

# Farbdefinitionen für bessere Lesbarkeit
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
BLUE="\033[34m"

# Standard-Installationsverzeichnis
DEFAULT_INSTALL_DIR="/opt/kormit"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"

# Funktion für Logo
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
    echo "║                      Setup Script v1.2.1                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# Prüfen, ob das Skript als Root ausgeführt wird
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${BOLD}✘ Dieses Skript muss als Root ausgeführt werden.${RESET}"
        echo -e "${YELLOW}Bitte mit 'sudo' oder als Root-Benutzer ausführen, z.B.:${RESET}"
        echo -e "${BOLD}sudo curl -sSL https://github.com/Kormit-Panel/kormit/raw/refs/heads/main/deploy/kormit-setup.sh | sudo bash${RESET}"
        exit 1
    fi
}

# Hilfefunktion
show_help() {
    echo -e "Verwendung: $0 [Optionen]"
    echo -e ""
    echo -e "Optionen:"
    echo -e "  --install         Kormit installieren"
    echo -e "  --uninstall       Kormit deinstallieren (Manager-Skript und Befehl entfernen)"
    echo -e "  --purge           Kormit vollständig entfernen (inkl. Daten und Konfiguration)"
    echo -e "  --dir=PFAD        Installationsverzeichnis (Standard: $DEFAULT_INSTALL_DIR)"
    echo -e "  --help, -h        Diese Hilfe anzeigen"
    echo -e ""
    echo -e "Ohne Parameter wird ein interaktives Menü angezeigt."
    echo -e ""
    exit 0
}

# Funktion zum Installieren von Kormit
install_kormit() {
    local install_dir="$1"
    
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
                    return 1
                    ;;
            esac
        else
            echo -e "${RED}❌ Konnte das Betriebssystem nicht erkennen.${RESET}"
            echo -e "${YELLOW}Bitte installieren Sie curl manuell und führen Sie das Skript erneut aus.${RESET}"
            return 1
        fi
    fi

    echo -e "${CYAN}▶ Lade Kormit Manager herunter...${RESET}"

    # Temporäres Verzeichnis für den Download
    TMP_DIR=$(mktemp -d)
    MANAGER_SCRIPT="$TMP_DIR/manager.sh"

    # Installationsskript-URL
    INSTALL_URL="https://github.com/Kormit-Panel/kormit/raw/refs/heads/main/deploy/manager.sh"

    # Herunterladen des Manager-Skripts
    if curl -sSL "$INSTALL_URL" -o "$MANAGER_SCRIPT"; then
        echo -e "${GREEN}✅ Download erfolgreich.${RESET}"
    else
        echo -e "${RED}❌ Fehler beim Herunterladen des Manager-Skripts.${RESET}"
        echo -e "${YELLOW}Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.${RESET}"
        rm -rf "$TMP_DIR"
        return 1
    fi

    # Ausführbar machen
    chmod +x "$MANAGER_SCRIPT"

    # Möglichkeit zum Anpassen des Installationsverzeichnisses
    local adjusted_dir=""
    echo -e "\n${CYAN}▶ Einrichtungsoptionen${RESET}"
    echo -e "${YELLOW}Möchten Sie das Installationsverzeichnis anpassen?${RESET}"
    echo -e "1) Standard-Installation nach $install_dir (empfohlen)"
    echo -e "2) Benutzerdefiniertes Installationsverzeichnis"
    echo -e "3) Abbrechen"

    read -p "Option wählen (1-3): " setup_option

    case $setup_option in
        1)
            echo -e "\n${CYAN}▶ Verwende Standardpfad: $install_dir${RESET}"
            adjusted_dir="$install_dir"
            ;;
        2)
            echo -e "\n${CYAN}▶ Benutzerdefinierte Installation...${RESET}"
            
            # Installationsverzeichnis
            read -p "Installationsverzeichnis [$install_dir]: " custom_dir
            if [ -n "$custom_dir" ]; then
                adjusted_dir="$custom_dir"
            else
                adjusted_dir="$install_dir"
            fi
            
            echo -e "Installationsverzeichnis: ${BOLD}$adjusted_dir${RESET}"
            ;;
        3)
            echo -e "\n${YELLOW}Installation abgebrochen.${RESET}"
            rm -rf "$TMP_DIR"
            return 1
            ;;
        *)
            echo -e "\n${RED}Ungültige Option. Verwende Standardpfad: $install_dir${RESET}"
            adjusted_dir="$install_dir"
            ;;
    esac

    # Zielverzeichnis erstellen, falls es nicht existiert
    mkdir -p "$adjusted_dir"

    # Manager-Skript in das Zielverzeichnis kopieren
    echo -e "\n${CYAN}▶ Installiere Manager-Skript in $adjusted_dir...${RESET}"
    cp "$MANAGER_SCRIPT" "$adjusted_dir/kormit-manager.sh"
    chmod +x "$adjusted_dir/kormit-manager.sh"

    # Systemweiten Befehl einrichten
    local KORMIT_SCRIPT_ORIG="$adjusted_dir/kormit-manager.sh"
    local KORMIT_COMMAND="/usr/local/bin/kormit"

    # Dann erstellen wir einen symbolischen Link
    ln -sf "$KORMIT_SCRIPT_ORIG" "$KORMIT_COMMAND"

    echo -e "${GREEN}✅ Kormit-Befehl erfolgreich eingerichtet.${RESET}"

    # Aufräumen
    rm -rf "$TMP_DIR"

    echo -e "\n${GREEN}${BOLD}Setup abgeschlossen!${RESET}"
    echo -e "Sie können Kormit nun auf zwei Arten verwenden:"
    echo -e "1. Über den globalen Befehl: ${BOLD}sudo kormit${RESET}"
    echo -e "2. Direkt über das Skript: ${BOLD}sudo $adjusted_dir/kormit-manager.sh${RESET}"
    echo -e "\nBitte beachten: Beide Befehle benötigen Root-Rechte (sudo)."
    
    # Fragen, ob Kormit direkt gestartet werden soll
    echo -e "\n${YELLOW}Möchten Sie Kormit jetzt starten? (j/N)${RESET}"
    read -p "> " start_now
    
    if [[ "$start_now" =~ ^[jJ]$ ]]; then
        echo -e "${CYAN}▶ Starte Kormit...${RESET}"
        "$KORMIT_COMMAND"
    else
        echo -e "\n${YELLOW}Sie können Kormit jederzeit mit '${BOLD}sudo kormit${RESET}${YELLOW}' starten.${RESET}"
    fi
    
    return 0
}

# Funktion zum Deinstallieren von Kormit
uninstall_kormit() {
    local install_dir="$1"
    local purge="$2"
    
    if [ "$purge" = true ]; then
        echo -e "${RED}${BOLD}ACHTUNG: Sie sind dabei, Kormit vollständig zu entfernen!${RESET}"
        echo -e "${RED}Dies wird alle Container, Volumes und Konfigurationsdaten löschen.${RESET}"
    else
        echo -e "${YELLOW}${BOLD}ACHTUNG: Sie sind dabei, das Kormit-Managementtool zu deinstallieren.${RESET}"
        echo -e "${YELLOW}Die Daten und Container bleiben erhalten.${RESET}"
    fi
    
    echo -e "Installationsverzeichnis: ${BOLD}$install_dir${RESET}"
    read -p "Sind Sie sicher, dass Sie fortfahren möchten? (j/N): " confirm
    
    if [[ ! "$confirm" =~ ^[jJ]$ ]]; then
        echo -e "${YELLOW}Deinstallation abgebrochen.${RESET}"
        return 1
    fi
    
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
    return 0
}

# Interaktives Menü anzeigen - jetzt mit Ausführungssteuerung
show_menu() {
    print_logo
    echo -e "${BLUE}${BOLD}HAUPTMENÜ${RESET}"
    echo -e "${BLUE}═════════${RESET}"
    echo -e "1) ${BOLD}Kormit installieren${RESET} - Neue Installation durchführen"
    echo -e "2) ${BOLD}Kormit deinstallieren${RESET} - Manager-Skript und Befehl entfernen"
    echo -e "3) ${BOLD}Kormit vollständig entfernen${RESET} - Alle Daten und Container löschen"
    echo -e "${BLUE}───────────────────────────${RESET}"
    echo -e "4) ${BOLD}Installationsverzeichnis ändern${RESET} - (aktuell: $INSTALL_DIR)"
    echo -e "${BLUE}───────────────────────────${RESET}"
    echo -e "0) ${BOLD}Beenden${RESET} - Programm beenden"
    echo ""
    echo -e "Wählen Sie eine Option (0-4):"
    read -p "> " choice
    
    case $choice in
        1)
            install_kormit "$INSTALL_DIR"
            return 0
            ;;
        2)
            uninstall_kormit "$INSTALL_DIR" false
            return 0
            ;;
        3)
            uninstall_kormit "$INSTALL_DIR" true
            return 0
            ;;
        4)
            echo -e "Aktuelles Installationsverzeichnis: ${BOLD}$INSTALL_DIR${RESET}"
            read -p "Neues Installationsverzeichnis eingeben: " new_dir
            if [ -n "$new_dir" ]; then
                INSTALL_DIR="$new_dir"
                echo -e "${GREEN}✅ Installationsverzeichnis geändert auf: ${BOLD}$INSTALL_DIR${RESET}"
            fi
            # Hier kein return, damit wir wieder ins Menü kommen
            ;;
        0)
            echo -e "${GREEN}Auf Wiedersehen!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Ungültige Option. Bitte wählen Sie eine Zahl zwischen 0 und 4.${RESET}"
            # Hier kein return, damit wir wieder ins Menü kommen
            ;;
    esac
    
    # Nach Option 4 oder bei ungültiger Eingabe fragen wir, ob man zurück zum Menü will
    echo ""
    read -p "Drücken Sie Enter, um fortzufahren oder 'q' zum Beenden: " continue_opt
    if [[ "$continue_opt" =~ ^[qQ]$ ]]; then
        echo -e "${GREEN}Auf Wiedersehen!${RESET}"
        exit 0
    fi
    
    return 1  # 1 = Menü erneut anzeigen
}

# Hauptprogramm
main() {
    check_root
    
    # Verarbeite Kommandozeilenparameter
    UNINSTALL=false
    PURGE=false
    CUSTOM_DIR=""
    
    # Prüfen, ob Parameter vorhanden sind
    if [ $# -gt 0 ]; then
        for i in "$@"; do
            case $i in
                --help|-h)
                    show_help
                    ;;
                --install)
                    if [ -n "$CUSTOM_DIR" ]; then
                        install_kormit "$CUSTOM_DIR"
                    else
                        install_kormit "$DEFAULT_INSTALL_DIR"
                    fi
                    exit $?
                    ;;
                --uninstall)
                    UNINSTALL=true
                    ;;
                --purge)
                    UNINSTALL=true
                    PURGE=true
                    ;;
                --dir=*)
                    CUSTOM_DIR="${i#*=}"
                    ;;
                *)
                    echo -e "${YELLOW}Unbekannter Parameter: $i${RESET}"
                    echo -e "Verwenden Sie --help für Hilfe."
                    ;;
            esac
        done
        
        # Wenn --uninstall oder --purge gesetzt ist, führe die Deinstallation durch
        if [ "$UNINSTALL" = true ]; then
            if [ -n "$CUSTOM_DIR" ]; then
                uninstall_kormit "$CUSTOM_DIR" "$PURGE"
            else
                uninstall_kormit "$DEFAULT_INSTALL_DIR" "$PURGE"
            fi
            exit $?
        fi
    else
        # Interaktiven Modus starten - nur einmal anzeigen, nicht in Schleife
        while true; do
            clear  # Bildschirm säubern vor jeder Anzeige
            show_menu
            # Wenn show_menu 0 zurückgibt, beenden wir die Schleife
            if [ $? -eq 0 ]; then
                break
            fi
        done
    fi
}

# Skript starten
main "$@"
