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
├── .github/workflows/
│   └── cicd.yaml         # CI/CD: build → Docker Hub → deploy on EC2
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
- **Docker** + **Docker Hub**: containerised deployment
- **GitHub Actions** + **AWS EC2**: CI/CD pipeline with a self-hosted runner

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

## CI/CD Deployment to AWS with GitHub Actions

Every push to `main` runs `.github/workflows/cicd.yaml`, which:

1. Builds a Docker image from the source code
2. Pushes the image to Docker Hub
3. On the EC2 instance (a self-hosted GitHub Actions runner), pulls the image from Docker Hub
4. Runs the container on EC2, serving the app on port `8501`

### 1. Log in to the AWS console

### 2. Create an IAM user for deployment

Attach this policy:

- `AmazonEC2FullAccess`

Then create an access key for the user (**Security credentials → Create access key**) and save the key ID and secret. They go into GitHub Secrets in step 6.

### 3. Launch an EC2 instance (Ubuntu)

In the instance's security group, add an inbound rule: **Custom TCP, port `8501`, source `0.0.0.0/0`**. This is the port Streamlit listens on.

### 4. Install Docker on the EC2 instance

Connect to the instance, then run:

```bash
# Optional
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker
```

### 5. Configure EC2 as a self-hosted runner

On GitHub, go to **Settings → Actions → Runners → New self-hosted runner**, choose **Linux**, then run the commands it shows on the EC2 instance, one by one.

> Tip: `./run.sh` stops when you close the SSH session. To keep the runner alive after you log out, install it as a service instead:
> ```bash
> sudo ./svc.sh install
> sudo ./svc.sh start
> ```

### 6. Add secrets to GitHub Actions

Go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret | Value |
|---|---|
| `REGISTRY` | `docker.io` |
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | A Docker Hub access token (**Account settings → Personal access tokens**, Read & Write) |
| `IMAGE_NAME` | `agentic-chatbot` |
| `AWS_ACCESS_KEY_ID` | Access key ID of the IAM user from step 2 |
| `AWS_SECRET_ACCESS_KEY` | Secret access key of the IAM user from step 2 |
| `AWS_REGION` | e.g. `us-east-1` |
| `OPENAI_API_KEY` | OpenAI API key |
| `TAVILY_API_KEY` | Tavily API key |
| `OPENWEATHER_API_KEY` | OpenWeather API key |
| `GOOGLE_API_KEY` | Google Gemini API key |
| `ALPHAVANTAGE_API_KEY` | Alpha Vantage API key |
| `LANGSMITH_TRACING` | `true` |
| `LANGSMITH_ENDPOINT` | `https://api.smith.langchain.com` |
| `LANGSMITH_API_KEY` | LangSmith API key |
| `LANGSMITH_PROJECT` | `agentic-chatbot-project` |

Once the runner is online and the secrets are set, push to `main` (or run the workflow manually from the **Actions** tab), then open `http://<EC2-public-IP>:8501`.

## Notes

- Chat history lives in `data/chatbot.db`. Delete it to start fresh; it's recreated automatically.
- Uploading a PDF replaces the single shared index in `faiss_db/`.
- `purchase_stock` is a mock tool. No real trade is ever placed.
