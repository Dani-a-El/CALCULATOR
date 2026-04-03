# Calculator App Manual

## 1. Purpose

This manual explains how to install, run, test, maintain, and troubleshoot the Huawei-style calculator project.

The system has two apps:

- Frontend: Flutter app in `pura_calc_flutter`
- Backend: FastAPI app in `pura_calc_api`

Optional component:

- MySQL database for persistent history

## 2. Functional Overview

### Frontend features

- Expression input and result display
- 4-column calculator button grid
- Clear (`C`) and delete (`DEL`) controls
- Equals (`=`) triggers backend evaluation
- History modal for previously evaluated expressions
- Dark mode support via system theme

### Backend features

- `POST /calculate` safely evaluates expression
- `POST /history` stores history item
- `GET /history` retrieves history list
- Regex validation and `simpleeval` safety controls
- MySQL optional, in-memory fallback if DB is disabled or unavailable

## 3. Environment Setup

### 3.1 Flutter prerequisites

- Flutter SDK installed
- Linux desktop support enabled (`flutter create . --platforms=linux` already run)

Validate:

```bash
flutter --version
flutter doctor
```

### 3.2 Python prerequisites

- Python 3.12+
- Virtual environment recommended

Install backend dependencies:

```bash
/home/daniel/development/CALCULATOR/.venv/bin/python -m pip install -r pura_calc_api/requirements.txt
```

## 4. Running the Backend

From repo root:

```bash
/home/daniel/development/CALCULATOR/.venv/bin/python -m uvicorn app.main:app --app-dir pura_calc_api --reload --host 0.0.0.0 --port 8000
```

Expected startup lines:

- `Application startup complete`
- `Uvicorn running on http://0.0.0.0:8000`

## 5. Running the Frontend

From repo root:

```bash
cd pura_calc_flutter
flutter pub get
flutter run -d linux
```

If Android emulator is used:

```bash
flutter run -d emulator-5554
```

## 6. Backend URL behavior

Frontend URL logic in `pura_calc_flutter/lib/main.dart`:

- Android emulator uses `http://10.0.2.2:8000`
- Other platforms use `http://127.0.0.1:8000`

This prevents the common localhost mismatch error between emulator and host.

## 7. API Contract

### 7.1 POST /calculate

Request:

```json
{
  "expression": "3+5*2"
}
```

Response:

```json
{
  "result": "13"
}
```

### 7.2 POST /history

Request:

```json
{
  "expression": "3+5*2",
  "result": "13"
}
```

Response:

```json
{
  "status": "saved"
}
```

### 7.3 GET /history

Response:

```json
{
  "items": [
    {
      "id": 1,
      "expression": "3+5*2",
      "result": "13",
      "timestamp": "2026-04-03 12:30:00"
    }
  ]
}
```

## 8. Supported Expression Grammar

Allowed operators:

- `+`, `-`, `*`, `/`, `%`, `^`

Grouping:

- `(` and `)`

Numbers:

- Integers and decimal values

Optional functions:

- `sqrt`, `sin`, `cos`, `log`

Internal conversion:

- UI `×` converted to `*`
- UI `÷` converted to `/`
- `^` converted to `**` for power

## 9. MySQL Mode (Optional)

Enable by setting:

- `MYSQL_ENABLED=true`

Required environment keys:

- `MYSQL_HOST`
- `MYSQL_PORT`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_DATABASE`

Schema file:

- `pura_calc_api/schema.sql`

Table columns:

- `id` INT PK AUTO_INCREMENT
- `expression` VARCHAR(255)
- `result` VARCHAR(255)
- `timestamp` DATETIME

## 10. Docker Mode (Optional)

Start all services:

```bash
docker compose up --build
```

Stop all services:

```bash
docker compose down
```

## 11. Validation Checklist

- Backend starts without bind error
- Frontend launches on selected target
- `POST /calculate` returns expected result
- History appears in frontend modal
- Invalid expressions return clear error

## 12. Operational Best Practices

- Keep one backend instance on port 8000
- Run Flutter commands from `pura_calc_flutter` root only
- Use `.venv` interpreter for backend commands
- Use API curl checks before frontend debugging

## 13. Maintenance Notes

When updating logic:

- Update docs in `README.md`
- Update troubleshooting in `docs/TROUBLESHOOTING.md`
- Update implementation walkthrough in `docs/CODE_LINE_EXPLANATION.md`
