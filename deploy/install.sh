#!/usr/bin/env bash
# Kormit Installation Script
# Installiert die Kormit-Anwendung mit Docker Compose
# Version 1.0.0

# Fehlerbehandlung aktivieren mit detailliertem Logging
set -eo pipefail

# Fehlerbehandlungs-Funktionen
handle_error() {
    local line_num=$1
    local error_code=$2
    local last_command=$3
    
    echo -e "${RED}Fehler beim Ausführen des Skripts:${RESET}"
    echo -e "${RED}Befehl '${last_command}' fehlgeschlagen mit Exit-Code ${error_code} in Zeile ${line_num}${RESET}"
    echo -e "${YELLOW}Überprüfen Sie die Berechtigungen und Verfügbarkeit der benötigten Dateien${RESET}"
}

# Registriere die Fehlerbehandlungs-Funktion
trap 'handle_error ${LINENO} $? "$BASH_COMMAND"' ERR

# Farbdefinitionen
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m' # No Color

# Standardwerte
INSTALL_DIR="/opt/kormit"
DOMAIN_NAME="localhost"
HTTP_PORT="80"
HTTPS_PORT="443"
HTTP_ONLY=true  # Standardmäßig nur HTTP verwenden

# Hilfefunktion
show_help() {
    echo "Verwendung: $0 [Optionen]"
    echo ""
    echo "Optionen:"
    echo "  --install-dir=DIR    Installationsverzeichnis (Standard: /opt/kormit)"
    echo "  --domain=DOMAIN      Domain-Name oder IP-Adresse (Standard: localhost)"
    echo "  --http-port=PORT     HTTP-Port (Standard: 80)"
    echo "  --https-port=PORT    HTTPS-Port (Standard: 443, nur mit --use-https)"
    echo "  --use-https          HTTPS aktivieren (Standard: deaktiviert)"
    echo "  --http-only          Nur HTTP verwenden (Standard: aktiviert)"
    echo "  --help               Diese Hilfe anzeigen"
    echo ""
    exit 0
}

# Parameter verarbeiten
for i in "$@"; do
    case $i in
        --install-dir=*)
            INSTALL_DIR="${i#*=}"
            ;;
        --domain=*)
            DOMAIN_NAME="${i#*=}"
            ;;
        --http-port=*)
            HTTP_PORT="${i#*=}"
            ;;
        --https-port=*)
            HTTPS_PORT="${i#*=}"
            ;;
        --use-https)
            HTTP_ONLY=false
            ;;
        --http-only)
            HTTP_ONLY=true
            ;;
        --help)
            show_help
            ;;
        *)
            echo "Unbekannte Option: $i"
            show_help
            ;;
    esac
done

echo -e "${BLUE}
   _  __                    _ _   
  | |/ /___  _ __ _ __ ___ (_) |_ 
  | ' // _ \| '__| '_ \` _ \| | __|
  | . \ (_) | |  | | | | | | | |_ 
  |_|\_\___/|_|  |_| |_| |_|_|\__|
${RESET}"

echo -e "${GREEN}Kormit Installation Tool${RESET}\n"

echo -e "${CYAN}▶ Installationsdetails:${RESET}"
echo -e "  - Installationsverzeichnis: ${INSTALL_DIR}"
echo -e "  - Domain-Name: ${DOMAIN_NAME}"
echo -e "  - HTTP-Port: ${HTTP_PORT}"
if [[ "$HTTP_ONLY" = false ]]; then
    echo -e "  - HTTPS-Port: ${HTTPS_PORT}"
    echo -e "  - Protokoll: HTTP & HTTPS"
else
    echo -e "  - Protokoll: Nur HTTP"
fi

# Verzeichnisstruktur erstellen
echo -e "\n${CYAN}▶ Erstelle Verzeichnisstruktur...${RESET}"
mkdir -p "${INSTALL_DIR}/docker/production"
mkdir -p "${INSTALL_DIR}/docker/production/logs"
mkdir -p "${INSTALL_DIR}/docker/production/ssl"

