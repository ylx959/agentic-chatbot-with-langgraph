FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:0.8.17 /uv /uvx /bin/

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1

# Install dependencies first so this layer is cached when only code changes
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src/ ./src/

ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8501

# API keys are passed at runtime: docker run --env-file .env ...
CMD ["streamlit", "run", "src/app.py", "--server.address=0.0.0.0", "--server.port=8501", "--server.headless=true"]
