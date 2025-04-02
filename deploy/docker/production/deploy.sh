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

# Logging-Funktion
log() {
    local level=$1
    shift
    local message=$1
    case $level in
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
    esac
}

# Banner anzeigen
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
    log "ERROR" "Docker ist nicht installiert. Bitte installieren Sie Docker und versuchen Sie es erneut."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log "ERROR" "Docker Compose ist nicht installiert. Bitte installieren Sie Docker Compose und versuchen Sie es erneut."
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

# Funktion zum Laden eines Docker-Images
load_docker_image() {
    local image_name=$1
    local tar_file=$2
    local registry_path="ghcr.io/kormit-panel/kormit/$image_name"
    
    if [[ -f "$tar_file" ]]; then
        log "INFO" "Lade $image_name aus lokaler Datei..."
        if docker load -i "$tar_file"; then
            export "${image_name^^}_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$image_name" | head -n 1)"
            log "SUCCESS" "$image_name geladen: ${!image_name^^}_IMAGE"
        else
            log "ERROR" "Fehler beim Laden von $image_name"
            return 1
        fi
    else
        log "WARNING" "Keine lokale $image_name-Datei gefunden. Versuche, das Image aus der Registry zu ziehen..."
        if docker pull "$registry_path:latest"; then
            log "SUCCESS" "$image_name aus Registry geholt"
        else
            log "WARNING" "Konnte $image_name nicht aus der Registry ziehen. Stellen Sie sicher, dass es verfügbar ist."
            log "WARNING" "Sie können den Pfad zum lokalen Image mit ${image_name^^}_IMAGE=... überschreiben."
            return 1
        fi
    fi
}

# Images laden
load_docker_image "kormit-backend" "$BACKEND_TAR"
load_docker_image "kormit-frontend" "$FRONTEND_TAR"

# Services starten
log "INFO" "Starte Kormit-Services..."
$DOCKER_COMPOSE down 2>/dev/null || true
$DOCKER_COMPOSE up -d

# Überprüfen, ob alles läuft
log "INFO" "Überprüfe Service-Status..."
sleep 5
if $DOCKER_COMPOSE ps | grep -q "Exit"; then
    log "ERROR" "Einige Services konnten nicht gestartet werden:"
    $DOCKER_COMPOSE ps
    exit 1
else
    log "SUCCESS" "Alle Services wurden erfolgreich gestartet!"
    $DOCKER_COMPOSE ps
fi

# IP des Servers anzeigen
SERVER_IP=$(hostname -I | awk '{print $1}')
log "SUCCESS" "Kormit wurde erfolgreich bereitgestellt!"
log "INFO" "Sie können darauf zugreifen unter:"
echo -e "  Frontend: http://$SERVER_IP/"
echo -e "  API:      http://$SERVER_IP/api"

log "INFO" "Tipp: Zum Anzeigen der Logs verwenden Sie: $DOCKER_COMPOSE logs -f"