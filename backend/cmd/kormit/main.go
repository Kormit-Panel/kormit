package main 
 
import ( 
	"encoding/json"
	"fmt" 
	"log"
	"net/http"
	"os"
	"path/filepath"
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
	
	// TODO: Initialize services, database, API routes
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok", "message": "Kormit API läuft"})
	})
	
	serverAddr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	log.Fatal(http.ListenAndServe(serverAddr, nil)) 
}
