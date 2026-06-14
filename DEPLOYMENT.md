# ArcReel Deployment Guide

This guide covers how to set up and run ArcReel on your local machine.

## Prerequisites

Ensure you have the following installed on your system:
- **Python 3.11+**
- **Node.js 18+**
- **pnpm** (Package manager for Node)
- **uv** (Package manager for Python)
- **FFmpeg** (Required for video processing/stitching)

## 1. Installation

Clone the repository and install dependencies:

### Backend
```bash
# Install Python dependencies using uv
uv sync
```

### Frontend
```bash
cd frontend
pnpm install
```

## 2. Configuration

Copy the example environment file and configure it:
```bash
cp .env.example .env
```
Inside `.env`, configure your authentication parameters:
- `AUTH_USERNAME`
- `AUTH_PASSWORD`
- `AUTH_TOKEN_SECRET` (generate a random string)

API Keys and Provider settings can be managed directly in the Web UI under the `/settings` page once the application is running.

## 3. Database Initialization

Run the Alembic migrations to set up your local SQLite database:
```bash
uv run alembic upgrade head
```

## 4. Running the Application (Development)

You can use the provided Windows batch script to launch both the backend and frontend simultaneously:

```bash
# Double click the file or run it in the terminal
start.bat
```

Alternatively, you can run them manually in separate terminal windows:

**Backend:**
```bash
uv run uvicorn server.app:app --reload --reload-dir server --reload-dir lib --port 1241
```

**Frontend:**
```bash
cd frontend
pnpm dev
```

The frontend will be available at `http://localhost:5173`.

## 5. Production Setup Notes

If deploying to a production server (Linux):
- Use **PostgreSQL** instead of SQLite by setting `DATABASE_URL=postgresql+asyncpg://user:pass@host/db`.
- Run the backend with standard uvicorn workers (without `--reload`).
- Build the frontend statically (`pnpm build`) and serve it using Nginx.
- Set up a reverse proxy (Nginx or Caddy) to route `/api` traffic to the backend on port `1241` and all other traffic to the static frontend files.
- You can optionally use Docker or WSL2 to fully utilize the Agent Sandbox features.
