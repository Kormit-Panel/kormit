#!/bin/bash
# Dieses Skript korrigiert das Start-Skript von Kormit

# Prüfen, ob das Skript als Root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo "Dieses Skript muss als Root ausgeführt werden."
    exit 1
fi

# Pfad zum start.sh
SCRIPT_PATH="/opt/kormit/start.sh"

if [ -f "$SCRIPT_PATH" ]; then
    # Sichern des alten Skripts
    cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak"
    
    # Neues korrektes Skript erstellen
    cat > "$SCRIPT_PATH" << EOT
#!/bin/bash
cd \$(dirname \$0)/docker/production
docker compose up -d
echo "Kormit wurde gestartet und ist unter http://localhost erreichbar."
EOT
    
    # Ausführbar machen
    chmod +x "$SCRIPT_PATH"
    
    echo "Das Start-Skript wurde erfolgreich korrigiert."
    echo "Sie können Kormit jetzt mit '$SCRIPT_PATH' starten."
else
    echo "Fehler: Die Datei $SCRIPT_PATH wurde nicht gefunden."
    exit 1
fi 