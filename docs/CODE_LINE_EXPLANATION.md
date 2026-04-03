# Code Line Explanation

This file explains the current implementation in:

- `pura_calc_flutter/lib/main.dart`
- `pura_calc_api/app/main.py`

Because these files are long, explanations are provided in strict line-block order so every line in each source file is covered.

## A. Frontend: pura_calc_flutter/lib/main.dart

### Block A1: Imports and app bootstrap

- `import 'dart:convert';`: Enables JSON encode/decode for HTTP payloads.
- `import 'dart:io' show Platform;`: Detects runtime platform to choose backend host.
- `import 'package:flutter/material.dart';`: Flutter UI components.
- `import 'package:http/http.dart' as http;`: HTTP client for backend calls.
- `void main() { runApp(const CalculatorApp()); }`: App entry point; mounts root widget.

### Block A2: Root widget configuration

- `class CalculatorApp extends StatelessWidget`: Immutable root widget.
- `MaterialApp(...)`: Defines app-level routing/theme behavior.
- `title`: App title used by system/task switcher.
- `debugShowCheckedModeBanner: false`: Hides debug banner.
- `themeMode: ThemeMode.system`: Uses OS light/dark mode.
- `theme` and `darkTheme`: Light/dark appearance definitions.
- `home: const CalculatorPage()`: Main screen.

### Block A3: Stateful calculator screen and state initialization

- `class CalculatorPage extends StatefulWidget`: Screen with mutable UI state.
- `createState`: Creates `_CalculatorPageState`.
- `backendBaseUrl` getter:
- `Platform.isAndroid`: Uses Android-emulator mapping `10.0.2.2`.
- `else`: Uses `127.0.0.1` for desktop/iOS simulator style local access.
- `input`: Current expression string typed by button presses.
- `result`: Displayed result string.
- `loading`: Prevents overlapping calculate requests.
- `history`: Local list of fetched history objects.
- `buttons`: Fixed order for calculator keypad content.

### Block A4: Operator helper and button handler

- `_isOperator(String value)`: Classifies operator buttons for styling.
- `_onButtonTap(String value) async`: Main click controller.
- `if (loading) return;`: Prevents duplicate submissions while waiting.
- `if (value == 'C')`: Clears both input and result.
- `if (value == 'DEL')`: Removes last typed character.
- `if (value == '=')`: Validates non-empty input and triggers `_calculate()`.
- Final `setState`: Appends tapped character to input for normal buttons.

### Block A5: Expression normalization and calculate request

- `_normalizeExpression`: Replaces UI glyphs (`×`, `÷`) with backend operators (`*`, `/`).
- `_calculate()`: Sends expression to backend and updates UI.
- `loading = true`: Shows calculating state and locks input.
- `normalized`: Expression transformed for API compatibility.
- `http.post(...)`: Calls `/calculate` with JSON body.
- `statusCode == 200` branch:
- Decodes JSON response.
- Updates `result` from backend payload.
- Refreshes history list via `_loadHistory()`.
- Error status branch:
- Parses error payload.
- Shows backend detail text or fallback message.
- `catch`: Network/transport failure fallback message.
- `finally`: Always clears `loading` flag.

### Block A6: History loading and modal rendering

- `_loadHistory()`: Calls `GET /history`.
- On 200:
- Parses `items` list.
- Casts each dynamic item to map.
- Stores list in `history` state.
- Catch block intentionally ignored because history is optional.
- `_openHistory()`: Opens modal bottom sheet.
- Empty history path returns compact placeholder.
- Non-empty path renders `ListView.separated`.
- Each item row shows `expression = result` and timestamp.
- On tap:
- Closes modal.
- Replaces current `input` and `result` with selected history row.

### Block A7: Lifecycle and main layout

- `initState`: Calls `_loadHistory()` once at startup.
- `build(BuildContext context)`: Rebuilds UI from current state.
- `isDark`: Reads active theme brightness.
- `Scaffold`:
- `AppBar` title + history action button.
- `body` container uses dark/light gradient background.
- `SafeArea` avoids system overlap.
- Main `Column` has two vertical areas:
- Display area (`flex: 3`) with right-aligned input/result text.
- Keypad area (`flex: 5`) with fixed 4-column grid.
- `GridView.builder`:
- Uses `buttons` list as source.
- Prevents scroll for stable keypad behavior.
- Creates `CalculatorButton` per key with operator highlighting.

### Block A8: Reusable CalculatorButton widget

