#!/bin/bash
# Kormit Installationshelfer - Plattformerkennung
# Version 1.1.5 - Vollständige Korrektur des Start-Skript-Problems

# Farbige Ausgaben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Basis-URL zum Kormit-Repository
REPO_URL="https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy"

# Funktion zum Erkennen des Betriebssystems
detect_os() {
    # Prüfen auf Windows
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
        return
    fi
    
    # Prüfen auf macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
        return
    fi
    
    # Prüfen auf Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
        return
    fi
    
    # Fallback
    echo "unknown"
}

# OS erkennen
OS=$(detect_os)

echo -e "${BLUE}Erkanntes Betriebssystem: ${GREEN}$OS${NC}"

# Je nach Betriebssystem den richtigen Installer aufrufen
case $OS in
    linux|macos)
        echo -e "${BLUE}Starte Linux/macOS-Installer...${NC}"
        curl -sSL "${REPO_URL}/scripts/install_curl.sh" | bash -s -- "$@"
        ;;
    windows)
        echo -e "${YELLOW}Windows erkannt. PowerShell-Installer wird empfohlen.${NC}"
        echo -e "${YELLOW}Bitte führen Sie diesen Befehl in PowerShell aus:${NC}"
        echo -e "${GREEN}Invoke-Expression (New-Object System.Net.WebClient).DownloadString('${REPO_URL}/scripts/install_curl.ps1')${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}Nicht unterstütztes Betriebssystem.${NC}"
        echo -e "${YELLOW}Bitte besuchen Sie https://github.com/kormit-panel/kormit für weitere Informationen.${NC}"
        exit 1
        ;;
esac

exit 0
