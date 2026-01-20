@echo off
REM QR Menu - Start All Services (Windows)
REM This script starts all Flutter apps and the Python reverse proxy

echo ========================================
echo    QR Menu - Starting All Services
echo ========================================
echo.

REM Start Flutter apps in background
echo Starting System Admin (port 3000)...
start "System Admin" cmd /c "cd apps\system_admin && flutter run -d chrome --web-port=3000"

timeout /t 5 /nobreak > nul

echo Starting Shop Admin (port 3001)...
start "Shop Admin" cmd /c "cd apps\shop_admin && flutter run -d chrome --web-port=3001"

timeout /t 5 /nobreak > nul

echo Starting Client Panel (port 3002)...
start "Client Panel" cmd /c "cd apps\client_panel && flutter run -d chrome --web-port=3002"

timeout /t 10 /nobreak > nul

echo.
echo ========================================
echo    All Flutter apps starting...
echo    Starting Reverse Proxy on port 80
echo ========================================
echo.

REM Start Python reverse proxy (foreground)
python main.py --port 8000

pause
