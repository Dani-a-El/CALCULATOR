# Troubleshooting and Error Countermeasures

This guide covers the most common errors observed while running this project and how to fix them quickly.

## 1. Error: address already in use on port 8000

### Symptom

- Uvicorn startup fails with:
- `error while attempting to bind on address ('0.0.0.0', 8000): address already in use`

### Cause

- Another backend process is already listening on port 8000.

### Fix

Find process using 8000:

```bash
ss -ltnp | grep ':8000'
```

Stop existing process by PID:

```bash
kill <PID>
```

Or run backend on another port and update frontend URL accordingly.

### Prevention

- Keep only one backend launch method active (task, debug, or terminal).

## 2. Error: No pubspec.yaml file found

### Symptom

- Flutter run fails with:
- `No pubspec.yaml file found. This command should be run from the root of your Flutter project.`

### Cause

- Command executed from wrong directory.

### Fix

```bash
cd /home/daniel/development/CALCULATOR/pura_calc_flutter
flutter run -d linux
```

### Prevention

- Always run Flutter commands inside `pura_calc_flutter`.

## 3. Error: No Linux desktop project configured

### Symptom

- `flutter run -d linux` fails with desktop support message.

### Cause

- Linux platform files do not exist in project.

### Fix

```bash
cd /home/daniel/development/CALCULATOR/pura_calc_flutter
flutter create . --platforms=linux
flutter run -d linux
```

### Prevention

- Ensure required target platform support is generated once per project.

## 4. Frontend shows Network error on equals

### Symptom

- Result display shows `Network error`.

### Causes

- Backend not running
- Backend running on different host/port
- Frontend URL points to wrong host for selected platform

### Fix

1. Confirm backend is running:

```bash
ss -ltnp | grep ':8000'
```

2. Verify API manually:

```bash
curl -s -X POST http://127.0.0.1:8000/calculate -H 'Content-Type: application/json' -d '{"expression":"1+1"}'
```

3. Confirm URL logic in `pura_calc_flutter/lib/main.dart`:

- Android emulator -> `10.0.2.2`
- Linux/Desktop -> `127.0.0.1`

## 5. Error: Invalid expression response from API

### Symptom

- API returns HTTP 400 with detail `Invalid expression` or `Expression contains invalid characters`.

### Cause

- Expression uses unsupported characters or invalid syntax.

### Fix

- Use only supported operators and characters.
- Ensure balanced parentheses and valid numeric formatting.

Examples:

- Valid: `3+5*2`, `(2+3)^2`, `sqrt(81)`
- Invalid: `3++`, `abc+1`, `import os`

## 6. MySQL history not saving

### Symptom

- History appears but is not persisted across restarts.

### Cause

- `MYSQL_ENABLED` is false or DB connection failed.

### Fix

1. Set environment values correctly (`pura_calc_api/.env.example`).
2. Ensure MySQL server is reachable.
3. Check table exists using `pura_calc_api/schema.sql`.

### Note

- Backend intentionally falls back to in-memory history to keep app functional.

## 7. Debug run fails but terminal run works

### Symptom

- VS Code debug launch fails with exit code while manual command works.

### Cause

- Existing process conflict or wrong working directory in debug config.

### Fix

- Stop old backend process
- Re-run debug launch
- Verify `.vscode/launch.json` uses correct app dir and Python interpreter

## 8. Flutter analyzer errors after edits

### Symptom

- `flutter analyze` reports lint or compile errors.

### Fix flow

```bash
cd /home/daniel/development/CALCULATOR/pura_calc_flutter
flutter pub get
flutter analyze
```

Address reported issues, then re-run.

## 9. Backend smoke test checklist

Run these quickly when debugging:

```bash
curl -s http://127.0.0.1:8000/history
curl -s -X POST http://127.0.0.1:8000/calculate -H 'Content-Type: application/json' -d '{"expression":"3+5*2"}'
```

Expected second response:

```json
{"result":"13"}
```

## 10. Recovery Sequence (when everything is failing)

1. Stop all running backend instances.
2. Start backend once on port 8000.
3. Confirm API with curl.
4. Run frontend from `pura_calc_flutter` directory.
5. Test a simple expression (`1+1`) in UI.
