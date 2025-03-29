# Beitragsrichtlinien für Kormit

Wir freuen uns über deine Unterstützung beim Kormit-Projekt! Diese Richtlinien sollen dir helfen, effektiv zum Projekt beizutragen.

## Code of Conduct

Wir erwarten von allen Mitwirkenden einen respektvollen Umgang miteinander. Bitte halte dich an die folgenden Grundprinzipien:

- Respektiere andere Beitragende, unabhängig von ihrer Erfahrung oder ihren Ansichten
- Gib konstruktives Feedback und sei offen für Feedback zu deiner eigenen Arbeit
- Konzentriere dich auf die bestmögliche Lösung für die Benutzer von Kormit

## Wie du beitragen kannst

Es gibt viele Möglichkeiten, zum Projekt beizutragen:

1. **Fehler melden**: Erstelle einen Issue, wenn du einen Bug findest
2. **Feature-Anfragen**: Schlage neue Funktionen vor, die Kormit verbessern würden
3. **Dokumentation**: Hilf bei der Verbesserung oder Übersetzung der Dokumentation
4. **Code beitragen**: Reiche Pull Requests ein, um Fehler zu beheben oder neue Funktionen zu implementieren

## Entwicklungsprozess

### Einrichtung der Entwicklungsumgebung

1. Klone das Repository:
   ```bash
   git clone https://github.com/yourusername/kormit.git
   cd kormit
   ```

2. Starte die Entwicklungsumgebung:
   ```bash
   build run-dev
   ```

### Branching-Strategie

- Der `main`-Branch ist immer stabil und bereit für Releases
- Entwicklung findet in Feature-Branches statt
- Benenne deine Branches nach dem folgenden Schema:
  - `feature/kurze-beschreibung` für neue Features
  - `fix/kurze-beschreibung` für Bugfixes
  - `docs/kurze-beschreibung` für Dokumentationsänderungen

### Pull Requests

1. Stelle sicher, dass dein Code den Stil-Richtlinien entspricht
2. Schreibe Tests für neue Funktionen oder Bugfixes
3. Aktualisiere bei Bedarf die Dokumentation
4. Reiche deinen Pull Request ein
5. Beschreibe klar die Änderungen und den Zweck deines PRs

## Stil-Richtlinien

### Go-Code

- Formatiere deinen Go-Code mit `go fmt`
- Folge den [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Verwende aussagekräftige Variablen- und Funktionsnamen
- Kommentiere deinen Code, besonders bei komplexer Logik

### JavaScript/Vue.js-Code

- Verwende ESLint und Prettier für konsistente Formatierung
- Folge dem Vue.js Stil-Guide
- Bevorzuge moderne ES6+-Syntax
- Sorge für ausreichende Kommentierung komplexer Logik

## Teststrategie

- Schreibe Unit-Tests für Backend-Funktionen
- Schreibe Komponententests für Frontend-Komponenten
- Ziel ist eine Testabdeckung von mindestens 70%

## Versionsmanagement

Wir folgen [Semantic Versioning](https://semver.org/):

- **MAJOR** Version: Inkompatible API-Änderungen
- **MINOR** Version: Neue Funktionen (abwärtskompatibel)
- **PATCH** Version: Bugfixes (abwärtskompatibel)

## Release-Prozess

1. Code wird in den `main`-Branch gemergt
2. Tests werden automatisch durchgeführt
3. Bei Erfolg werden Docker-Images erstellt und zu Docker Hub gepusht
4. Release-Tags werden erstellt und auf GitHub veröffentlicht

## Fragen?

Wenn du Fragen hast oder Hilfe benötigst, erstelle einen Issue mit dem Label "question" oder kontaktiere einen der Maintainer direkt.

Vielen Dank für deine Beiträge! 