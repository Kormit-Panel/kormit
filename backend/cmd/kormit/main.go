package main 
 
import ( 
	"encoding/json"
	"fmt" 
	"log"
	"net/http"
	"os"
	"path/filepath"
	
	"github.com/gorilla/mux"
	"github.com/rs/cors"
) 

// Config repräsentiert die Anwendungskonfiguration
type Config struct {
	Server struct {
		Port int    `json:"port"`
		Host string `json:"host"`
	} `json:"server"`
	Database struct {
		Host     string `json:"host"`
		Port     int    `json:"port"`
		User     string `json:"user"`
		Password string `json:"password"`
		DBName   string `json:"dbname"`
	} `json:"database"`
	Logging struct {
		Level  string `json:"level"`
		Format string `json:"format"`
	} `json:"logging"`
}

// Container repräsentiert einen Docker-Container
type Container struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Image   string `json:"image"`
	Status  string `json:"status"`
	Created string `json:"created"`
}

// Deployment repräsentiert ein Deployment von mehreren Containern
type Deployment struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Status      string `json:"status"`
	Replicas    int    `json:"replicas"`
	CreatedAt   string `json:"createdAt"`
}

// LoadConfig lädt die Konfiguration aus einer JSON-Datei
func LoadConfig(path string) (*Config, error) {
	file, err := os.Open(path)
	if err != nil {
		// Wenn die Datei nicht existiert, verwende Standardwerte
		if os.IsNotExist(err) {
			log.Printf("Konfigurationsdatei nicht gefunden: %s, verwende Standardwerte", path)
			return &Config{
				Server: struct {
					Port int    `json:"port"`
					Host string `json:"host"`
				}{
					Port: 8080,
					Host: "0.0.0.0",
				},
			}, nil
		}
		return nil, err
	}
	defer file.Close()

	config := &Config{}
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(config); err != nil {
		return nil, err
	}

	return config, nil
}
 
func main() { 
	fmt.Println("Starting Kormit backend server...") 
	
	// Konfiguration laden
	configPath := filepath.Join("config", "app.json")
	config, err := LoadConfig(configPath)
	if err != nil {
		log.Fatalf("Fehler beim Laden der Konfiguration: %v", err)
	}
	
	log.Printf("Server wird gestartet auf %s:%d", config.Server.Host, config.Server.Port)
	
	// Router initialisieren
	router := mux.NewRouter()
	
	// API-Routes Präfix
	api := router.PathPrefix("/api").Subrouter()
	
	// Root-Route
	router.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok", "message": "Kormit API läuft"})
	})
	
	// Deployments-Routen
	api.HandleFunc("/deployments", getDeployments).Methods("GET")
	api.HandleFunc("/deployments", createDeployment).Methods("POST")
	api.HandleFunc("/deployments/{id}", getDeployment).Methods("GET")
	api.HandleFunc("/deployments/{id}", deleteDeployment).Methods("DELETE")
	api.HandleFunc("/deployments/{id}/restart", restartDeployment).Methods("POST")
	api.HandleFunc("/deployments/{id}/scale", scaleDeployment).Methods("POST")
	api.HandleFunc("/deployments/{id}/activate", activateDeployment).Methods("POST")
	
	// Container-Routen
	api.HandleFunc("/containers", getContainers).Methods("GET")
	api.HandleFunc("/containers", createContainer).Methods("POST")
	api.HandleFunc("/containers/{id}", getContainer).Methods("GET")
	api.HandleFunc("/containers/{id}", deleteContainer).Methods("DELETE")
	api.HandleFunc("/containers/{id}/start", startContainer).Methods("POST")
	api.HandleFunc("/containers/{id}/stop", stopContainer).Methods("POST")
	api.HandleFunc("/containers/{id}/logs", getContainerLogs).Methods("GET")
	
	// Einstellungen-Routen
	api.HandleFunc("/settings", getSettings).Methods("GET")
	api.HandleFunc("/settings", updateSettings).Methods("POST")
	
	// CORS konfigurieren
	corsOptions := cors.New(cors.Options{
		AllowedOrigins: []string{
			"http://localhost:8081",           // Frontend in Entwicklung
			"http://127.0.0.1:8081",           // Frontend (alternativer Zugang)
			"http://kormit-frontend-dev:8080", // Frontend im Docker-Netzwerk
		},
		AllowedMethods: []string{
			http.MethodGet,
			http.MethodPost,
			http.MethodPut,
			http.MethodPatch,
			http.MethodDelete,
			http.MethodOptions,
		},
		AllowedHeaders: []string{
			"Accept",
			"Authorization",
			"Content-Type",
			"X-CSRF-Token",
		},
		AllowCredentials: true,
		Debug:           os.Getenv("KORMIT_DEV_MODE") == "true",
	})
	
	// CORS-Middleware auf den Router anwenden
	handler := corsOptions.Handler(router)
	
	serverAddr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	log.Fatal(http.ListenAndServe(serverAddr, handler)) 
}

