# Kormit Installationsskript für Windows
# Dieses Skript installiert Kormit auf einem Windows-Server mit Docker Desktop
# Mit Unterstützung für private Repositories

# Farbige Ausgabe
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
    Write-ColorOutput "[INFO] $Message" -Color Cyan
}

function Write-Success {
    param (
        [string]$Message
    )
    Write-ColorOutput "[SUCCESS] $Message" -Color Green
}

function Write-Warning {
    param (
        [string]$Message
    )
    Write-ColorOutput "[WARNING] $Message" -Color Yellow
}

function Write-Error {
    param (
        [string]$Message
    )
    Write-ColorOutput "[ERROR] $Message" -Color Red
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

# GitHub Container Registry-Authentifizierung konfigurieren
function Set-GitHubAuth {
    Write-Info "GitHub Container Registry Authentifizierung wird konfiguriert..."
    
    $githubAuth = Read-Host "Möchten Sie sich bei GitHub Container Registry anmelden? (j/N)"
    if ($githubAuth -eq "j" -or $githubAuth -eq "J") {
        Write-Info "GitHub Anmeldedaten werden eingerichtet..."
        
        $githubUsername = Read-Host "GitHub Benutzername"
        $githubToken = Read-Host "GitHub Personal Access Token (mit read:packages-Berechtigung)" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($githubToken)
        $githubTokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        
        if ([string]::IsNullOrEmpty($githubUsername) -or [string]::IsNullOrEmpty($githubTokenPlain)) {
            Write-Warning "Benutzername oder Token fehlt. Die Anmeldung wird übersprungen."
            return $false
        }
        
        try {
            $loginOutput = $githubTokenPlain | docker login ghcr.io -u $githubUsername --password-stdin
            Write-Success "GitHub Container Registry Anmeldung erfolgreich."
            return $true
        }
        catch {
            Write-Error "GitHub Container Registry Anmeldung fehlgeschlagen."
            Write-Warning "Die Installation wird fortgesetzt, aber Sie müssen möglicherweise manuell Anmeldedaten konfigurieren."
            return $false
        }
    }
    else {
        Write-Info "GitHub Anmeldung übersprungen. Wenn die Images privat sind, müssen Sie sich manuell anmelden."
        return $false
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
    Set-Content -Path "$Path\docker\production\docker-compose.yml" -Value $Content
    Write-Success "docker-compose.yml wurde erstellt."
}

# Nginx-Konfiguration erstellen
function New-NginxConfigFile {
    param (
        [string]$Path,
        [string]$Content
    )
    Write-Info "Erstelle nginx.conf"
    Set-Content -Path "$Path\docker\production\nginx.conf" -Value $Content
    Write-Success "nginx.conf wurde erstellt."
}

# Umgebungsvariablen-Datei erstellen
function New-EnvironmentFile {
    param (
        [string]$Path,
        [string]$DomainName = "localhost",
        [string]$TimeZone = "UTC"
    )
    Write-Info "Erstelle .env-Datei"
    
    # Zufällige Passwörter generieren
    $dbPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | % {[char]$_})
    $secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
    
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

# Image-Konfiguration
BACKEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-backend:main
FRONTEND_IMAGE=ghcr.io/kormit-panel/kormit/kormit-frontend:main
"@
    
    Set-Content -Path "$Path\docker\production\.env" -Value $envContent
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
IP.1 = 127.0.0.1
"@
    
    Set-Content -Path $openSSLPath -Value $openSSLConfig
    
    # Prüfen, ob OpenSSL verfügbar ist
    try {
        $openSSLVersion = openssl version
        Write-Info "OpenSSL gefunden: $openSSLVersion"
        
        # SSL-Zertifikat erstellen
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$certPath\kormit.key" -out "$certPath\kormit.crt" -config $openSSLPath
        
        Write-Success "Selbstsigniertes SSL-Zertifikat wurde erstellt."
    }
    catch {
        Write-Warning "OpenSSL ist nicht verfügbar. Es wird versucht, ein Windows-eigenes Zertifikat zu erstellen."
        
        try {
            # Windows-eigenes Zertifikat erstellen
            $cert = New-SelfSignedCertificate -DnsName $DomainName -CertStoreLocation "Cert:\LocalMachine\My"
            $certPassword = ConvertTo-SecureString -String "kormit" -Force -AsPlainText
            $certPath = "$Path\docker\production\ssl"
            
            # PFX exportieren
            Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$($cert.Thumbprint)" -FilePath "$certPath\kormit.pfx" -Password $certPassword
            
            # Extrahieren für Nginx
            $pfxBytes = Get-Content "$certPath\kormit.pfx" -Encoding Byte
            $pfxContent = [System.Convert]::ToBase64String($pfxBytes)
            
            # Platzhalter für Nginx erstellen
            Set-Content -Path "$certPath\kormit.key" -Value "-----BEGIN PRIVATE KEY-----`n-----END PRIVATE KEY-----"
            Set-Content -Path "$certPath\kormit.crt" -Value "-----BEGIN CERTIFICATE-----`n-----END CERTIFICATE-----"
            
            Write-Info "Sie müssen das generierte PFX-Zertifikat in die richtigen Formate für Nginx konvertieren."
            Write-Info "PFX-Passwort: kormit"
            
            Write-Success "Windows-Zertifikat wurde erstellt, muss aber manuell konvertiert werden."
        }
        catch {
            Write-Warning "Weder OpenSSL noch Windows-Zertifikatserstellung funktionierte. SSL-Zertifikate müssen manuell erstellt werden."
            Write-Info "Bitte erstellen Sie ein SSL-Zertifikat und legen Sie es unter $certPath\kormit.key und $certPath\kormit.crt ab."
            
            # Leere Zertifikatsdateien erstellen als Platzhalter
            Set-Content -Path "$certPath\kormit.key" -Value "# Platzhalter für SSL-Schlüssel"
            Set-Content -Path "$certPath\kormit.crt" -Value "# Platzhalter für SSL-Zertifikat"
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
    
    Set-Content -Path "$Path\start.ps1" -Value $startContent
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
    
    Set-Content -Path "$Path\stop.ps1" -Value $stopContent
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
    
    Set-Content -Path "$Path\update.ps1" -Value $updateContent
    Write-Success "Update-Skript wurde erstellt."
}

# Test der Docker-Images
function Test-DockerImages {
    Write-Info "Teste den Zugriff auf die Docker-Images..."
    
    try {
        docker pull ghcr.io/kormit-panel/kormit/kormit-backend:main | Out-Null
        Write-Success "Backend-Image ist verfügbar."
        $backendAvailable = $true
    }
    catch {
        Write-Warning "Backend-Image konnte nicht abgerufen werden. Überprüfen Sie Ihre Anmeldedaten."
        $backendAvailable = $false
    }
    
    try {
        docker pull ghcr.io/kormit-panel/kormit/kormit-frontend:main | Out-Null
        Write-Success "Frontend-Image ist verfügbar."
        $frontendAvailable = $true
    }
    catch {
        Write-Warning "Frontend-Image konnte nicht abgerufen werden. Überprüfen Sie Ihre Anmeldedaten."
        $frontendAvailable = $false
    }
    
    return ($backendAvailable -and $frontendAvailable)
}

# Hauptfunktion
function Install-Kormit {
    Write-ColorOutput "=== Kormit Installation für Windows ===" -Color Magenta
    
    # Prüfe Voraussetzungen
    if (-not (Test-Docker)) {
        exit 1
    }
    
    Test-DockerCompose
    
    # GitHub Container Registry-Authentifizierung
    $githubAuthConfigured = Set-GitHubAuth
    
    if ($githubAuthConfigured) {
        $imagesAvailable = Test-DockerImages
        if (-not $imagesAvailable) {
            Write-Warning "Einige Docker-Images sind nicht verfügbar. Die Installation wird trotzdem fortgesetzt."
        }
    }
    
    # Installationsverzeichnis
    $installDir = "C:\kormit"
    $currentDir = Split-Path -Parent $PSCommandPath
    
    # Frage nach dem Installationsverzeichnis
    $userInstallDir = Read-Host "Installationsverzeichnis [$installDir]"
    if ($userInstallDir) {
        $installDir = $userInstallDir
    }
    
    # Frage nach Domain-Namen
    $domainName = Read-Host "Domain-Name für Kormit [localhost]"
    if (-not $domainName) {
        $domainName = "localhost"
    }
    
    # Erstelle Verzeichnisse
    New-InstallationDirectory -Path $installDir
    
    # Erstelle Konfigurationsdateien
    $dockerComposeContent = Get-Content -Path "$currentDir\docker\production\docker-compose.yml" -Raw -ErrorAction SilentlyContinue
    if (-not $dockerComposeContent) {
        Write-Error "docker-compose.yml wurde nicht gefunden. Bitte führen Sie das Skript im Verzeichnis des Projekts aus."
        exit 1
    }
    New-DockerComposeFile -Path $installDir -Content $dockerComposeContent
    
    $nginxConfigContent = Get-Content -Path "$currentDir\docker\production\nginx.conf" -Raw -ErrorAction SilentlyContinue
    if (-not $nginxConfigContent) {
        Write-Error "nginx.conf wurde nicht gefunden. Bitte führen Sie das Skript im Verzeichnis des Projekts aus."
        exit 1
    }
    New-NginxConfigFile -Path $installDir -Content $nginxConfigContent
    
    # Zeitzone ermitteln
    $timezone = [System.TimeZoneInfo]::Local.Id
    
    New-EnvironmentFile -Path $installDir -DomainName $domainName -TimeZone $timezone
    
    # Erstelle SSL-Zertifikat
    New-SelfSignedCertificate -Path $installDir -DomainName $domainName
    
    # Erstelle Start- und Stop-Skripte
    New-StartScript -Path $installDir -DomainName $domainName
    New-StopScript -Path $installDir
    New-UpdateScript -Path $installDir
    
    # Frage, ob Kormit jetzt gestartet werden soll
    $startNow = Read-Host "Möchten Sie Kormit jetzt starten? (j/N)"
    if ($startNow -eq "j" -or $startNow -eq "J") {
        Write-Info "Kormit wird gestartet..."
        & "$installDir\start.ps1"
    }
    
    # Zusammenfassung
    Write-ColorOutput "`n=== Installation abgeschlossen ===" -Color Magenta
    Write-Success "Kormit wurde erfolgreich installiert unter: $installDir"
    Write-Info "Um Kormit zu starten, führen Sie das folgende Skript aus: $installDir\start.ps1"
    Write-Info "Um Kormit zu stoppen, führen Sie das folgende Skript aus: $installDir\stop.ps1"
    Write-Info "Um Kormit zu aktualisieren, führen Sie das folgende Skript aus: $installDir\update.ps1"
    Write-Info "Sie können auf das Dashboard unter https://$domainName zugreifen."
    Write-Warning "Für Produktionsumgebungen ersetzen Sie bitte das selbstsignierte SSL-Zertifikat durch ein gültiges Zertifikat."
}

# Starte die Installation
Install-Kormit 