# Docker-Compose-Datei kopieren
echo -e "${CYAN}▶ Kopiere Docker-Compose-Konfiguration...${RESET}"
# Funktion zum Finden und Kopieren einer Datei
find_and_copy_file() {
    local file_name="$1"
    local target_dir="$2"
    local description="$3"
    
    # Debug-Ausgabe hinzufügen
    echo -e "${CYAN}▶ Debug: Suche nach $file_name für $description${RESET}"
    echo -e "${CYAN}▶ Debug: Zielverzeichnis ist $target_dir${RESET}"
    echo -e "${CYAN}▶ Debug: Basis-Skriptpfad ist $(dirname "$0")${RESET}"
    
    # Prüfe, ob das Zielverzeichnis existiert
    if [[ ! -d "$target_dir" ]]; then
        echo -e "${YELLOW}▶ Debug: Zielverzeichnis existiert nicht, wird erstellt...${RESET}"
        mkdir -p "$target_dir" || {
            echo -e "${RED}Fehler: Konnte Zielverzeichnis $target_dir nicht erstellen.${RESET}"
            return 1
        }
    fi
    
    # Standardpfad prüfen
    local standard_path="$(dirname "$0")/docker/production/$file_name"
    echo -e "${CYAN}▶ Debug: Prüfe Standardpfad: $standard_path${RESET}"
    
    if [[ -f "$standard_path" ]]; then
        echo -e "${CYAN}▶ Debug: Datei im Standardpfad gefunden${RESET}"
        if cp "$standard_path" "$target_dir/"; then
            echo -e "${GREEN}✅ $description aus Standardpfad kopiert.${RESET}"
            return 0
        else
            echo -e "${RED}Fehler: Konnte Datei nicht aus Standardpfad kopieren.${RESET}"
        fi
    fi
    
    # Alternative Pfade suchen
    echo -e "${YELLOW}$description nicht im Standardpfad gefunden. Suche an alternativen Orten...${RESET}"
    
    # Suche nach der Datei
    echo -e "${CYAN}▶ Debug: Starte Dateisuche in $(dirname "$0")${RESET}"
    
    # Verwende find mit Error-Handling
    local find_result
    find_result=$(find "$(dirname "$0")" -name "$file_name" 2>/dev/null || echo "")
    
    # Prüfe, ob find erfolgreich war
    if [[ -z "$find_result" ]]; then
        echo -e "${RED}Fehler: find-Befehl konnte nicht ausgeführt werden oder fand keine Ergebnisse.${RESET}"
        echo -e "${YELLOW}▶ Debug: Versuche direkten Zugriff auf bekannte Speicherorte...${RESET}"
        
        # Versuche einige bekannte Speicherorte
        local known_paths=(
            "$(dirname "$0")/docker/$file_name"
            "$(dirname "$0")/../docker/production/$file_name"
            "$(dirname "$0")/../docker/$file_name"
            "$(dirname "$0")/docker/development/$file_name"
        )
        
        for path in "${known_paths[@]}"; do
            echo -e "${CYAN}▶ Debug: Prüfe $path${RESET}"
            if [[ -f "$path" ]]; then
                echo -e "${CYAN}▶ Debug: Datei gefunden unter $path${RESET}"
                if cp "$path" "$target_dir/"; then
                    echo -e "${GREEN}✅ $description aus $path kopiert.${RESET}"
                    return 0
                else
                    echo -e "${RED}Fehler: Konnte Datei nicht aus $path kopieren.${RESET}"
                fi
            fi
        done
        
        echo -e "${RED}Fehler: $description konnte nicht gefunden werden.${RESET}"
        return 1
    fi
    
    # Konvertiere in Array
    mapfile -t found_files < <(echo "$find_result" | sort)
    
    echo -e "${CYAN}▶ Debug: ${#found_files[@]} Dateien gefunden${RESET}"
    for file in "${found_files[@]}"; do
        echo -e "${CYAN}▶ Debug: Gefunden: $file${RESET}"
    done
    
    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo -e "${RED}Fehler: $description nicht gefunden.${RESET}"
        return 1
    fi
    
    # Verwende die erste gefundene Datei (bevorzuge production über development)
    for file in "${found_files[@]}"; do
        if [[ "$file" == *"/production/"* ]]; then
            echo -e "${CYAN}▶ Debug: Verwende production-Datei: $file${RESET}"
            if cp "$file" "$target_dir/"; then
                echo -e "${GREEN}✅ $description aus $file kopiert.${RESET}"
                return 0
            else
                echo -e "${RED}Fehler: Konnte Datei nicht kopieren: $file${RESET}"
            fi
        fi
    done
    
    # Wenn keine production-Version gefunden wurde, verwende die erste Datei
    echo -e "${CYAN}▶ Debug: Keine production-Version gefunden, verwende erste Datei: ${found_files[0]}${RESET}"
    if cp "${found_files[0]}" "$target_dir/"; then
        echo -e "${YELLOW}⚠️ $description aus ${found_files[0]} kopiert (nicht aus /production/).${RESET}"
        return 0
    else
        echo -e "${RED}Fehler: Konnte Datei nicht kopieren: ${found_files[0]}${RESET}"
        return 1
    fi
}

