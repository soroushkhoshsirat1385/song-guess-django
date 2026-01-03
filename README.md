# Song Guessing Game (Django)

This repo is the beginnings of a multiplayer **song guessing game** backend.

## Current status (MVP backend)

Backend lives under:
- `backend/server/` (Django project: `songguess`)

Key capabilities implemented so far:
- Django + PostgreSQL support (and an easy SQLite mode for first run)
- Django Channels (WebSockets) for realtime room events
- Core models: Rooms, membership + scores, rounds, submissions (song uploads), guesses
- Minimal API endpoints for auth + room flow + submit/guess

## Setup

### 1) Create / use the virtualenv

Dependencies are listed in:
- `backend/requirements/base.txt`

A virtualenv is already created by the agent in:
- `backend/.venv/`

If you want to recreate it:
```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -U pip
.\.venv\Scripts\python.exe -m pip install -r requirements\base.txt
```

### 2) Configure environment

Copy the example env file:
- `backend/server/.env.example`

#### Postgres-first (recommended)

You can run Postgres with Docker Compose (recommended):
```powershell
docker compose up -d
```

Then run migrations pointing at Postgres via env vars:
```powershell
cd backend\server
# set DB_* env vars (or load from your shell)
..\.venv\Scripts\python.exe manage.py migrate
```

#### SQLite quick-run (optional)
If you want to run without Postgres:
```powershell
cd backend\server
$env:USE_SQLITE='1'
..\.venv\Scripts\python.exe manage.py migrate
```

### 3) Migrate

SQLite quick-run:
```powershell
cd backend\server
$env:USE_SQLITE='1'
..\.venv\Scripts\python.exe manage.py migrate
```

Postgres:
```powershell
cd backend\server
# set DB_* env vars first
..\.venv\Scripts\python.exe manage.py migrate
```

### 4) Run the server

```powershell
cd backend\server
$env:USE_SQLITE='1'
..\.venv\Scripts\python.exe manage.py runserver
```

## HTTP endpoints

Health:
- `GET /health/`

Session-based auth (JSON):
- `POST /api/auth/register/` `{ "username": "...", "password": "..." }`
- `POST /api/auth/login/` `{ "username": "...", "password": "..." }`
- `POST /api/auth/logout/`
- `GET /api/auth/me/`

Rooms:
- `POST /api/rooms/create/` `{ "name": "optional" }`
- `GET /api/rooms/` (list rooms you are a member of)
- `POST /api/rooms/<code>/join/`
- `POST /api/rooms/<code>/leave/`
- `GET /api/rooms/<code>/state/`

Gameplay:
- `POST /api/rooms/<code>/submit/` (multipart form with `file`)
- `POST /api/rooms/<code>/submissions/<id>/guess/` `{ "guessed_username": "..." }`
- `POST /api/rooms/<code>/order/create/` (creates RoundSong play order for round 1)
- `POST /api/rooms/<code>/reveal/` (scores + returns leaderboard for round 1)

## WebSockets

WebSocket route:
- `ws://localhost:8000/ws/rooms/<room_code>/`

The socket is authenticated via Django session cookies (same browser session as the HTTP login).

Messages supported (JSON):
- `{"type":"ping"}` → `{"type":"pong"}`
- `{"type":"state"}` → `{"type":"state","state":{...}}`
- `{"type":"guess","submission_id":123,"guessed_username":"alice"}`
  - broadcasts: `{"type":"guess", ...}` to everyone in the room
- `{"type":"reveal","round":1}`
  - computes MVP scoring and broadcasts `{"type":"reveal", "leaderboard": [...] }`

### MVP scoring rules
- +2 for each correct guess (to the guesser)
- +3 to the uploader if nobody guessed their song correctly

## Notes / known limitations

- Uploaded media is served from `/media/` in `DEBUG` mode. For production we should serve audio behind auth (room membership checks), not as a public static URL.
- Room/round flow is currently hard-coded to round 1 for simplicity.
