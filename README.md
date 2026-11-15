# Agentic Chatbot using LangGraph

> **A step-by-step learning repo.** This project builds an agentic chatbot one feature at a time with [LangGraph](https://github.com/langchain-ai/langgraph) and [Streamlit](https://streamlit.io/). It starts as a single-node chat workflow and adds threads, database persistence, tool calling, RAG and human-in-the-loop, one layer per stage.

Each stage is a separate, runnable Streamlit app with its own backend. You can run them in order and see exactly what each new concept adds on top of the previous one. Rather than one finished product, the repo is a record of how an agent is put together.

---

## Learning Path

| # | Stage | App | Backend | What's new |
|---|-------|-----|---------|------------|
| 1 | **Simple chatbot** | `app_simple.py` | `agentic_chatbot_backend.py` | A single-node `StateGraph` (`START → chat_node → END`), message state with `add_messages`, streaming replies via `st.write_stream` |
| 2 | **Threads** | `app_thread.py` | `agentic_chatbot_backend.py` | Multiple conversations with `thread_id`, a sidebar to switch between them, in-memory `MemorySaver` checkpointer |
| 3 | **Database persistence** | `app_db.py` | `agentic_chatbot_db_backend.py` | `SqliteSaver` instead of `MemorySaver`, so conversations persist across restarts; past threads are listed from the checkpoint store |
| 4 | **Tool calling** | `app_tool.py` | `agentic_chatbot_tool_backend.py` | `ToolNode` + `tools_condition` routing; tools: web search (Tavily), calculator, stock price (Alpha Vantage), weather (OpenWeather) |
| 5 | **RAG** | `app_rag.py` | `agentic_chatbot_rag_backend.py` | Upload a PDF → chunk → embed → store in FAISS; a `rag_tool` lets the agent answer questions about the document |
| 6 | **Human-in-the-loop** | `app_hitl.py` | `agentic_chatbot_hitl_backend.py` | A `purchase_stock` tool that pauses the graph with `interrupt()` and resumes with `Command(resume=...)` after the user approves or rejects |

The graph grows from a straight line into an agent loop:

```
Stage 1–3:   START ──► chat_node ──► END

Stage 4–6:   START ──► chat_node ──(tool call?)──► tools ──┐
                           ▲             │                  │
                           │             └──(no)──► END     │
                           └────────────────────────────────┘
```

The `notebooks/` folder walks through the same concepts interactively, and `diagrams/` contains Excalidraw sketches of the architecture.

---

## Project Structure

```
agentic-chatbot-using-langgraph/
├── src/                                  # Application code
│   ├── config.py                         # Shared paths (.env, data/chatbot.db, faiss_db/)
│   ├── app_simple.py                     # Stage 1 – simple streaming chatbot
│   ├── app_thread.py                     # Stage 2 – multi-thread conversations
│   ├── app_db.py                         # Stage 3 – SQLite persistence
│   ├── app_tool.py                       # Stage 4 – tool calling
│   ├── app_rag.py                        # Stage 5 – RAG with PDF upload
│   ├── app_hitl.py                       # Stage 6 – human-in-the-loop approval
│   ├── agentic_chatbot_backend.py        # Backend for stages 1–2 (MemorySaver)
│   ├── agentic_chatbot_db_backend.py     # Backend for stage 3 (SqliteSaver)
│   ├── agentic_chatbot_tool_backend.py   # Backend for stage 4 (tools)
│   ├── agentic_chatbot_rag_backend.py    # Backend for stage 5 (tools + RAG)
│   └── agentic_chatbot_hitl_backend.py   # Backend for stage 6 (tools + RAG + HITL)
│
├── notebooks/                            # Step-by-step concept notebooks
│   ├── Chatbot_workflow.ipynb            # Building the basic chat graph
│   ├── tools_demo.ipynb                  # Tool calling
│   ├── rag_demo.ipynb                    # RAG pipeline
│   ├── HITL_demo.ipynb                   # Human-in-the-loop with interrupt()
│   └── my_paper.pdf                      # Sample document for the RAG notebook
│
├── examples/                             # Standalone demos
│   ├── chatbot_without_hitl.py           # CLI agent (tools + RAG)
│   ├── chatbot_with_hitl.py              # CLI agent with HITL approval
│   └── non_stream.py                     # Non-streaming Streamlit chatbot
│
├── tests/
│   └── test.py                           # Streaming smoke test (calls the LLM)
│
├── diagrams/                             # Excalidraw architecture diagrams
│   ├── demo.excalidraw
│   └── HITL.excalidraw
│
├── data/
│   └── chatbot.db                        # SQLite checkpoint store (git-ignored)
├── faiss_db/                             # FAISS vector index for the RAG stages
│
├── pyproject.toml                        # Dependencies (managed by uv)
├── uv.lock
└── .env                                  # API keys (git-ignored, create your own)
```

---

## Tech Stack

- **LangGraph**: graph-based agent workflow, checkpointers, `interrupt` / `Command`
- **LangChain**: tools, document loaders, text splitters
- **Google Gemini**: chat model (`gemini-3.1-flash-lite`) and embeddings (`gemini-embedding-001`)
- **FAISS**: local vector store for RAG
- **SQLite**: conversation persistence via `langgraph-checkpoint-sqlite`
- **Streamlit**: chat UI
- **LangSmith** (optional): tracing
- **uv**: Python environment and dependency management

---

## Getting Started

### 1. Install

Requires Python 3.11+ and [uv](https://docs.astral.sh/uv/).

```bash
git clone <this-repo>
cd agentic-chatbot-using-langgraph
uv sync
```

### 2. Configure API keys

Create a `.env` file in the project root:

```env
GOOGLE_API_KEY=...          # required – Gemini chat model and embeddings
TAVILY_API_KEY=...          # stage 4+ – web search tool
OPENWEATHER_API_KEY=...     # stage 4+ – weather tool

# Optional – LangSmith tracing
LANGSMITH_TRACING=false
LANGSMITH_ENDPOINT=https://api.smith.langchain.com
LANGSMITH_API_KEY=...
LANGSMITH_PROJECT=agentic-chatbot-project
```

### 3. Run a stage

Run from the project root:

```bash
uv run streamlit run src/app_simple.py   # stage 1
uv run streamlit run src/app_thread.py   # stage 2
uv run streamlit run src/app_db.py       # stage 3
uv run streamlit run src/app_tool.py     # stage 4
uv run streamlit run src/app_rag.py      # stage 5
uv run streamlit run src/app_hitl.py     # stage 6
```

### Notebooks, examples and tests

```bash
uv run jupyter lab                                # open the notebooks
uv run python examples/chatbot_with_hitl.py       # CLI agent with HITL
uv run python examples/chatbot_without_hitl.py    # CLI agent without HITL
uv run streamlit run examples/non_stream.py       # non-streaming chatbot
uv run python tests/test.py                       # streaming smoke test (calls the LLM)
```

---

## Notes

- Conversation history is stored in `data/chatbot.db`. Delete it, or clear its tables, to start fresh. It's recreated automatically.
- Uploading a PDF in the RAG / HITL apps overwrites the single shared index in `faiss_db/`.
- `purchase_stock` is a mock tool. No real trade is ever placed.
