# Docker Hub Einrichtung für GitHub Actions

Diese Anleitung beschreibt, wie Du die erforderlichen Secrets für die Veröffentlichung von Docker Images auf Docker Hub einrichtest.

## Voraussetzungen

1. Ein Docker Hub Konto (kostenlos oder kostenpflichtig)
2. Ein GitHub Repository mit den Kormit-Dateien

## Schritt 1: Erstelle einen Docker Hub Access Token

1. Melde Dich bei [Docker Hub](https://hub.docker.com) an
2. Klicke auf Deinen Benutzernamen in der oberen rechten Ecke und wähle "Account Settings"
3. Wechsle zum Tab "Security"
4. Klicke auf "New Access Token"
5. Gib einen Namen für den Token ein (z.B. "GitHub Actions")
6. Wähle einen geeigneten Ablaufzeitraum (z.B. 1 Jahr)
7. Klicke auf "Generate"
8. **Wichtig**: Kopiere den Token und speichere ihn sicher. Er wird nur einmal angezeigt!

## Schritt 2: Erstelle die GitHub Repository Secrets

1. Gehe zu Deinem GitHub Repository
2. Klicke auf "Settings" > "Secrets and variables" > "Actions"
3. Klicke auf "New repository secret"
4. Erstelle die folgenden Secrets:

| Name | Wert |
|------|------|
| `DOCKERHUB_USERNAME` | Dein Docker Hub Benutzername |
| `DOCKERHUB_TOKEN` | Der im vorherigen Schritt generierte Access Token |

5. Klicke jeweils auf "Add secret"

## Schritt 3: Erstelle die Docker Hub Repositories

Bevor Du den Workflow ausführst, solltest Du die erforderlichen Repositories auf Docker Hub erstellen:

1. Melde Dich bei [Docker Hub](https://hub.docker.com) an
2. Klicke auf "Create Repository"
3. Erstelle die folgenden Repositories:
   - `kormit/kormit-backend`
   - `kormit/kormit-frontend`
   
   Hinweis: Ersetze `kormit` durch Deinen Docker Hub Benutzernamen oder den Namen Deiner Organisation.
   
4. Stelle sicher, dass die Repositories öffentlich sind, damit andere Benutzer darauf zugreifen können

## Schritt 4: Passe den Workflow an

Wenn Du einen anderen Namen für Deine Docker Hub Repositories verwendest als `kormit/kormit-backend` und `kormit/kormit-frontend`, musst Du diese Namen im Workflow anpassen:

1. Öffne die Datei `.github/workflows/build.yml`
2. Suche nach allen Vorkommen von `kormit/kormit-backend` und `kormit/kormit-frontend`
3. Ersetze sie durch Deine Repository-Namen

## Schritt 5: Führe den Workflow aus

Der Workflow wird automatisch ausgeführt, wenn Du Code in die Branches `main` oder `master` pushst oder einen Pull Request erstellst.

Um den Workflow manuell auszuführen:

1. Gehe zu Deinem GitHub Repository
2. Klicke auf den Tab "Actions"
3. Wähle den Workflow "Build and Push Docker Images"
4. Klicke auf "Run workflow"
5. Wähle den Branch aus und klicke auf "Run workflow"

## Fehlerbehebung

Wenn der Workflow fehlschlägt, überprüfe die folgenden häufigen Probleme:

- Die Secrets `DOCKERHUB_USERNAME` und `DOCKERHUB_TOKEN` sind nicht korrekt konfiguriert
- Der Docker Hub Access Token ist abgelaufen
- Die Docker Hub Repositories existieren nicht oder haben einen anderen Namen
- Dein Docker Hub Konto hat keine Berechtigung zum Pushen in die angegebenen Repositories

Für weitere Hilfe, siehe die [Docker Hub Dokumentation](https://docs.docker.com/docker-hub/) und die [GitHub Actions Dokumentation](https://docs.github.com/en/actions). 