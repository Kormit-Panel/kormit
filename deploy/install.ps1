# Kormit Installationsskript für Windows
# Dieses Skript installiert Kormit auf einem Windows-Server mit Docker Desktop

# Version
$Version = "1.0.0"

param (
    [string]$InstallDir = "C:\kormit",
    [string]$DomainName = "localhost",
    [string]$HttpPort = "80",
    [string]$HttpsPort = "443",
    [switch]$AutoStart,
    [switch]$Yes,
    [switch]$Debug,
    [switch]$Help
)

# Hilfe anzeigen
if ($Help) {
    Write-Host "Kormit Installer v$Version"
    Write-Host ""
    Write-Host "Verwendung: .\install.ps1 [Optionen]"
    Write-Host "Optionen:"
    Write-Host "  -InstallDir DIR           Installationsverzeichnis (Standard: C:\kormit)"
    Write-Host "  -DomainName DOMAIN        Domain-Name (Standard: localhost)"
    Write-Host "  -HttpPort PORT            HTTP-Port (Standard: 80)"
    Write-Host "  -HttpsPort PORT           HTTPS-Port (Standard: 443)"
    Write-Host "  -AutoStart                Kormit nach der Installation automatisch starten"
    Write-Host "  -Yes                      Alle Fragen automatisch mit Ja beantworten"
    Write-Host "  -Debug                    Aktiviere Debug-Ausgaben"
    Write-Host "  -Help                     Diese Hilfe anzeigen"
    Write-Host ""
    Write-Host "Beispiel:"
    Write-Host "  .\install.ps1 -DomainName example.com -InstallDir D:\kormit -AutoStart"
    exit 0
}

# Farbige Ausgabe und Unicode-Symbole
function Write-ColorOutput {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info {
    param (
        [string]$Message
    )
    Write-ColorOutput "ℹ️  $Message" -Color Cyan
}

function Write-Success {
    param (
        [string]$Message
    )
    Write-ColorOutput "✅ $Message" -Color Green
}

function Write-Warning {
    param (
        [string]$Message
    )
    Write-ColorOutput "⚠️  $Message" -Color Yellow
}

function Write-Error {
    param (
        [string]$Message
    )
    Write-ColorOutput "❌ $Message" -Color Red
}

function Write-Section {
    param (
        [string]$Title
    )
    
    Write-Host ""
    Write-Host "▶️  $Title" -ForegroundColor Magenta
    Write-Host ("   " + ("-" * 50)) -ForegroundColor Magenta
}

function Write-Debug {
    param (
        [string]$Message
    )
    
    if ($Debug) {
        Write-Host "🔍 [DEBUG] $Message" -ForegroundColor DarkGray
    }
}

# Prüfe Administrator-Rechte
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Error "Dieses Skript muss als Administrator ausgeführt werden."
    exit 1
}

# Docker prüfen
function Test-Docker {
    try {
        $dockerVersion = docker --version
        Write-Success "Docker ist installiert: $dockerVersion"
        return $true
    }
    catch {
        Write-Error "Docker ist nicht installiert oder kann nicht gefunden werden."
        Write-Info "Bitte installieren Sie Docker Desktop von https://www.docker.com/products/docker-desktop"
        return $false
    }
}

# Docker Compose prüfen
function Test-DockerCompose {
    try {
        $dockerComposeVersion = docker compose version
        Write-Success "Docker Compose Plugin ist bereits installiert."
        return $true
    }
    catch {
        try {
            $dockerComposeVersion = docker-compose --version
            Write-Success "Docker Compose Legacy ist bereits installiert."
            return $true
        }
        catch {
            Write-Warning "Docker Compose scheint nicht verfügbar zu sein."
            Write-Info "In neueren Docker Desktop-Versionen ist Docker Compose jedoch integriert. Wir fahren fort."
            return $true
        }
    }
}

# Installationsverzeichnis erstellen
function New-InstallationDirectory {
    param (
        [string]$Path
    )
    Write-Info "Erstelle Installationsverzeichnis: $Path"
    
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
    
    # Unterverzeichnisse erstellen
    New-Item -Path "$Path\docker\production\ssl" -ItemType Directory -Force | Out-Null
    New-Item -Path "$Path\docker\production\logs" -ItemType Directory -Force | Out-Null
    
    Write-Success "Verzeichnisse wurden erstellt."
}