// Deployment-Handler
func getDeployments(w http.ResponseWriter, r *http.Request) {
	// In der Entwicklungsphase geben wir Testdaten zurück
	deployments := []Deployment{
		{
			ID:          "deploy-1",
			Name:        "Web Application",
			Description: "Hauptwebserver und Datenbank",
			Status:      "running",
			Replicas:    3,
			CreatedAt:   "2023-09-15T14:30:00Z",
		},
		{
			ID:          "deploy-2",
			Name:        "API Services",
			Description: "REST API Backend",
			Status:      "running",
			Replicas:    2,
			CreatedAt:   "2023-09-14T10:15:00Z",
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(deployments)
}

func getDeployment(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	deploymentID := vars["id"]
	
	// Demo-Deployment
	deployment := Deployment{
		ID:          deploymentID,
		Name:        "Web Application",
		Description: "Hauptwebserver und Datenbank",
		Status:      "running",
		Replicas:    3,
		CreatedAt:   "2023-09-15T14:30:00Z",
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(deployment)
}

func createDeployment(w http.ResponseWriter, r *http.Request) {
	var deployment Deployment
	err := json.NewDecoder(r.Body).Decode(&deployment)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	// Demo-ID setzen
	deployment.ID = "new-deploy-id"
	deployment.CreatedAt = "2023-09-17T08:45:00Z"
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(deployment)
}

func deleteDeployment(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNoContent)
}

func restartDeployment(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "restarted", "id": vars["id"]})
}

func scaleDeployment(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "scaled", "id": vars["id"]})
}

func activateDeployment(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "activated", "id": vars["id"]})
}

// Container-Handler
func getContainers(w http.ResponseWriter, r *http.Request) {
	// In der Entwicklungsphase geben wir Testdaten zurück
	containers := []Container{
		{
			ID:      "container-1",
			Name:    "web-server",
			Image:   "nginx:latest",
			Status:  "running",
			Created: "2023-09-15T14:30:00Z",
		},
		{
			ID:      "container-2",
			Name:    "database",
			Image:   "postgres:13",
			Status:  "running",
			Created: "2023-09-14T10:15:00Z",
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(containers)
}

func getContainer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	containerID := vars["id"]
	
	// Demo-Container
	container := Container{
		ID:      containerID,
		Name:    "web-server",
		Image:   "nginx:latest",
		Status:  "running",
		Created: "2023-09-15T14:30:00Z",
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(container)
}

func createContainer(w http.ResponseWriter, r *http.Request) {
	var container Container
	err := json.NewDecoder(r.Body).Decode(&container)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	// Demo-ID setzen
	container.ID = "new-container-id"
	container.Created = "2023-09-17T08:45:00Z"
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(container)
}

func deleteContainer(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNoContent)
}

func startContainer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "started", "id": vars["id"]})
}

func stopContainer(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "stopped", "id": vars["id"]})
}

func getContainerLogs(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"id": vars["id"],
		"logs": []string{
			"2023-09-17T08:45:00Z INFO: Container gestartet",
			"2023-09-17T08:46:00Z INFO: Service initialisiert",
			"2023-09-17T08:50:00Z INFO: Verbindung zur Datenbank hergestellt",
		},
	})
}

// Einstellungen-Handler
func getSettings(w http.ResponseWriter, r *http.Request) {
	settings := map[string]interface{}{
		"docker": map[string]string{
			"socket":  "/var/run/docker.sock",
			"version": "v1.41",
		},
		"ui": map[string]interface{}{
			"theme":             "light",
			"refreshInterval":   60,
			"notificationsEnabled": true,
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(settings)
}

func updateSettings(w http.ResponseWriter, r *http.Request) {
	var settings map[string]interface{}
	err := json.NewDecoder(r.Body).Decode(&settings)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(settings)
}
