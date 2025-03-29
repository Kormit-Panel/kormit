# Kormit-Installation
install_kormit() {
    log_section "Kormit wird installiert"
    
    # Interaktive Konfiguration, falls nicht über Parameter übergeben und nicht --yes gesetzt
    if [ "$INSTALL_DIR" = "/opt/kormit" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "Installationsverzeichnis [/opt/kormit]: " user_install_dir
        if [ -n "$user_install_dir" ]; then
            INSTALL_DIR="$user_install_dir"
        fi
    fi
    
    if [ "$DOMAIN_NAME" = "localhost" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "Domain-Name (oder IP-Adresse) [localhost]: " user_domain
        if [ -n "$user_domain" ]; then
            DOMAIN_NAME="$user_domain"
        fi
    fi
    
    if [ "$HTTP_PORT" = "80" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "HTTP-Port [80]: " user_http_port
        if [ -n "$user_http_port" ]; then
            HTTP_PORT="$user_http_port"
        fi
    fi
    
    if [ "$HTTPS_PORT" = "443" ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "HTTPS-Port [443]: " user_https_port
        if [ -n "$user_https_port" ]; then
            HTTPS_PORT="$user_https_port"
        fi
    fi
    
    log_debug "Installationsverzeichnis: $INSTALL_DIR"
    log_debug "Domain-Name: $DOMAIN_NAME"
    log_debug "HTTP-Port: $HTTP_PORT"
    log_debug "HTTPS-Port: $HTTPS_PORT"
    
    # Installationsverzeichnis erstellen
    log_debug "Erstelle Installationsverzeichnis $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
    cd $INSTALL_DIR
    
    # Produktionskonfiguration erstellen
    log_info "Konfigurationsdateien werden erstellt..."
    
    log_debug "Erstelle Verzeichnisstruktur"
    mkdir -p docker/production
    mkdir -p docker/production/ssl
    mkdir -p docker/production/logs
    
    log_debug "Schritt: Erstelle docker-compose.yml"
    # Docker Compose-Datei direkt erstellen, statt zu versuchen, eine zu kopieren
    cat > docker/production/docker-compose.yml <<EOL
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: \${VOLUME_PREFIX}-db
    restart: always
    environment:
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: \${DB_NAME}
      TZ: \${TIMEZONE}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - kormit-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER} -d \${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: \${BACKEND_IMAGE}
    container_name: \${VOLUME_PREFIX}-backend
    restart: always
    environment:
      DATABASE_URL: postgresql://\${DB_USER}:\${DB_PASSWORD}@db:5432/\${DB_NAME}
      SECRET_KEY: \${SECRET_KEY}
      DOMAIN_NAME: \${DOMAIN_NAME}
      TZ: \${TIMEZONE}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - kormit-net

  frontend:
    image: \${FRONTEND_IMAGE}
    container_name: \${VOLUME_PREFIX}-frontend
    restart: always
    environment:
      BACKEND_URL: http://backend:8000
      TZ: \${TIMEZONE}
    depends_on:
      - backend
    networks:
      - kormit-net

  nginx:
    image: nginx:alpine
    container_name: \${VOLUME_PREFIX}-nginx
    restart: always
    ports:
      - "\${HTTP_PORT}:80"
      - "\${HTTPS_PORT}:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
      - ./logs:/var/log/nginx
    depends_on:
      - frontend
      - backend
    networks:
      - kormit-net

networks:
  kormit-net:
    name: \${NETWORK_NAME}

volumes:
  db_data:
    name: \${VOLUME_PREFIX}-db-data
EOL
    
    log_debug "Schritt: Erstelle nginx.conf"
    # Nginx-Konfiguration direkt erstellen, statt zu versuchen, eine zu kopieren
    cat > docker/production/nginx.conf <<EOL
server {
    listen 80;
    server_name \${DOMAIN_NAME};
    
    # HTTP zu HTTPS umleiten
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name \${DOMAIN_NAME};

    # SSL-Konfiguration
    ssl_certificate /etc/nginx/ssl/kormit.crt;
    ssl_certificate_key /etc/nginx/ssl/kormit.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;

    # Frontend
    location / {
        proxy_pass http://frontend:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Backend API
    location /api {
        proxy_pass http://backend:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Für WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOL
    
    log_debug "Schritt: Generiere Passwörter"
    # Zufällige Passwörter generieren
    DB_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
    SECRET_KEY=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
    
    log_debug "Schritt: Ermittle Timezone"
    # Timezone ermitteln
    TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
    
    log_debug "Schritt: Erstelle .env"
    # Umgebungsvariablen-Datei erstellen
    cat > docker/production/.env <<EOL
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=$DB_PASSWORD
DB_NAME=kormit
SECRET_KEY=$SECRET_KEY
DOMAIN_NAME=$DOMAIN_NAME
TIMEZONE=$TIMEZONE
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT

# Image-Konfiguration
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:latest
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:latest
EOL
    
    log_debug "Schritt: Erstelle SSL-Zertifikat"
    # Self-signed Zertifikat für die erste Einrichtung erstellen
    log_info "Selbstsigniertes SSL-Zertifikat wird erstellt..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout docker/production/ssl/kormit.key \
        -out docker/production/ssl/kormit.crt \
        -subj "/C=DE/ST=State/L=City/O=Organization/CN=$DOMAIN_NAME" \
        -addext "subjectAltName=DNS:$DOMAIN_NAME,IP:127.0.0.1"
    
    chmod 600 docker/production/ssl/kormit.key
    
    log_debug "Schritt: Erstelle Start-Skript"
    # Start-Skript erstellen
    cat > start.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist unter https://$DOMAIN_NAME erreichbar."
EOL
    
    chmod +x start.sh
    
    log_debug "Schritt: Erstelle Stop-Skript"
    # Stop-Skript erstellen
    cat > stop.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose down
echo "Kormit wurde gestoppt."
EOL
    
    chmod +x stop.sh
    
    log_debug "Schritt: Erstelle Update-Skript"
    # Update-Skript erstellen
    cat > update.sh <<EOL
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose pull
docker compose up -d
echo "Kormit wurde aktualisiert."
EOL
    
    chmod +x update.sh
    
    log_success "Kormit wurde erfolgreich installiert."
    log_info "Sie können Kormit mit dem Befehl '$INSTALL_DIR/start.sh' starten."
    
    # Automatischen Start ausführen, falls konfiguriert
    if [ "$AUTO_START" = true ]; then
        log_info "Kormit wird gestartet..."
        $INSTALL_DIR/start.sh
    else
        # Automatischen Start anbieten, wenn nicht bereits per Parameter festgelegt und nicht --yes gesetzt
        if [ "$SKIP_CONFIRM" = false ]; then
            read -p "Möchten Sie Kormit jetzt starten? (j/N): " start_now
            if [[ "$start_now" =~ ^[jJ]$ ]]; then
                log_info "Kormit wird gestartet..."
                $INSTALL_DIR/start.sh
            fi
        fi
    fi
}