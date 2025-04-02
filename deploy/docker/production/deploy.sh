#!/usr/bin/env bash
# Kormit Deployment Tool
# Version 1.0.0

# Fehlerbehandlung aktivieren
set -eo pipefail

# Farbdefinitionen
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}
   _  __                    _ _   
  | |/ /___  _ __ _ __ ___ (_) |_ 
  | ' // _ \| '__| '_ \` _ \| | __|
  | . \ (_) | |  | | | | | | | |_ 
  |_|\_\___/|_|  |_| |_| |_|_|\__|
${NC}"

echo -e "${GREEN}Kormit Deployment Tool${NC}\n"

# Überprüfen, ob Docker und Docker Compose installiert sind
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✘ Docker ist nicht installiert. Bitte installieren Sie Docker und versuchen Sie es erneut.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✘ Docker Compose ist nicht installiert. Bitte installieren Sie Docker Compose und versuchen Sie es erneut.${NC}"
    exit 1
fi

# Docker Compose Befehl dynamisch bestimmen
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Verzeichnisstruktur erstellen
mkdir -p ssl

# Pfade zu den Images
BACKEND_TAR="kormit-backend.tar"
FRONTEND_TAR="kormit-frontend.tar"

# Überprüfen, ob Images als Dateien bereitgestellt werden
if [[ -f "$BACKEND_TAR" ]]; then
    echo -e "${YELLOW}→ Backend-Image-Datei gefunden. Lade...${NC}"
    docker load -i "$BACKEND_TAR"
    # Setze Umgebungsvariable auf den geladenen Image-Namen
    export BACKEND_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep kormit-backend | head -n 1)
    echo -e "${GREEN}✓ Backend-Image geladen: $BACKEND_IMAGE${NC}"
else
    echo -e "${YELLOW}→ Keine lokale Backend-Image-Datei gefunden. Versuche, das Image aus der Registry zu ziehen...${NC}"
    if ! docker pull ghcr.io/kormit-panel/kormit/kormit-backend:latest; then
        echo -e "${YELLOW}! Konnte das Backend-Image nicht aus der Registry ziehen. Stelle sicher, dass es verfügbar ist.${NC}"
        echo -e "${YELLOW}! Sie können den Pfad zum lokalen Image mit BACKEND_IMAGE=... überschreiben.${NC}"
    else
        echo -e "${GREEN}✓ Backend-Image aus Registry geholt${NC}"
    fi
fi

if [[ -f "$FRONTEND_TAR" ]]; then
    echo -e "${YELLOW}→ Frontend-Image-Datei gefunden. Lade...${NC}"
    docker load -i "$FRONTEND_TAR"
    # Setze Umgebungsvariable auf den geladenen Image-Namen
    export FRONTEND_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep kormit-frontend | head -n 1)
    echo -e "${GREEN}✓ Frontend-Image geladen: $FRONTEND_IMAGE${NC}"
else
    echo -e "${YELLOW}→ Keine lokale Frontend-Image-Datei gefunden. Versuche, das Image aus der Registry zu ziehen...${NC}"
    if ! docker pull ghcr.io/kormit-panel/kormit/kormit-frontend:latest; then
        echo -e "${YELLOW}! Konnte das Frontend-Image nicht aus der Registry ziehen. Stelle sicher, dass es verfügbar ist.${NC}"
        echo -e "${YELLOW}! Sie können den Pfad zum lokalen Image mit FRONTEND_IMAGE=... überschreiben.${NC}"
    else
        echo -e "${GREEN}✓ Frontend-Image aus Registry geholt${NC}"
    fi
fi

# Starten der Services
echo -e "${BLUE}→ Starte Kormit-Services...${NC}"
$DOCKER_COMPOSE down 2>/dev/null || true
$DOCKER_COMPOSE up -d

# Überprüfen, ob alles läuft
echo -e "${YELLOW}→ Überprüfe Service-Status...${NC}"
sleep 5
if $DOCKER_COMPOSE ps | grep -q "Exit"; then
    echo -e "${RED}✘ Einige Services konnten nicht gestartet werden:${NC}"
    $DOCKER_COMPOSE ps
    exit 1
else
    echo -e "${GREEN}✓ Alle Services wurden erfolgreich gestartet!${NC}"
    $DOCKER_COMPOSE ps
fi

# IP des Servers anzeigen
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}✓ Kormit wurde erfolgreich bereitgestellt!${NC}"
echo -e "${BLUE}Sie können darauf zugreifen unter:${NC}"
echo -e "  Frontend: http://$SERVER_IP/"
echo -e "  API:      http://$SERVER_IP/api"
echo -e "\n${YELLOW}Tipp: Zum Anzeigen der Logs verwenden Sie:${NC} $DOCKER_COMPOSE logs -f"