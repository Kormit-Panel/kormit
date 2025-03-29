package docker

import (
	"context"
	"testing"
)

func TestNewClient(t *testing.T) {
	client, err := NewClient()
	if err != nil {
		t.Fatalf("Fehler beim Erstellen des Docker-Clients: %v", err)
	}
	if client == nil {
		t.Fatal("Docker-Client sollte nicht nil sein")
	}
}

func TestListContainers(t *testing.T) {
	client, err := NewClient()
	if err != nil {
		t.Fatalf("Fehler beim Erstellen des Docker-Clients: %v", err)
	}
	
	containers, err := client.ListContainers(context.Background())
	if err != nil {
		t.Fatalf("Fehler beim Auflisten der Container: %v", err)
	}
	
	// In der Testumgebung erwarten wir eine leere Liste, da keine echte Docker-Engine verwendet wird
	if containers == nil {
		t.Fatal("Container-Liste sollte nicht nil sein")
	}
} 