# Kormit Schnellstart-Skript für Windows

# Basis-URL zum Kormit-Repository
$RepoUrl = "https://raw.githubusercontent.com/kormit-panel/kormit/main/deploy"

# Farbige Ausgaben
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

# Header anzeigen
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                 KORMIT SCHNELLSTART                        ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Prüfen, ob Kormit installiert ist
$possiblePaths = @("C:\kormit", "$env:USERPROFILE\kormit", "D:\kormit")
$installedPath = $null

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $installedPath = $path
        break
    }
}

if (-not $installedPath) {
    Write-Warning "Kormit scheint nicht installiert zu sein."
    $installNow = Read-Host "Möchten Sie Kormit jetzt installieren? (j/N)"
    
    if ($installNow -match "^[jJ]$") {
        Write-Info "Starte den Installer..."
        $installScript = "$env:TEMP\kormit_install.ps1"
        Invoke-WebRequest -Uri "$RepoUrl/scripts/install_curl.ps1" -OutFile $installScript
        & $installScript
        Remove-Item $installScript -Force
        exit 0
    } else {
        Write-Error "Installation abgebrochen."
        exit 1
    }
}

# Wenn wir hier sind, wurde entweder Kormit gefunden oder gerade installiert
if (-not $installedPath) {
    $installedPath = Read-Host "Bitte geben Sie den Pfad zu Ihrem Kormit-Installationsverzeichnis ein"
    
    if (-not (Test-Path $installedPath)) {
        Write-Error "Das angegebene Verzeichnis existiert nicht: $installedPath"
        exit 1
    }
}

# Menü anzeigen
Write-Host "Kormit-Verwaltung" -ForegroundColor Blue
Write-Host "1) Kormit starten"
Write-Host "2) Kormit stoppen"
Write-Host "3) Kormit aktualisieren"
Write-Host "4) Status anzeigen"
Write-Host "5) Beenden"

$option = Read-Host "Wählen Sie eine Option (1-5)"

switch ($option) {
    "1" {
        Write-Info "Kormit wird gestartet..."
        & "$installedPath\start.ps1"
        Write-Success "Kormit wurde gestartet."
    }
    "2" {
        Write-Info "Kormit wird gestoppt..."
        & "$installedPath\stop.ps1"
        Write-Success "Kormit wurde gestoppt."
    }
    "3" {
        Write-Info "Kormit wird aktualisiert..."
        & "$installedPath\update.ps1"
        Write-Success "Kormit wurde aktualisiert."
    }
    "4" {
        Write-Info "Kormit-Status wird angezeigt..."
        Push-Location "$installedPath\docker\production"
        docker compose ps
        Pop-Location
    }
    "5" {
        Write-Info "Auf Wiedersehen!"
        exit 0
    }
    default {
        Write-Error "Ungültige Option."
        exit 1
    }
} 