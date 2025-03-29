# Kormit Curl Installer für Windows
# Dieses Skript erlaubt die Installation von Kormit direkt über PowerShell

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

# Header anzeigen
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                 KORMIT CURL INSTALLER                      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-ColorOutput "Lade Kormit Installationsskript herunter..." -Color Green
Write-Host "Sie können den HTTP-only-Modus mit -HttpOnly aktivieren, wenn Sie kein HTTPS benötigen." -ForegroundColor Blue

# Temporärer Dateiname für das Installationsskript
$installScript = "$env:TEMP\kormit_install.ps1"

# Installationsskript herunterladen
Invoke-WebRequest -Uri "$RepoUrl/install.ps1" -OutFile $installScript

# Parameter an das Skript weiterleiten und ausführen
$argumentList = $args
if ($argumentList.Count -gt 0) {
    & $installScript $argumentList
} else {
    & $installScript
}

# Aufräumen
Remove-Item $installScript -Force

Write-ColorOutput "Installation abgeschlossen!" -Color Green 