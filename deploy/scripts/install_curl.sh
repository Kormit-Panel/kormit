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
echo -e "${BLUE}Sie können den HTTP-only-Modus mit --http-only aktivieren, wenn Sie kein HTTPS benötigen.${NC}"

# Temporären Dateinamen generieren
TEMP_SCRIPT="kormit_install_$$.sh"

# Installationsskript herunterladen und ausführen
curl -sSL ${REPO_URL}/install.sh -o "$TEMP_SCRIPT"
chmod +x "$TEMP_SCRIPT"

# Parameter an das Skript weiterleiten
./"$TEMP_SCRIPT" "$@"
EXIT_CODE=$?

# Aufräumen
rm -f "$TEMP_SCRIPT"

echo -e "${GREEN}Installation abgeschlossen!${NC}"
exit $EXIT_CODE 