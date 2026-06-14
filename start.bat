@echo off
echo Starting ArcReel...

:: Install Backend Dependencies
echo [1/5] Checking backend dependencies...
uv sync

:: Start backend (--loop asyncio forces ProactorEventLoop on Windows, required for subprocess spawning by claude-agent-sdk)
echo [2/5] Starting backend server...
start "ArcReel Backend" cmd /k "uv run uvicorn server.app:app --reload --reload-dir server --reload-dir lib --port 1241 --loop asyncio"

:: Wait 3 seconds for backend to boot
timeout /t 3 /nobreak >nul

:: Install Frontend Dependencies
echo [3/5] Checking frontend dependencies...
cd frontend
call pnpm install

:: Start frontend
echo [4/5] Starting frontend server...
start "ArcReel Frontend" cmd /k "pnpm dev"
cd ..

:: Wait 2 seconds for Vite to initialize
timeout /t 2 /nobreak >nul

:: Open browser
echo [5/5] Launching web browser...
start http://localhost:5173

echo.
echo ArcReel is starting up!
echo Backend:  http://localhost:1241
echo Frontend: http://localhost:5173
echo.
pause
