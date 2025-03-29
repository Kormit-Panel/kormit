# GitHub Workflows 
 
Dieses Verzeichnis enthält GitHub Actions Workflows für CI/CD.
 
## Workflows 
 
- `ci.yml` - Run tests and linting on PRs 
- `build.yml` - Baut Docker Images und veröffentlicht sie auf GitHub Container Registry

Docker Images werden unter den folgenden Tags veröffentlicht:

- `ghcr.io/kormit-panel/kormit/kormit-backend:latest` - Neueste Version des Backends
- `ghcr.io/kormit-panel/kormit/kormit-frontend:latest` - Neueste Version des Frontends
- `ghcr.io/kormit-panel/kormit/kormit-backend:sha-xxxxxxxx` - Backend Version für spezifischen Commit
- `ghcr.io/kormit-panel/kormit/kormit-frontend:sha-xxxxxxxx` - Frontend Version für spezifischen Commit
- `ghcr.io/kormit-panel/kormit/kormit-backend:v1.x.x` - Backend Version für Release Tags
- `ghcr.io/kormit-panel/kormit/kormit-frontend:v1.x.x` - Frontend Version für Release Tags
