# Agentic Chatbot using LangGraph

An **agentic AI chatbot** built with **Python, LangGraph, LangChain, Google Gemini, Streamlit, FAISS and SQLite**.

It can search the web, do math, check stock prices and the weather, and answer questions about a PDF you upload. Before it makes a (mock) stock purchase, it stops and asks you to approve.

---

## Highlights

- **Multiple conversations**: start new chats and switch between past ones in the sidebar
- **Persistent history**: conversations are saved to SQLite and survive restarts
- **Tool calling**: web search (Tavily), calculator, stock price (Alpha Vantage), current weather (OpenWeather)
- **RAG over your PDF**: upload a PDF, which is chunked, embedded and stored in FAISS, then ask questions about it
- **Human-in-the-loop**: `purchase_stock` pauses the graph with `interrupt()` and resumes with your approve/reject decision
- **Streaming replies** with live tool-call status
- **Docker-ready**, with CI/CD to AWS EC2 through GitHub Actions

---

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

---

## How It Works

```
START ──► chat_node ──(tool call?)──► tools ──┐
              ▲            │                  │
              │            └──(no)──► END     │
              └───────────────────────────────┘
```

`chat_node` calls Gemini with all tools bound. When the model asks for a tool, `tools_condition` routes to the `ToolNode`, and the result goes back to the model. The loop ends when the model answers without calling a tool. A `SqliteSaver` checkpointer stores each thread's state, which lets the human-in-the-loop interrupt pause and resume.

---

## Prerequisites

Make sure you have the following:

- Python 3.11+ (uv can install it for you)
- [uv](https://docs.astral.sh/uv/)
- Git
- Google API key (Gemini)
- Tavily API key (web search)
- OpenWeather API key (weather)
- Alpha Vantage API key (stock prices)

Optional, for deployment:

- Docker
- Docker Hub account
- AWS account
- EC2 instance
- GitHub Actions self-hosted runner

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/ylx959/agentic-chatbot-with-langgraph.git
```

### 2. Navigate to the project directory

```bash
cd agentic-chatbot-with-langgraph
```

### 3. Install dependencies

uv creates the virtual environment and installs the locked dependencies in one step:

```bash
uv sync
```

---

## Environment Variables

Create a `.env` file in the project root directory.

```env
GOOGLE_API_KEY=your_google_api_key
TAVILY_API_KEY=your_tavily_api_key
OPENWEATHER_API_KEY=your_openweather_api_key
ALPHAVANTAGE_API_KEY=your_alphavantage_api_key

LANGSMITH_TRACING=false
LANGSMITH_ENDPOINT=https://api.smith.langchain.com
LANGSMITH_API_KEY=your_langsmith_api_key
LANGSMITH_PROJECT=agentic-chatbot-project
```

If you do not want to use LangSmith tracing, keep:

```env
LANGSMITH_TRACING=false
```

---

## Run Locally

Start the Streamlit app:

```bash
uv run streamlit run src/app.py
```

The app will be available at:

```text
http://localhost:8501
```

---

## Project Structure

```text
agentic-chatbot-with-langgraph/
│
├── src/
│   ├── app.py              # Streamlit UI: chat, threads, PDF upload, HITL approval
│   └── backend.py          # LangGraph graph, tools, RAG, SQLite checkpointer
│
├── examples/               # Standalone CLI / non-streaming demos
├── tests/                  # Streaming smoke test
│
├── .github/workflows/
│   └── cicd.yaml           # CI/CD: build → Docker Hub → deploy on EC2
├── Dockerfile              # Docker image configuration
├── .dockerignore           # Docker ignore rules
├── pyproject.toml          # Dependencies (managed by uv)
├── uv.lock                 # Locked dependency versions
│
├── data/                   # SQLite database (created at runtime)
└── faiss_db/               # FAISS vector index (created at runtime)
```

---

## Docker Deployment

### 1. Build the Docker image

```bash
docker build -t agentic-chatbot .
```

### 2. Run the Docker container

```bash
docker run -d \
  --name agentic-chatbot \
  --restart always \
  -p 8501:8501 \
  --env-file .env \
  -v "$PWD/data:/app/data" \
  -v "$PWD/faiss_db:/app/faiss_db" \
  agentic-chatbot
```

The two `-v` volumes keep chat history and the PDF index after the container stops.

The app will be available at:

```text
http://localhost:8501
```

---

## AWS CI/CD Deployment with GitHub Actions

This project can be deployed to AWS using:

- GitHub Actions
- Docker Hub
- Amazon EC2
- Docker
- GitHub self-hosted runner

---

### 1. Create an IAM User

Log in to the AWS console, create an IAM user for deployment and attach the following policy:

```text
AmazonEC2FullAccess
```

Then create an access key for the user (**Security credentials → Create access key**) and save the key ID and secret for GitHub Secrets.

---

### 2. Create an EC2 Instance

Create an Ubuntu EC2 instance.

Recommended inbound security group rule:

```text
Type: Custom TCP
Port: 8501
Source: 0.0.0.0/0
```

---

### 3. Install Docker on EC2

Connect to your EC2 instance and run:

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
```

Install Docker:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Add the Ubuntu user to the Docker group:

```bash
sudo usermod -aG docker ubuntu
newgrp docker
```

Check Docker:

```bash
docker --version
```

---

### 4. Configure EC2 as a GitHub Self-Hosted Runner

Go to your GitHub repository:

```text
Settings → Actions → Runners → New self-hosted runner
```

Select Linux and follow the commands shown by GitHub.

After setup, start the runner:

```bash
./run.sh
```

`./run.sh` stops when you close the SSH session. To keep the runner alive, configure it as a service:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

---

## GitHub Secrets

Add the following secrets in your GitHub repository:

```text
REGISTRY
DOCKER_USERNAME
DOCKER_PASSWORD
IMAGE_NAME

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION

GOOGLE_API_KEY
TAVILY_API_KEY
OPENWEATHER_API_KEY
ALPHAVANTAGE_API_KEY
OPENAI_API_KEY
LANGSMITH_TRACING
LANGSMITH_ENDPOINT
LANGSMITH_API_KEY
LANGSMITH_PROJECT
```

Path:

```text
GitHub Repository → Settings → Secrets and variables → Actions → New repository secret
```

Example:

```text
REGISTRY=docker.io
IMAGE_NAME=agentic-chatbot
AWS_REGION=us-east-1
LANGSMITH_TRACING=true
LANGSMITH_ENDPOINT=https://api.smith.langchain.com
LANGSMITH_PROJECT=agentic-chatbot-project
```

`DOCKER_USERNAME` is your Docker Hub username. `DOCKER_PASSWORD` is a Docker Hub access token, not your password (**Account settings → Personal access tokens**, Read & Write).

---

## GitHub Actions Workflow

The workflow lives in:

```text
.github/workflows/cicd.yaml
```

On every push to `main`, it will:

1. Build the Docker image
2. Push the image to Docker Hub
3. Pull the latest image on EC2 (self-hosted runner)
4. Stop the old container
5. Run the new container on port `8501`

Once it finishes, open `http://<EC2-public-IP>:8501`.

---

## Usage

After running locally or deploying to AWS:

1. Open the app in your browser.
2. Start chatting with the AI assistant.
3. Attach a PDF in the chat input box to use it as context.
4. Ask questions about the uploaded PDF.
5. Ask about current events, weather or stock prices to trigger the tools.
6. Ask it to buy a stock and approve or reject the purchase.
7. Switch between conversations in the sidebar. History is saved.

---

## Example Questions

```text
Summarize the uploaded PDF.
```

```text
What's the weather in Taipei right now?
```

```text
What is the current price of AAPL?
```

```text
Buy 10 shares of TSLA.
```

```text
Calculate 125 * 48 / 6.
```

---

## Notes

- Do not commit your `.env` file to GitHub.
- Keep API keys inside GitHub Secrets for deployment.
- Make sure port `8501` is open in your EC2 security group.
- Chat history lives in `data/chatbot.db`. Delete it to start fresh; it's recreated automatically.
- Uploading a PDF replaces the single shared index in `faiss_db/`.
- `purchase_stock` is a mock tool. No real trade is ever placed.

---

## Contributing

Contributions are welcome.

To contribute:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Submit a pull request.
