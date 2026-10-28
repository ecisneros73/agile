# Python Task Manager – Flask + SQLite + Docker Hardened NGINX

The original Python CLI operations (`displayTasks`, `addTask`, `editTask`, `removeTask`) are retained as Python functions in `backend/app.py`, adapted to use SQLite rather than `input()` and `print()`.

## Start

From the project directory:

```bash
docker login dhi.io
docker compose up --build -d
```

Visit **http://localhost:8081**. This avoids your existing port 8080 container.

```bash
docker compose ps
docker compose logs -f
curl http://localhost:8081/api/health
curl http://localhost:8081/api/tasks
```

Stop without deleting stored tasks:

```bash
docker compose down
```

**WARNING:** `docker compose down -v` deletes the task database volume.

## Structure
- `backend/app.py`: Flask API, Python task functions, SQLite database access
- `backend/Dockerfile`: Python runtime container
- `nginx/Dockerfile`: Docker Hardened NGINX reverse proxy and static website
- `nginx/nginx.conf`: NGINX listens on 8080 and proxies `/api/` to Flask
- `frontend/`: Browser UI (HTML/CSS/JavaScript sends requests to Python API)
- `compose.yaml`: two services and persistent SQLite volume

SQLite is stored in a Docker named volume so it persists across container restarts. No authentication is included: this is a local development project. NGINX publishes only on the host loopback interface; VS Code tunnels can separately expose forwarded ports if enabled.

If your existing hardened image uses a different tag, update the `FROM` line in `nginx/Dockerfile`. The `1-debian-dev` tag matches your previous `docker images` output. Docker Hardened Images may require registry authentication.