if ! find_and_copy_file "docker-compose.yml" "${INSTALL_DIR}/docker/production" "Docker-Compose-Konfiguration"; then
    echo -e "${RED}Fehler: docker-compose.yml konnte nicht gefunden werden.${RESET}"
    exit 1
fi

# Nginx-Konfiguration kopieren
echo -e "${CYAN}▶ Kopiere Nginx-Konfiguration...${RESET}"
if ! find_and_copy_file "nginx.conf" "${INSTALL_DIR}/docker/production" "Nginx-Konfiguration"; then
    echo -e "${RED}Fehler: nginx.conf konnte nicht gefunden werden.${RESET}"
    exit 1
fi

# Erstelle .env-Datei
echo -e "${CYAN}▶ Erstelle Umgebungsvariablen-Datei...${RESET}"

# Prüfe, ob das Zielverzeichnis existiert
if [[ ! -d "${INSTALL_DIR}/docker/production" ]]; then
    echo -e "${RED}Fehler: Verzeichnis ${INSTALL_DIR}/docker/production existiert nicht.${RESET}"
    echo -e "${YELLOW}Versuche, das Verzeichnis zu erstellen...${RESET}"
    mkdir -p "${INSTALL_DIR}/docker/production" || {
        echo -e "${RED}Fehler: Konnte Verzeichnis nicht erstellen. Überprüfen Sie die Berechtigungen.${RESET}"
        exit 1
    }
fi

# Generiere zufällige Passwörter
echo -e "${CYAN}▶ Generiere Sicherheitstoken...${RESET}"

