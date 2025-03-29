@echo off 
REM Kormit development script 
 
echo Starting development environment... 
docker-compose -f deploy\docker\development\docker-compose.yml up 