# Docker Compose-Datei erstellen
function New-DockerComposeFile {
    param (
        [string]$Path,
        [string]$Content
    )
    Write-Info "Erstelle docker-compose.yml"
    Write-Debug "Speichere docker-compose.yml in $Path\docker\production\docker-compose.yml"
    Set-Content -Path "$Path\docker\production\docker-compose.yml" -Value $Content -Encoding UTF8
    Write-Success "docker-compose.yml wurde erstellt."
}

# Nginx-Konfiguration erstellen
function New-NginxConfigFile {
    param (
        [string]$Path,
        [string]$Content
    )
    Write-Info "Erstelle nginx.conf"
    Write-Debug "Speichere nginx.conf in $Path\docker\production\nginx.conf"
    Set-Content -Path "$Path\docker\production\nginx.conf" -Value $Content -Encoding UTF8
    Write-Success "nginx.conf wurde erstellt."
}

# Umgebungsvariablen-Datei erstellen
function New-EnvironmentFile {
    param (
        [string]$Path,
        [string]$DomainName = "localhost",
        [string]$TimeZone = "UTC",
        [string]$HttpPort = "80",
        [string]$HttpsPort = "443"
    )
    Write-Info "Erstelle .env-Datei"
    
    # Zufällige Passwörter generieren
    $dbPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})
    $secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
    
    Write-Debug "Domain: $DomainName, Timezone: $TimeZone, HTTP-Port: $HttpPort, HTTPS-Port: $HttpsPort"
    
    $envContent = @"
# Kormit-Konfiguration
DB_USER=kormit_user
DB_PASSWORD=$dbPassword
DB_NAME=kormit
SECRET_KEY=$secretKey
DOMAIN_NAME=$DomainName
TIMEZONE=$TimeZone
VOLUME_PREFIX=kormit
NETWORK_NAME=kormit-network
HTTP_PORT=$HttpPort
HTTPS_PORT=$HttpsPort

# Image-Konfiguration
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:latest
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:latest
"@
    
    Write-Debug "Speichere .env-Datei in $Path\docker\production\.env"
    Set-Content -Path "$Path\docker\production\.env" -Value $envContent -Encoding UTF8
    Write-Success ".env-Datei wurde erstellt."
}

# SSL-Zertifikat erstellen
function New-SelfSignedCertificate {
    param (
        [string]$Path,
        [string]$DomainName = "localhost"
    )
    Write-Info "Erstelle selbstsigniertes SSL-Zertifikat"
    
    $certPath = "$Path\docker\production\ssl"
    $openSSLPath = "$Path\docker\production\ssl\openssl.cnf"
    
    Write-Debug "Zertifikatspfad: $certPath"
    Write-Debug "Domain: $DomainName"
    
    # OpenSSL-Konfigurationsdatei erstellen
    $openSSLConfig = @"
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = DE
ST = State
L = City
O = Organization
CN = $DomainName

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DomainName
DNS.2 = localhost
IP.1 = 127.0.0.1
"@
    
    Set-Content -Path $openSSLPath -Value $openSSLConfig -Encoding UTF8
    
    # Prüfen, ob OpenSSL verfügbar ist
    try {
        $openSSLVersion = openssl version
        Write-Info "OpenSSL gefunden: $openSSLVersion"
        
        # SSL-Zertifikat erstellen
        Write-Debug "Erstelle SSL-Zertifikat mit OpenSSL"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
            -keyout "$certPath\kormit.key" `
            -out "$certPath\kormit.crt" `
            -config $openSSLPath `
            -sha256
        
        Write-Success "Selbstsigniertes SSL-Zertifikat wurde erstellt."
    }
    catch {
        Write-Warning "OpenSSL ist nicht verfügbar. Es wird versucht, ein Windows-eigenes Zertifikat zu erstellen."
        
        try {
            # Windows-eigenes Zertifikat erstellen
            Write-Debug "Erstelle Windows-eigenes Zertifikat"
            $cert = New-SelfSignedCertificate -DnsName $DomainName -CertStoreLocation "Cert:\LocalMachine\My"
            $certPassword = ConvertTo-SecureString -String "kormit" -Force -AsPlainText
            
            # PFX exportieren
            Write-Debug "Exportiere PFX-Datei"
            Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$($cert.Thumbprint)" -FilePath "$certPath\kormit.pfx" -Password $certPassword
            
            # Extrahieren für Nginx
            $pfxBytes = Get-Content "$certPath\kormit.pfx" -Encoding Byte
            $pfxContent = [System.Convert]::ToBase64String($pfxBytes)
            
            # Platzhalter für Nginx erstellen
            Write-Debug "Erstelle Platzhalter für Nginx-Zertifikate"
            Set-Content -Path "$certPath\kormit.key" -Value "-----BEGIN PRIVATE KEY-----`n-----END PRIVATE KEY-----" -Encoding UTF8
            Set-Content -Path "$certPath\kormit.crt" -Value "-----BEGIN CERTIFICATE-----`n-----END CERTIFICATE-----" -Encoding UTF8
            
            Write-Info "Sie müssen das generierte PFX-Zertifikat in die richtigen Formate für Nginx konvertieren."
            Write-Info "PFX-Passwort: kormit"
            
            Write-Success "Windows-Zertifikat wurde erstellt, muss aber manuell konvertiert werden."
        }
        catch {
            Write-Warning "Weder OpenSSL noch Windows-Zertifikatserstellung funktionierte. SSL-Zertifikate müssen manuell erstellt werden."
            Write-Info "Bitte erstellen Sie ein SSL-Zertifikat und legen Sie es unter $certPath\kormit.key und $certPath\kormit.crt ab."
            
            # Leere Zertifikatsdateien erstellen als Platzhalter
            Write-Debug "Erstelle leere Platzhalter für Zertifikate"
            Set-Content -Path "$certPath\kormit.key" -Value "# Platzhalter für SSL-Schlüssel" -Encoding UTF8
            Set-Content -Path "$certPath\kormit.crt" -Value "# Platzhalter für SSL-Zertifikat" -Encoding UTF8
        }
    }
    
    # OpenSSL-Konfigurationsdatei entfernen
    Remove-Item -Path $openSSLPath -Force -ErrorAction SilentlyContinue
}

