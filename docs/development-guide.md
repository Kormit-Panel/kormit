# Kormit Development Guide 
 
This guide will help you set up and work with the Kormit codebase. 
 
## Prerequisites 
 
- Docker and Docker Compose 
- Go 1.18 or higher 
- Node.js 16 or higher 
- npm or yarn 
 
## Setting Up Development Environment 
 
1. Clone the repository: 
   ``` 
   git clone https://github.com/yourusername/kormit.git 
   cd kormit 
   ``` 
 
2. Start the development environment: 
   ``` 
   docker-compose -f deploy\docker\development\docker-compose.yml up 
   ``` 
 
3. The applications will be available at: 
   - Backend: http://localhost:8080 
   - Frontend: http://localhost:8081 
