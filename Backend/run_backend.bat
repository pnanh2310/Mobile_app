@echo off
echo ========================================
echo   Chay Backend API - PCM 056
echo ========================================
echo.

cd /d "%~dp0"

echo Dang khoi dong backend...
echo API se chay tai:
echo   - HTTP:  http://localhost:5000
echo   - HTTPS: https://localhost:5001
echo   - Swagger: https://localhost:5001/swagger
echo.
echo Nhan Ctrl+C de dung backend
echo.

dotnet run

pause
