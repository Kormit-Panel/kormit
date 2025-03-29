# Kormit Backend 
 
Go-based backend application for Kormit. 
 
## Directory Structure 
 
- `cmd/kormit/` - Application entry point 
- `internal/` - Private application code 
  - `api/` - API definitions and handlers 
  - `core/` - Core functionality 
  - `storage/` - Database interactions 
  - `middleware/` - HTTP middleware 
- `pkg/` - Public libraries 
- `config/` - Configuration files 
 
## Development 
 
### Prerequisites 
 
- Go 1.18 or higher 
- Docker and Docker Compose 
 
### Setup 
 
1. Install dependencies: 
   ```
   go mod download 
   ``` 
 
2. Run locally: 
   ``` 
   go run cmd/kormit/main.go 
   ``` 
 
### Building 
 
``` 
go build -o bin/kormit cmd/kormit/main.go 
``` 