# Start-Skript erstellen
function New-StartScript {
    param (
        [string]$Path,
        [string]$DomainName = "localhost"
    )
    Write-Info "Erstelle Start-Skript"
    
    $startContent = @"
# Kormit Start-Skript
Write-Host "Starte Kormit..." -ForegroundColor Cyan
Set-Location -Path `$PSScriptRoot\docker\production
docker compose up -d
Write-Host "Kormit wurde gestartet. Sie können auf das Dashboard unter https://$DomainName zugreifen." -ForegroundColor Green
"@
    
    Write-Debug "Speichere start.ps1 in $Path\start.ps1"
    Set-Content -Path "$Path\start.ps1" -Value $startContent -Encoding UTF8
    Write-Success "Start-Skript wurde erstellt."
}

# Stop-Skript erstellen
function New-StopScript {
    param (
        [string]$Path
    )
    Write-Info "Erstelle Stop-Skript"
    
    $stopContent = @"
# Kormit Stop-Skript
Write-Host "Stoppe Kormit..." -ForegroundColor Cyan
Set-Location -Path `$PSScriptRoot\docker\production
docker compose down
Write-Host "Kormit wurde gestoppt." -ForegroundColor Green
"@
    
    Write-Debug "Speichere stop.ps1 in $Path\stop.ps1"
    Set-Content -Path "$Path\stop.ps1" -Value $stopContent -Encoding UTF8
    Write-Success "Stop-Skript wurde erstellt."
}

