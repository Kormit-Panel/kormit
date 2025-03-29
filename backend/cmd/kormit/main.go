package main 
 
import ( 
	"fmt" 
	"log" 
	"net/http" 
) 
 
func main() { 
	fmt.Println("Starting Kormit backend server...") 
	// TODO: Initialize services, database, API routes 
	log.Fatal(http.ListenAndServe(":8080", nil)) 
} 
