"""Shared project paths. Code lives in src/, data stays at the project root."""
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENV_PATH = PROJECT_ROOT / ".env"
CHAT_DB_PATH = PROJECT_ROOT / "data" / "chatbot.db"
FAISS_DB_PATH = PROJECT_ROOT / "faiss_db"