- `class CalculatorButton extends StatelessWidget`: Visual keypad key component.
- Constructor requires `label`, `isOperator`, `onTap`.
- `isDark` computes theme-specific colors.
- `bg` and `fg` assign operator and normal key colors.
- `Material` + `Ink` + `InkWell` combination:
- Preserves ripple effects with rounded shape.
- `BoxDecoration`:
- Rounded corners.
- Soft shadow for elevated Huawei-like appearance.
- `Text` in center renders key label with weight and size.

## B. Backend: pura_calc_api/app/main.py

### Block B1: Imports and global configuration

- `import os`, `import re`: Environment + regex support.
- `datetime, timezone`: Timestamp creation for history entries.
- `math` imports (`cos`, `log`, `sin`, `sqrt`): Allowed safe scientific functions.
- `typing` imports: Type hints for dictionaries and optional fields.
- FastAPI and Pydantic imports: API framework and request/response models.
- `simpleeval` imports: Restricted expression evaluator.
- `MYSQL_ENABLED`: Reads env var and normalizes to boolean.
- `ALLOWED_PATTERN`: Regex that whitelists supported characters.
- `app = FastAPI(...)`: API application instance metadata.
- `mysql_conn = None`: Shared MySQL connection holder.
- `memory_history = []`: In-memory fallback store.

### Block B2: Pydantic models

- `CalculateRequest`: Validates incoming expression input.
- `CalculateResponse`: Standard response payload for `/calculate`.
- `HistoryRequest`: Input model for manual history insert endpoint.
- `HistoryItem`: Output shape for one history record.
- `HistoryResponse`: Wrapper list response model for `/history` GET.

### Block B3: MySQL connectivity and schema initialization

- `get_mysql_connection()`:
- Imports mysql connector only when used.
- Reads host/port/user/password/database from environment.
- Enables autocommit for simple write workflow.
- `init_db()`:
- Exits early when MySQL mode is disabled.
- Opens connection.
- Executes `CREATE TABLE IF NOT EXISTS calculation_history`.
- Closes cursor.

### Block B4: Startup hook and DB fault tolerance

- `@app.on_event("startup")`: Runs once when service starts.
- `startup_event`:
- Calls `init_db()`.
- Catches initialization failure and logs message.
- Behavior is intentional so calculator can still work without MySQL.

### Block B5: Expression normalization and safe evaluation

- `normalize_expression`:
- Trims whitespace.
- Converts UI operators to Python-safe syntax.
- Converts `^` to `**` for exponentiation.
- Returns transformed expression.
- `evaluate_expression`:
- Rejects expressions failing whitelist regex.
- Normalizes expression.
- Constructs `SimpleEval` with only allowed functions.
- `names={}` disables variable access.
- `evaluator.eval(expr)` computes expression safely.
- Catches parse/runtime errors and returns HTTP 400.
- Float results are rounded to 10 decimals.
- Converts whole-number floats to integer form.
- Returns final result as string.

### Block B6: History write logic

- `save_history(expression, result)`:
- Generates UTC timestamp string.
- If MySQL enabled:
- Reconnects if connection is missing/stale.
- Executes parameterized insert statement.
- Returns on success.
- If DB write fails or MySQL disabled:
- Inserts item into front of in-memory list.
- Trims list to latest 20 entries.

### Block B7: History read logic

- `fetch_history(limit=20)`:
- If MySQL enabled:
- Reconnects if needed.
- Reads rows ordered newest-first by id.
- Converts datetime fields to strings.
- Returns DB rows.
- On DB failure or disabled mode:
- Returns in-memory history slice.

### Block B8: API routes

- `@app.post('/calculate')`:
- Validates request model.
- Evaluates expression safely.
- Persists history.
- Returns result payload.
- `@app.post('/history')`:
- Persists provided expression/result pair.
- Returns saved status.
- `@app.get('/history')`:
- Returns list of recent history items.

## C. Data and Control Flow Summary

1. User taps keys in frontend.
2. Input string updates in state.
3. User taps `=`.
4. Frontend normalizes and posts expression to backend.
5. Backend validates and safely evaluates.
6. Backend saves record to MySQL or memory fallback.
7. Backend returns result string.
8. Frontend renders result and refreshes history.

## D. Security-Critical Lines to Keep Intact

- Regex whitelist in backend (`ALLOWED_PATTERN`)
- `SimpleEval` usage with restricted `functions` and `names={}`
- No use of Python `eval`
- Parameterized SQL insert statement

## E. If You Edit Code

After edits run:

```bash
cd /home/daniel/development/CALCULATOR/pura_calc_flutter && flutter analyze
/home/daniel/development/CALCULATOR/.venv/bin/python -m py_compile /home/daniel/development/CALCULATOR/pura_calc_api/app/main.py
```
