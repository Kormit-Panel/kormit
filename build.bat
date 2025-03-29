@echo off 
if "%1"=="" goto help 
if "%1"=="build" goto build 
if "%1"=="test" goto test 
if "%1"=="run-dev" goto run-dev 
if "%1"=="clean" goto clean 
if "%1"=="docker-build" goto docker-build 
if "%1"=="docker-run" goto docker-run 
if "%1"=="help" goto help 
 
:build 
echo Building Kormit... 
call scripts\build.bat 
goto end 
 
:test 
echo Running tests... 
cd backend 
go test .\... 
cd ..\frontend 
call npm test 
cd .. 
goto end 
 
:run-dev 
echo Starting development environment... 
docker-compose -f deploy\docker\development\docker-compose.yml up 
goto end 
 
:clean 
echo Cleaning up... 
rmdir /s /q backend\bin 2>nul 
rmdir /s /q frontend\dist 2>nul 
goto end 
 
:docker-build 
echo Building Docker images... 
docker build -t kormit-backend:latest .\backend 
docker build -t kormit-frontend:latest .\frontend 
goto end 
 
:docker-run 
echo Running Docker containers... 
docker-compose -f deploy\docker\production\docker-compose.yml up -d 
goto end 
 
:help 
echo Kormit Build System 
echo Usage: build [command] 
echo. 
echo Commands: 
echo   build        Build the application 
echo   test         Run tests 
echo   run-dev      Start development environment 
echo   clean        Clean build artifacts 
echo   docker-build Build Docker images 
echo   docker-run   Run Docker containers 
echo   help         Show this help 
 
:end 
