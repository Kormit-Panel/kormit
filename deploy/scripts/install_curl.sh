#!/bin/bash
# Kormit Curl Installer für Linux
# Dieses Skript erlaubt die Installation von Kormit direkt über curl

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

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 KORMIT CURL INSTALLER                      ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "${GREEN}Lade Kormit Installationsskript herunter...${NC}"

# Installationsskript herunterladen und ausführen
curl -sSL ${REPO_URL}/install.sh -o kormit_install.sh
chmod +x kormit_install.sh

# Parameter an das Skript weiterleiten
./kormit_install.sh "$@"

# Aufräumen
rm kormit_install.sh

echo -e "${GREEN}Installation abgeschlossen!${NC}" 