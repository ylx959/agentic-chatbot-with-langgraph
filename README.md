# Agentic Chatbot using LangGraph

## Setup

```bash
uv sync
```

## Run

```bash
uv run streamlit run src/app_simple.py   # or src/app_tool.py, src/app_db.py, src/app_rag.py, src/app_hitl.py, src/app_thread.py
```

Examples and tests:

```bash
uv run python examples/chatbot_with_hitl.py      # CLI chatbot with human-in-the-loop
uv run python examples/chatbot_without_hitl.py   # CLI chatbot without HITL
uv run streamlit run examples/non_stream.py      # non-streaming Streamlit app
uv run python tests/test.py                      # streaming smoke test (calls the LLM)
```

API keys are read from `.env`.

## Layout

```
src/        all Python code (Streamlit apps + LangGraph backends, shared paths in config.py)
examples/   standalone CLI / non-streaming demos
tests/      smoke tests
notebooks/  step-by-step notebooks (chatbot workflow, tools, RAG, HITL)
diagrams/   Excalidraw architecture diagrams
faiss_db/   FAISS vector index used by the RAG backends
data/       SQLite checkpoint store chatbot.db (conversation history)
.env        API keys
```
