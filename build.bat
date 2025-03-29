@echo off
setlocal enabledelayedexpansion

REM Define logo and title
echo.
echo    _  __                    _ _   
echo   ^| ^|/ /___  _ __ _ __ ___ (_) ^|_ 
echo   ^| ' // _ \^| '__^| '_ \` _ \^| ^| __^|
echo   ^| . \ (_) ^| ^|  ^| ^| ^| ^| ^| ^| ^| ^|_ 
echo   ^|_^|\_\___/^|_^|  ^|_^| ^|_^| ^|_^|_^|\__^|
echo.

REM Check if command was provided as argument
if not "%~1"=="" (
    set COMMAND=%~1
    goto process_command
)

:menu
echo Kormit Build System
echo ===================================
echo.
echo  [1] Build the application
echo  [2] Run tests
echo  [3] Start development environment
echo  [4] Clean build artifacts
echo  [5] Build Docker images
echo  [6] Run Docker containers
echo  [7] Exit
echo.
echo ===================================
echo.

set /p MENU_CHOICE="Enter your choice [1-7]: "

if "%MENU_CHOICE%"=="1" set COMMAND=build
if "%MENU_CHOICE%"=="2" set COMMAND=test
if "%MENU_CHOICE%"=="3" set COMMAND=run-dev
if "%MENU_CHOICE%"=="4" set COMMAND=clean
if "%MENU_CHOICE%"=="5" set COMMAND=docker-build
if "%MENU_CHOICE%"=="6" set COMMAND=docker-run
if "%MENU_CHOICE%"=="7" goto end

echo.

:process_command
if "%COMMAND%"=="build" goto build
if "%COMMAND%"=="test" goto test
if "%COMMAND%"=="run-dev" goto run-dev
if "%COMMAND%"=="clean" goto clean
if "%COMMAND%"=="docker-build" goto docker-build
if "%COMMAND%"=="docker-run" goto docker-run
if "%COMMAND%"=="help" goto help

REM Unknown command
echo Unknown command: %COMMAND%
echo.
goto menu

:build
echo ===================================
echo  Building Kormit...
echo ===================================
call scripts\build.bat
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
) else (
    echo [SUCCESS] Build completed successfully!
)
if "%~1"=="" goto return_to_menu
goto end

:test
echo ===================================
echo  Running tests...
echo ===================================
echo Running backend tests...
cd backend
go test .\...
set backend_result=%ERRORLEVEL%
cd ..
echo.
echo Running frontend tests...
cd frontend
call npm test -- --passWithNoTests
set frontend_result=%ERRORLEVEL%
cd ..

if %backend_result% NEQ 0 (
    echo [ERROR] Backend tests failed!
    if "%~1"=="" goto return_to_menu
    goto end
)
if %frontend_result% NEQ 0 (
    echo [ERROR] Frontend tests failed!
    if "%~1"=="" goto return_to_menu
    goto end
)
echo [SUCCESS] All tests passed!
if "%~1"=="" goto return_to_menu
goto end

:run-dev
echo ===================================
echo  Starting development environment...
echo ===================================
docker-compose -f deploy\docker\development\docker-compose.yml up
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Development environment startup failed!
) else (
    echo [SUCCESS] Development environment started!
)
if "%~1"=="" goto return_to_menu
goto end

:clean
echo ===================================
echo  Cleaning up...
echo ===================================
echo Removing backend build artifacts...
if exist backend\bin (
    rmdir /s /q backend\bin
    echo - backend\bin removed
) else (
    echo - backend\bin not found
)

echo Removing frontend build artifacts...
if exist frontend\dist (
    rmdir /s /q frontend\dist
    echo - frontend\dist removed
) else (
    echo - frontend\dist not found
)
echo [SUCCESS] Cleanup completed!
if "%~1"=="" goto return_to_menu
goto end

:docker-build
echo ===================================
echo  Building Docker images...
echo ===================================
echo Building backend image...
docker build -t kormit-backend:latest .\backend
set backend_result=%ERRORLEVEL%

echo Building frontend image...
docker build -t kormit-frontend:latest .\frontend
set frontend_result=%ERRORLEVEL%

if %backend_result% NEQ 0 (
    echo [ERROR] Backend Docker build failed!
    if "%~1"=="" goto return_to_menu
    goto end
)
if %frontend_result% NEQ 0 (
    echo [ERROR] Frontend Docker build failed!
    if "%~1"=="" goto return_to_menu
    goto end
)
echo [SUCCESS] Docker images built successfully!
if "%~1"=="" goto return_to_menu
goto end

:docker-run
echo ===================================
echo  Running Docker containers...
echo ===================================
docker-compose -f deploy\docker\production\docker-compose.yml up -d
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker containers startup failed!
) else (
    echo [SUCCESS] Docker containers started successfully!
)
if "%~1"=="" goto return_to_menu
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
if "%~1"=="" goto return_to_menu
goto end

:return_to_menu
echo.
pause
cls
goto menu

:end
endlocal