#!/bin/bash
# Skript zum Neu-Starten der Kormit-Container mit neuer Konfiguration

set -e

# Farben für Ausgaben
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stoppe laufende Kormit-Container...${NC}"
docker-compose -f docker-compose.yml down || true

echo -e "${YELLOW}Starte Container mit neuer Konfiguration...${NC}"
docker-compose -f docker-compose.yml up -d

echo -e "${GREEN}Container wurden neu gestartet.${NC}"
echo -e "${YELLOW}Kormit ist nun erreichbar unter: http://localhost:8090${NC}"

# Ausgabe der Container-Status
echo -e "${YELLOW}Container-Status:${NC}"
docker-compose -f docker-compose.yml ps

echo -e "${YELLOW}Prüfe Logs für Fehler...${NC}"
docker-compose -f docker-compose.yml logs --tail=10

echo -e "${GREEN}Fertig! Überprüfe die Frontend-Verbindung im Browser unter http://localhost:8090${NC}"