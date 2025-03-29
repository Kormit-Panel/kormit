#!/bin/bash

# Modern CLI colors
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[91m"
GREEN="\033[92m"
YELLOW="\033[93m"
BLUE="\033[94m"
MAGENTA="\033[95m"
CYAN="\033[96m"
WHITE="\033[97m"

# Define logo and title
LOGO=(
"   _  __                    _ _   "
"  | |/ /___  _ __ _ __ ___ (_) |_ "
"  | ' // _ \| '__| '_ \` _ \| | __|"
"  | . \ (_) | |  | | | | | | | |_ "
"  |_|\_\___/|_|  |_| |_| |_|_|\__|"
)

# Function to display the logo
display_logo() {
    clear
    for line in "${LOGO[@]}"; do
        echo -e "${CYAN}${BOLD}${line}${RESET}"
    done
    echo ""
}

# Display menu and get user choice
display_menu() {
    display_logo
    echo -e "${CYAN}${BOLD} Kormit Build System ${RESET}"
    echo -e "${CYAN}====================================${RESET}"
    echo ""
    echo -e "  ${GREEN}[1]${RESET} Build the application"
    echo -e "  ${YELLOW}[2]${RESET} Run tests"
    echo -e "  ${BLUE}[3]${RESET} Start development environment"
    echo -e "  ${MAGENTA}[4]${RESET} Clean build artifacts"
    echo -e "  ${CYAN}[5]${RESET} Build Docker images"
    echo -e "  ${CYAN}[6]${RESET} Run Docker containers"
    echo -e "  ${WHITE}[7]${RESET} Exit"
    echo ""
    echo -e "${CYAN}====================================${RESET}"
    echo ""
    
    read -p "Enter your choice [1-7]: " choice
    
    case $choice in
        1) COMMAND="build" ;;
        2) COMMAND="test" ;;
        3) COMMAND="run-dev" ;;
        4) COMMAND="clean" ;;
        5) COMMAND="docker-build" ;;
        6) COMMAND="docker-run" ;;
        7) exit 0 ;;
        *) 
            echo -e "${RED}Invalid option. Press any key to continue...${RESET}"
            read -n 1
            display_menu
            ;;
    esac
}

# Check if command was provided as argument
if [ $# -eq 0 ]; then
    display_menu
else
    COMMAND="$1"
fi

# Function to return to menu if script was launched without args
return_to_menu() {
    if [ $# -eq 0 ]; then
        echo ""
        read -p "Press Enter to continue..."
        display_menu
        process_command
    fi
}

# Process the chosen command
process_command() {
    case "$COMMAND" in
        build)
            display_logo
            echo -e "${CYAN}${BOLD} ⚙️  Building Kormit...${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            ./scripts/build.sh
            if [ $? -ne 0 ]; then
                echo -e "${RED}[ERROR] Build failed!${RESET}"
            else
                echo -e "${GREEN}[SUCCESS] Build completed successfully!${RESET}"
            fi
            return_to_menu $1
            ;;
        
        test)
            display_logo
            echo -e "${CYAN}${BOLD} 🧪 Running tests...${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            echo -e "Running backend tests..."
            cd backend
            go test ./...
            BACKEND_RESULT=$?
            cd ..
            
            echo -e "Running frontend tests..."
            cd frontend
            npm test -- --passWithNoTests
            FRONTEND_RESULT=$?
            cd ..
            
            if [ $BACKEND_RESULT -ne 0 ]; then
                echo -e "${RED}[ERROR] Backend tests failed!${RESET}"
                return_to_menu $1
                exit 1
            fi
            if [ $FRONTEND_RESULT -ne 0 ]; then
                echo -e "${RED}[ERROR] Frontend tests failed!${RESET}"
                return_to_menu $1
                exit 1
            fi
            echo -e "${GREEN}[SUCCESS] All tests passed!${RESET}"
            return_to_menu $1
            ;;
        
        run-dev)
            display_logo
            echo -e "${CYAN}${BOLD} 🚀 Starting development environment...${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            docker-compose -f deploy/docker/development/docker-compose.yml up
            if [ $? -ne 0 ]; then
                echo -e "${RED}[ERROR] Development environment startup failed!${RESET}"
            else
                echo -e "${GREEN}[SUCCESS] Development environment started!${RESET}"
            fi
            return_to_menu $1
            ;;
        
        clean)
            display_logo
            echo -e "${CYAN}${BOLD} 🧹 Cleaning up...${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            echo -e "Removing backend build artifacts..."
            if [ -d "backend/bin" ]; then
                rm -rf backend/bin
                echo -e "- backend/bin removed"
            else
                echo -e "- backend/bin not found"
            fi
            
            echo -e "Removing frontend build artifacts..."
            if [ -d "frontend/dist" ]; then
                rm -rf frontend/dist
                echo -e "- frontend/dist removed"
            else
                echo -e "- frontend/dist not found"
            fi
            echo -e "${GREEN}[SUCCESS] Cleanup completed!${RESET}"
            return_to_menu $1
            ;;
        
        docker-build)
            display_logo
            echo -e "${CYAN}${BOLD} 🐳 Building Docker images...${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            echo -e "Building backend image..."
            docker build -t kormit-backend:latest ./backend
            BACKEND_RESULT=$?
            
            echo -e "Building frontend image..."
            docker build -t kormit-frontend:latest ./frontend
            FRONTEND_RESULT=$?
            
            if [ $BACKEND_RESULT -ne 0 ]; then
                echo -e "${RED}[ERROR] Backend Docker build failed!${RESET}"
                return_to_menu $1
                exit 1
            fi
            if [ $FRONTEND_RESULT -ne 0 ]; then
                echo -e "${RED}[ERROR] Frontend Docker build failed!${RESET}"
                return_to_menu $1
                exit 1
            fi
            echo -e "${GREEN}[SUCCESS] Docker images built successfully!${RESET}"
            return_to_menu $1
            ;;
        
        docker-run)
            display_logo
            echo -e "${CYAN}${BOLD} 🚢 Running Docker containers...${RESET}"
            echo -e "${CYAN}====================================${RESET}"
            docker-compose -f deploy/docker/production/docker-compose.yml up -d
            if [ $? -ne 0 ]; then
                echo -e "${RED}[ERROR] Docker containers startup failed!${RESET}"
            else
                echo -e "${GREEN}[SUCCESS] Docker containers started successfully!${RESET}"
            fi
            return_to_menu $1
            ;;
        
        help|*)
            display_logo
            echo -e "${CYAN}${BOLD} Kormit Build System ${RESET}"
            echo ""
            echo -e "${WHITE}Usage:${RESET} ./build.sh [command]"
            echo ""
            echo -e "${WHITE}Commands:${RESET}"
            echo -e "  ${GREEN}build${RESET}         Build the application"
            echo -e "  ${YELLOW}test${RESET}          Run tests"
            echo -e "  ${BLUE}run-dev${RESET}       Start development environment"
            echo -e "  ${MAGENTA}clean${RESET}         Clean build artifacts"
            echo -e "  ${CYAN}docker-build${RESET}  Build Docker images"
            echo -e "  ${CYAN}docker-run${RESET}    Run Docker containers"
            echo -e "  ${WHITE}help${RESET}          Show this help"
            return_to_menu $1
            ;;
    esac
}

# Run the command
process_command $1