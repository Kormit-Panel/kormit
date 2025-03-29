@echo off 
REM Kormit build script 
 
echo Building backend... 
cd backend 
go build -o bin\kormit.exe cmd\kormit\main.go 
if 0 neq 0 goto error 
cd .. 
 
echo Building frontend... 
cd frontend 
call npm install 
if 0 neq 0 goto error 
call npm run build 
if 0 neq 0 goto error 
cd .. 
 
echo Build completed successfully 
exit /b 0 
 
:error 
echo Build failed 
exit /b 1 
