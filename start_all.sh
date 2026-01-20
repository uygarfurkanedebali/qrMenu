#!/bin/bash
# QR Menu - Start All Services (Linux/Mac)
# This script starts all Flutter apps and the Python reverse proxy

echo "========================================"
echo "   QR Menu - Starting All Services"
echo "========================================"
echo

# Start Flutter apps in background
echo "Starting System Admin (port 3000)..."
cd apps/system_admin && flutter run -d chrome --web-port=3000 &
sleep 5

echo "Starting Shop Admin (port 3001)..."
cd ../shop_admin && flutter run -d chrome --web-port=3001 &
sleep 5

echo "Starting Client Panel (port 3002)..."
cd ../client_panel && flutter run -d chrome --web-port=3002 &
sleep 10

cd ../..

echo
echo "========================================"
echo "   All Flutter apps starting..."
echo "   Starting Reverse Proxy on port 80"
echo "========================================"
echo

# Start Python reverse proxy (foreground)
sudo python3 main.py --port 8000
