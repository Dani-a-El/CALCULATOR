import os
import re
from datetime import datetime, timezone
from math import cos, log, sin, sqrt
from typing import Any, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from simpleeval import InvalidExpression, NameNotDefined, SimpleEval

MYSQL_ENABLED = os.getenv("MYSQL_ENABLED", "false").lower() == "true"
ALLOWED_PATTERN = re.compile(r"^[0-9+\-*/%^().,\sA-Za-z]+$")

app = FastAPI(title="Pura Calculator API", version="1.0.0")

mysql_conn = None
memory_history: list[dict[str, Any]] = []


class CalculateRequest(BaseModel):
    expression: str = Field(..., min_length=1, max_length=255)


class CalculateResponse(BaseModel):
    result: str


class HistoryRequest(BaseModel):
    expression: str = Field(..., min_length=1, max_length=255)
    result: str = Field(..., min_length=1, max_length=255)


class HistoryItem(BaseModel):
    id: Optional[int] = None
    expression: str
    result: str
    timestamp: Optional[str] = None


class HistoryResponse(BaseModel):
    items: list[HistoryItem]


def get_mysql_connection():
    import mysql.connector

    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", "root"),
        database=os.getenv("MYSQL_DATABASE", "calculator_db"),
        autocommit=True,
    )


def init_db() -> None:
    global mysql_conn
    if not MYSQL_ENABLED:
        return

    mysql_conn = get_mysql_connection()
    cursor = mysql_conn.cursor()
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS calculation_history (
            id INT PRIMARY KEY AUTO_INCREMENT,
            expression VARCHAR(255) NOT NULL,
            result VARCHAR(255) NOT NULL,
            timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )
    cursor.close()


@app.on_event("startup")
def startup_event() -> None:
    try:
        init_db()
    except Exception as ex:  # pragma: no cover
        # Keep API usable even if optional DB initialization fails.
        print(f"MySQL initialization skipped: {ex}")


def normalize_expression(expression: str) -> str:
    normalized = expression.strip()
    normalized = normalized.replace("×", "*").replace("÷", "/")
    normalized = normalized.replace("^", "**")
    return normalized


def evaluate_expression(expression: str) -> str:
    if not ALLOWED_PATTERN.match(expression):
        raise HTTPException(status_code=400, detail="Expression contains invalid characters")

    expr = normalize_expression(expression)

    evaluator = SimpleEval(
        functions={
            "sqrt": sqrt,
            "sin": sin,
            "cos": cos,
            "log": log,
        },
        names={},
    )

    try:
        value = evaluator.eval(expr)
    except (InvalidExpression, NameNotDefined, SyntaxError, TypeError, ValueError, ZeroDivisionError):
        raise HTTPException(status_code=400, detail="Invalid expression")

    if isinstance(value, float):
        rounded = round(value, 10)
        value = int(rounded) if rounded.is_integer() else rounded

    return str(value)


def save_history(expression: str, result: str) -> None:
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    if MYSQL_ENABLED:
        try:
            global mysql_conn
            if mysql_conn is None or not mysql_conn.is_connected():
                mysql_conn = get_mysql_connection()
            cursor = mysql_conn.cursor()
            cursor.execute(
                "INSERT INTO calculation_history (expression, result) VALUES (%s, %s)",
                (expression, result),
            )
            cursor.close()
            return
        except Exception:
            # Fall back to in-memory storage if optional DB write fails.
            pass

    memory_history.insert(
        0,
        {
            "id": len(memory_history) + 1,
            "expression": expression,
            "result": result,
            "timestamp": timestamp,
        },
    )
    del memory_history[20:]


def fetch_history(limit: int = 20) -> list[dict[str, Any]]:
    if MYSQL_ENABLED:
        try:
            global mysql_conn
            if mysql_conn is None or not mysql_conn.is_connected():
                mysql_conn = get_mysql_connection()
            cursor = mysql_conn.cursor(dictionary=True)
            cursor.execute(
                "SELECT id, expression, result, timestamp FROM calculation_history ORDER BY id DESC LIMIT %s",
                (limit,),
            )
            rows = cursor.fetchall()
            cursor.close()
            for row in rows:
                if row.get("timestamp") is not None:
                    row["timestamp"] = str(row["timestamp"])
            return rows
        except Exception:
            pass

    return memory_history[:limit]


@app.post("/calculate", response_model=CalculateResponse)
def calculate(payload: CalculateRequest) -> dict[str, str]:
    result = evaluate_expression(payload.expression)
    save_history(payload.expression, result)
    return {"result": result}


@app.post("/history")
def add_history(payload: HistoryRequest) -> dict[str, str]:
    save_history(payload.expression, payload.result)
    return {"status": "saved"}


@app.get("/history", response_model=HistoryResponse)
def get_history() -> dict[str, list[dict[str, Any]]]:
    return {"items": fetch_history(limit=20)}
