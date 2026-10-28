# Task Manager web application

Browser-based implementation of your Python add/list/edit/remove task manager. The site is static HTML/CSS/JavaScript and works with Docker Hardened NGINX, without requiring Python inside the container.

## Run with Docker

```bash
docker build -t task-manager:1.0 .
docker run -d --name task-manager -p 127.0.0.1:8080:8080 task-manager:1.0
curl -I http://localhost:8080
```

Open http://localhost:8080. If port 8080 is already occupied, stop the previous container or use `-p 127.0.0.1:8081:8080` and open http://localhost:8081.

## Features

- Add a task name and description
- List and search tasks
- Edit existing tasks
- Remove tasks with confirmation
- Prevent empty or duplicate task names
- Store tasks locally in the browser using `localStorage`

## Note on persistence

Tasks are stored per browser and site origin, not on the server. If you switch browsers/devices or change origins, the task list may differ. Do not store confidential information in browser local storage. A multi-user app with centralized persistence would require a backend and database.