# Alternative Methode zur Generierung von zufälligen Strings, falls tr und /dev/urandom nicht verfügbar sind
generate_random_string() {
    local length=$1
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local result=""
    
    # Versuche es zuerst mit /dev/urandom
    if [[ -f /dev/urandom ]] && command -v tr &> /dev/null; then
        result=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length" || echo "")
    fi
    
    # Fallback-Methode, wenn /dev/urandom nicht funktioniert oder das Ergebnis leer ist
    if [[ -z "$result" ]]; then
        # Verwende $RANDOM (Bash-interne Funktion) und date
        for ((i=0; i<length; i++)); do
            local pos=$(( RANDOM % ${#chars} ))
            result+="${chars:$pos:1}"
        done
        
        # Füge Zeitstempel hinzu, um Vorhersehbarkeit zu vermeiden
        result="${result:0:$((length-10))}_$(date +%s)"
    fi
    
    echo "$result"
}

# DB-Passwort generieren
DB_PASSWORD=$(generate_random_string 16)
if [[ -z "$DB_PASSWORD" ]]; then
    echo -e "${RED}Fehler: Konnte kein zufälliges Datenbankpasswort generieren.${RESET}"
    echo -e "${YELLOW}Verwende Standard-Passwort...${RESET}"
    DB_PASSWORD="kormit_default_pass_$(date +%s)"
fi

# Secret Key generieren
SECRET_KEY=$(generate_random_string 32)
if [[ -z "$SECRET_KEY" ]]; then
    echo -e "${RED}Fehler: Konnte keinen zufälligen Secret Key generieren.${RESET}"
    echo -e "${YELLOW}Verwende Standard-Secret-Key...${RESET}"
    SECRET_KEY="kormit_default_key_$(date +%s)"
fi

# Bekannte korrekte Image-Pfade
BACKEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-backend:main"
FRONTEND_IMAGE="ghcr.io/kormit-panel/kormit/kormit-frontend:main"

# Erstelle .env-Datei
echo -e "${CYAN}▶ Schreibe .env-Datei...${RESET}"
ENV_FILE="${INSTALL_DIR}/docker/production/.env"

# Versuche, die .env-Datei zu erstellen
if ! cat > "$ENV_FILE" << EOL
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=kormit
SECRET_KEY=${SECRET_KEY}
DOMAIN_NAME=${DOMAIN_NAME}
TIMEZONE=UTC
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}

# Image-Konfiguration
BACKEND_IMAGE=${BACKEND_IMAGE}
FRONTEND_IMAGE=${FRONTEND_IMAGE}
EOL
then
    echo -e "${RED}Fehler: Konnte .env-Datei nicht erstellen: $ENV_FILE${RESET}"
    echo -e "${YELLOW}Überprüfen Sie die Schreibberechtigungen für dieses Verzeichnis.${RESET}"
    exit 1
fi

# Prüfe, ob die Datei erfolgreich erstellt wurde
if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}Fehler: .env-Datei wurde nicht erstellt: $ENV_FILE${RESET}"
    exit 1
fi

echo -e "${GREEN}✅ Umgebungsvariablen-Datei wurde erstellt.${RESET}"

# HTTPS-Konfiguration
if [[ "$HTTP_ONLY" = false ]]; then
    echo -e "${CYAN}▶ Aktiviere HTTPS und erstelle SSL-Zertifikat...${RESET}"
    
    # Erstelle selbstsigniertes Zertifikat
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${INSTALL_DIR}/docker/production/ssl/kormit.key" \
        -out "${INSTALL_DIR}/docker/production/ssl/kormit.crt" \
        -subj "/CN=${DOMAIN_NAME}" -addext "subjectAltName=DNS:${DOMAIN_NAME}"
    
    # Modifiziere die HTTP-Konfiguration, um auf HTTPS weiterzuleiten
    # Ersetze den HTTP-Standort-Block mit einer Umleitung zu HTTPS
    sed -i '/# HTTP-Handling - wird durch das Installationsskript konfiguriert/,/location \/ {/!b; /location \/ {/a\
        return 301 https://$host$request_uri;' "${INSTALL_DIR}/docker/production/nginx.conf"
    
    # Entferne alle Zeilen zwischen "location / {" und dem nächsten "}"
    sed -i '/# HTTP-Handling.*konfiguriert/,/location \/ {/!b; /location \/ {/,/}/{//!d}' "${INSTALL_DIR}/docker/production/nginx.conf"
    
    echo -e "${GREEN}✅ HTTPS wurde aktiviert und ein selbstsigniertes SSL-Zertifikat wurde erstellt.${RESET}"
    echo -e "${YELLOW}⚠️ Hinweis: Da es sich um ein selbstsigniertes Zertifikat handelt, werden Browser eine Warnung anzeigen.${RESET}"
else
    echo -e "${CYAN}▶ Verwende nur HTTP (kein HTTPS)...${RESET}"
    
    # Erstelle leere Zertifikatsdateien für Nginx
    touch "${INSTALL_DIR}/docker/production/ssl/kormit.key"
    touch "${INSTALL_DIR}/docker/production/ssl/kormit.crt"
    
    # Entferne den HTTPS-Port aus der docker-compose.yml
    sed -i 's/- "${HTTPS_PORT:-443}:443"/#- "${HTTPS_PORT:-443}:443"/' "${INSTALL_DIR}/docker/production/docker-compose.yml"
    
    echo -e "${GREEN}✅ HTTP-only Modus wurde konfiguriert.${RESET}"
fi

# Erstelle Hilfsskripte
echo -e "${CYAN}▶ Erstelle Management-Skripte...${RESET}"

# Start-Skript
cat > "${INSTALL_DIR}/start.sh" << 'EOL'
#!/usr/bin/env bash
cd "$(dirname "$0")/docker/production" || { echo "Konnte nicht ins Verzeichnis wechseln"; exit 1; }
docker compose up -d
echo "Kormit wurde gestartet und ist erreichbar."
EOL
chmod +x "${INSTALL_DIR}/start.sh"

# Stop-Skript
cat > "${INSTALL_DIR}/stop.sh" << 'EOL'
#!/usr/bin/env bash
cd "$(dirname "$0")/docker/production" || { echo "Konnte nicht ins Verzeichnis wechseln"; exit 1; }
docker compose down
echo "Kormit wurde gestoppt."
EOL
chmod +x "${INSTALL_DIR}/stop.sh"

# Update-Skript
cat > "${INSTALL_DIR}/update.sh" << 'EOL'
#!/usr/bin/env bash
cd "$(dirname "$0")/docker/production" || { echo "Konnte nicht ins Verzeichnis wechseln"; exit 1; }
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL
chmod +x "${INSTALL_DIR}/update.sh"

echo -e "${GREEN}✅ Management-Skripte wurden erstellt.${RESET}"

# Frage, ob Kormit direkt gestartet werden soll
echo -e "\n${CYAN}▶ Installation abgeschlossen!${RESET}"
echo -e "${YELLOW}Möchten Sie Kormit jetzt starten? (J/n)${RESET}"
read -rp "> " start_now

if [[ ! "$start_now" =~ ^[nN]$ ]]; then
    echo -e "${CYAN}▶ Starte Kormit...${RESET}"
    "${INSTALL_DIR}/start.sh"
    
    # Server-IP oder Domain anzeigen
    if [[ "$DOMAIN_NAME" = "localhost" ]]; then
        SERVER_IP=$(hostname -I | awk '{print $1}')
        ACCESS_URL="$SERVER_IP"
    else
        ACCESS_URL="$DOMAIN_NAME"
    fi
    
    echo -e "\n${GREEN}✅ Kormit wurde erfolgreich installiert und gestartet!${RESET}"
    echo -e "${CYAN}Sie können nun auf Kormit zugreifen unter:${RESET}"
    
    if [[ "$HTTP_ONLY" = true ]]; then
        echo -e "  http://${ACCESS_URL}:${HTTP_PORT}"
    else
        echo -e "  https://${ACCESS_URL}:${HTTPS_PORT}"
    fi
else
    echo -e "\n${GREEN}✅ Kormit wurde erfolgreich installiert!${RESET}"
    echo -e "${CYAN}Verwenden Sie '${INSTALL_DIR}/start.sh', um Kormit zu starten.${RESET}"
fi

echo -e "\n${YELLOW}Hinweis: Das Standard-Admin-Passwort finden Sie in der ersten Log-Ausgabe nach dem Start.${RESET}"
echo -e "${YELLOW}Verwenden Sie '${INSTALL_DIR}/update.sh', um Kormit in Zukunft zu aktualisieren.${RESET}"

exit 0