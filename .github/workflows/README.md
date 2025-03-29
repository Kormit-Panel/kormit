# GitHub Workflows 
 
Dieses Verzeichnis enthält GitHub Actions Workflows für CI/CD.
 
## Workflows 
 
- `ci.yml` - Run tests and linting on PRs 
- `build.yml` - Baut Docker Images und veröffentlicht sie auf Docker Hub

Docker Images werden unter den folgenden Tags veröffentlicht:

- `kormit/kormit-backend:latest` - Neueste Version des Backends
- `kormit/kormit-frontend:latest` - Neueste Version des Frontends
- `kormit/kormit-backend:{commit-sha}` - Backend Version für spezifischen Commit
- `kormit/kormit-frontend:{commit-sha}` - Frontend Version für spezifischen Commit
- `kormit/kormit-backend:{tag}` - Backend Version für Release Tags
- `kormit/kormit-frontend:{tag}` - Frontend Version für Release Tags
