# Agentic Chatbot using LangGraph

An agentic chatbot built with [LangGraph](https://github.com/langchain-ai/langgraph) and [Streamlit](https://streamlit.io/). It can search the web, do math, check stock prices and the weather, and answer questions about a PDF you upload. Before it makes a (mock) stock purchase, it stops and asks you to approve.

## Highlights

- **Multiple conversations**: start new chats and switch between past ones in the sidebar
- **Persistent history**: conversations are saved to SQLite and survive restarts
- **Tool calling**: web search (Tavily), calculator, stock price (Alpha Vantage), current weather (OpenWeather)
- **RAG over your PDF**: upload a PDF, which is chunked, embedded and stored in FAISS, then ask questions about it
- **Human-in-the-loop**: `purchase_stock` pauses the graph with `interrupt()` and resumes with your approve/reject decision
- **Streaming replies** with live tool-call status

## How it works

```
START ──► chat_node ──(tool call?)──► tools ──┐
              ▲            │                  │
              │            └──(no)──► END     │
              └───────────────────────────────┘
```

`chat_node` calls Gemini with all tools bound. When the model asks for a tool, `tools_condition` routes to the `ToolNode`, and the result goes back to the model. The loop ends when the model answers without calling a tool. A `SqliteSaver` checkpointer stores each thread's state, which lets the human-in-the-loop interrupt pause and resume.

## Learn with the notebooks

New to LangGraph? The `notebooks/` folder builds the same ideas step by step, and you can follow along before reading `src/`:

1. `Chatbot_workflow.ipynb`: a basic chat graph
2. `tools_demo.ipynb`: tool calling
3. `rag_demo.ipynb`: the RAG pipeline
4. `HITL_demo.ipynb`: human-in-the-loop with `interrupt()`

`diagrams/` has Excalidraw sketches of the architecture.

## Project Structure

```
├── src/
│   ├── app.py            # Streamlit UI
│   └── backend.py        # LangGraph graph, tools, RAG, SQLite checkpointer
├── notebooks/            # Step-by-step learning notebooks
├── diagrams/             # Excalidraw architecture diagrams
├── examples/             # Standalone CLI / non-streaming demos
├── tests/                # Streaming smoke test
├── Dockerfile
└── pyproject.toml        # Dependencies (managed by uv)
```

## Built With

- **LangGraph**: agent graph, checkpointers, `interrupt` / `Command`
- **LangChain**: tools, document loaders, text splitters
- **Google Gemini**: chat model (`gemini-3.1-flash-lite`) and embeddings (`gemini-embedding-001`)
- **FAISS**: local vector store for RAG
- **SQLite**: conversation persistence via `langgraph-checkpoint-sqlite`
- **Streamlit**: chat UI
- **LangSmith** (optional): tracing
- **uv**: dependency management
- **Docker**: containerised deployment

## Getting Started

### 1. Configure API keys

Create a `.env` file in the project root:

```env
GOOGLE_API_KEY=...          # required: Gemini chat model and embeddings
TAVILY_API_KEY=...          # web search tool
OPENWEATHER_API_KEY=...     # weather tool
ALPHAVANTAGE_API_KEY=...    # stock price tool

# Optional: LangSmith tracing
LANGSMITH_TRACING=false
LANGSMITH_API_KEY=...
LANGSMITH_PROJECT=agentic-chatbot-project
```

### 2a. Run with Docker

```bash
docker build -t agentic-chatbot .
docker run --rm -p 8501:8501 --env-file .env agentic-chatbot
```

Open http://localhost:8501. To keep chat history and the PDF index after the container stops, add `-v "$PWD/data:/app/data" -v "$PWD/faiss_db:/app/faiss_db"`.

### 2b. Run locally

Requires Python 3.11+ and [uv](https://docs.astral.sh/uv/).

```bash
uv sync
uv run streamlit run src/app.py
```

To open the notebooks, run `uv run jupyter lab`.

## Deployment (AWS)

`.github/workflows/cicd.yaml` runs on every push to `main`:

1. **CI**: install from `uv.lock`, lint with ruff, check that the graph builds
2. **Build**: build the Docker image and push it to Amazon ECR
3. **Deploy**: SSH into an EC2 instance, pull the new image and restart the container on port 80

Pull requests run CI only. The workflow can also be started manually from the Actions tab.

## Notes

- Chat history lives in `data/chatbot.db`. Delete it to start fresh; it's recreated automatically.
- Uploading a PDF replaces the single shared index in `faiss_db/`.
- `purchase_stock` is a mock tool. No real trade is ever placed.