# Update-Skript erstellen
function New-UpdateScript {
    param (
        [string]$Path
    )
    Write-Info "Erstelle Update-Skript"
    
    $updateContent = @"
# Kormit Update-Skript
Write-Host "Aktualisiere Kormit..." -ForegroundColor Cyan
Set-Location -Path `$PSScriptRoot\docker\production
docker compose pull
docker compose up -d
Write-Host "Kormit wurde aktualisiert." -ForegroundColor Green
"@
    
    Write-Debug "Speichere update.ps1 in $Path\update.ps1"
    Set-Content -Path "$Path\update.ps1" -Value $updateContent -Encoding UTF8
    Write-Success "Update-Skript wurde erstellt."
}

# Hauptfunktion
function Install-Kormit {
    Clear-Host
    
    # Titelblock
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                 KORMIT INSTALLER v$Version                  ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Section "System wird vorbereitet"
    
    # Prüfe Voraussetzungen
    if (-not (Test-Docker)) {
        exit 1
    }
    
    Test-DockerCompose
    
    Write-Section "Konfiguration"
    
    # Installationsverzeichnis - falls nicht als Parameter übergeben und nicht -Yes
    $currentDir = Split-Path -Parent $PSCommandPath
    Write-Debug "Skriptverzeichnis: $currentDir"
    
    # Frage nach dem Installationsverzeichnis, falls nicht als Parameter übergeben
    if ($InstallDir -eq "C:\kormit" -and -not $Yes) {
        $userInstallDir = Read-Host "Installationsverzeichnis [$InstallDir]"
        if ($userInstallDir) {
            $InstallDir = $userInstallDir
        }
    }
    
    # Frage nach Domain-Namen, falls nicht als Parameter übergeben
    if ($DomainName -eq "localhost" -and -not $Yes) {
        $userDomain = Read-Host "Domain-Name für Kormit [$DomainName]"
        if ($userDomain) {
            $DomainName = $userDomain
        }
    }
    
    # Frage nach HTTP-Port, falls nicht als Parameter übergeben
    if ($HttpPort -eq "80" -and -not $Yes) {
        $userHttpPort = Read-Host "HTTP-Port [$HttpPort]"
        if ($userHttpPort) {
            $HttpPort = $userHttpPort
        }
    }
    
    # Frage nach HTTPS-Port, falls nicht als Parameter übergeben
    if ($HttpsPort -eq "443" -and -not $Yes) {
        $userHttpsPort = Read-Host "HTTPS-Port [$HttpsPort]"
        if ($userHttpsPort) {
            $HttpsPort = $userHttpsPort
        }
    }
    
    Write-Debug "Installationsverzeichnis: $InstallDir"
    Write-Debug "Domain-Name: $DomainName"
    Write-Debug "HTTP-Port: $HttpPort"
    Write-Debug "HTTPS-Port: $HttpsPort"
    
    Write-Section "Installation"
    
    # Erstelle Verzeichnisse
    New-InstallationDirectory -Path $InstallDir
    
    # Erstelle Konfigurationsdateien
    $dockerComposeContent = Get-Content -Path "$currentDir\docker\production\docker-compose.yml" -Raw -ErrorAction SilentlyContinue
    if (-not $dockerComposeContent) {
        Write-Error "docker-compose.yml wurde nicht gefunden. Bitte führen Sie das Skript im Verzeichnis des Projekts aus."
        exit 1
    }
    New-DockerComposeFile -Path $InstallDir -Content $dockerComposeContent
    
    $nginxConfigContent = Get-Content -Path "$currentDir\docker\production\nginx.conf" -Raw -ErrorAction SilentlyContinue
    if (-not $nginxConfigContent) {
        Write-Error "nginx.conf wurde nicht gefunden. Bitte führen Sie das Skript im Verzeichnis des Projekts aus."
        exit 1
    }
    New-NginxConfigFile -Path $InstallDir -Content $nginxConfigContent
    
    # Zeitzone ermitteln
    $timezone = [System.TimeZoneInfo]::Local.Id
    Write-Debug "Lokale Zeitzone: $timezone"
    
    New-EnvironmentFile -Path $InstallDir -DomainName $DomainName -TimeZone $timezone -HttpPort $HttpPort -HttpsPort $HttpsPort
    
    # Erstelle SSL-Zertifikat
    New-SelfSignedCertificate -Path $InstallDir -DomainName $DomainName
    
    # Erstelle Start- und Stop-Skripte
    New-StartScript -Path $InstallDir -DomainName $DomainName
    New-StopScript -Path $InstallDir
    New-UpdateScript -Path $InstallDir
    
    # Kormit starten, falls gewünscht
    if ($AutoStart) {
        Write-Info "Kormit wird automatisch gestartet..."
        & "$InstallDir\start.ps1"
    } elseif (-not $Yes) {
        # Frage, ob Kormit jetzt gestartet werden soll
        $startNow = Read-Host "Möchten Sie Kormit jetzt starten? (j/N)"
        if ($startNow -eq "j" -or $startNow -eq "J") {
            Write-Info "Kormit wird gestartet..."
            & "$InstallDir\start.ps1"
        }
    }
    
    # Zusammenfassung
    Write-Section "Installation abgeschlossen"
    Write-Success "Kormit wurde erfolgreich installiert unter: $InstallDir"
    Write-Info "Um Kormit zu starten, führen Sie das folgende Skript aus: $InstallDir\start.ps1"
    Write-Info "Um Kormit zu stoppen, führen Sie das folgende Skript aus: $InstallDir\stop.ps1"
    Write-Info "Um Kormit zu aktualisieren, führen Sie das folgende Skript aus: $InstallDir\update.ps1"
    Write-Info "Sie können auf das Dashboard unter https://$DomainName zugreifen."
    Write-Warning "Für Produktionsumgebungen ersetzen Sie bitte das selbstsignierte SSL-Zertifikat durch ein gültiges Zertifikat."
}

# Starte die Installation
Install-Kormit 