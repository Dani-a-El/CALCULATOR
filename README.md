# CALCULATOR

This calculator app is a sleek, modern mobile calculator that lets users input numbers and operators, perform standard arithmetic calculations, view results instantly, and optionally save a history of calculations, all in a clean Huawei-inspired interface with rounded buttons and smooth interactions.

## Huawei-Style Calculator (Flutter + FastAPI)

This project is a Huawei Pura-inspired calculator built with:

- Flutter frontend UI with modern rounded controls, ripple effects, and history access
- FastAPI backend for safe expression evaluation
- Optional MySQL persistence for calculation history

## 1. Project Layout

- `pura_calc_flutter/`: Flutter application source
- `pura_calc_api/`: FastAPI backend source
- `docker-compose.yml`: Optional API + MySQL local stack
- `docs/MANUAL.md`: End-to-end usage and operations manual
- `docs/TROUBLESHOOTING.md`: Error handling and fixes
- `docs/CODE_LINE_EXPLANATION.md`: Detailed code walkthrough by line blocks

## 2. Feature Summary

- Calculator layout in a 4-column button grid
- Buttons: `0-9`, `+`, `-`, `×`, `÷`, `%`, `^`, `.`, `C`, `DEL`, `=`
- Live input/result display at top
- API-driven evaluation on `=`
- History retrieval and tap-to-reuse
- Platform-aware backend URL selection for Android emulator and desktop
- Optional MySQL-backed history with in-memory fallback

## 3. Requirements

### Frontend

- Flutter SDK installed and available in PATH
- Linux run support (already added for this repo)

### Backend

- Python 3.12+
- `pip` and virtual environment support

### Optional Database

- Docker + Docker Compose
- or local MySQL server

## 4. Backend Setup and Run

From repository root:

```bash
/home/daniel/development/CALCULATOR/.venv/bin/python -m pip install -r pura_calc_api/requirements.txt
/home/daniel/development/CALCULATOR/.venv/bin/python -m uvicorn app.main:app --app-dir pura_calc_api --reload --host 0.0.0.0 --port 8000
```

API endpoints:

- `POST /calculate` request body: `{"expression":"3+5*2"}` response: `{"result":"13"}`
- `POST /history` request body: `{"expression":"3+5*2","result":"13"}`
- `GET /history` response: `{"items":[...]}`

Quick API test:

```bash
curl -s -X POST http://127.0.0.1:8000/calculate -H 'Content-Type: application/json' -d '{"expression":"3+5*2"}'
```

## 5. Frontend Setup and Run

From repository root:

```bash
cd pura_calc_flutter
flutter pub get
flutter run -d linux
```

The app auto-selects backend URL:

- Android emulator: `http://10.0.2.2:8000`
- Other platforms in current code path: `http://127.0.0.1:8000`

## 6. Optional MySQL Mode

Use environment settings in `pura_calc_api/.env.example`:

- `MYSQL_ENABLED=true`
- `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`

Schema reference:

- `pura_calc_api/schema.sql`

## 7. Docker Run (Optional)

From repository root:

```bash
docker compose up --build
```

This starts:

- API at `http://localhost:8000`
- MySQL at `localhost:3306`

## 8. Error Handling and Safety Notes

- Backend evaluation uses `simpleeval` and does not use Python `eval`
- Expressions are validated by regex before evaluation
- Invalid input returns HTTP 400 with detail message
- If MySQL is unavailable, history falls back to in-memory storage

## 9. Detailed Documentation

- Full manual: `docs/MANUAL.md`
- Error fixes: `docs/TROUBLESHOOTING.md`
- Code explanation: `docs/CODE_LINE_EXPLANATION.md`
