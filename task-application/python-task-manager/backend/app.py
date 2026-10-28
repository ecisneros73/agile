"""Python task-manager backend based on the original CLI functions."""
import os
import sqlite3
from contextlib import closing
from flask import Flask, jsonify, request, send_from_directory

app = Flask(__name__, static_folder=None)
DB_PATH = os.environ.get('DATABASE_PATH', '/data/tasks.db')


def connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    with closing(connection()) as conn:
        conn.execute('CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, description TEXT NOT NULL DEFAULT "")')
        conn.commit()


# Original function names, adapted from terminal input()/print() to HTTP + SQLite.
def displayTasks():
    with closing(connection()) as conn:
        return [dict(row) for row in conn.execute('SELECT id, name, description FROM tasks ORDER BY id DESC')]


def addTask(name, description):
    with closing(connection()) as conn:
        cursor = conn.execute('INSERT INTO tasks (name, description) VALUES (?, ?)', (name, description))
        conn.commit()
        return cursor.lastrowid


def editTask(task_id, name, description):
    with closing(connection()) as conn:
        cursor = conn.execute('UPDATE tasks SET name=?, description=? WHERE id=?', (name, description, task_id))
        conn.commit()
        return cursor.rowcount


def removeTask(task_id):
    with closing(connection()) as conn:
        cursor = conn.execute('DELETE FROM tasks WHERE id=?', (task_id,))
        conn.commit()
        return cursor.rowcount


def validate_payload():
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return None, ('JSON object required', 400)
    name, description = payload.get('name'), payload.get('description', '')
    if not isinstance(name, str) or not name.strip():
        return None, ('Task name cannot be empty.', 400)
    if len(name.strip()) > 120:
        return None, ('Task name must be 120 characters or fewer.', 400)
    if not isinstance(description, str) or len(description) > 2000:
        return None, ('Description must be text of 2000 characters or fewer.', 400)
    return (name.strip(), description), None


@app.get('/api/health')
def health():
    return jsonify(status='ok')


@app.get('/api/tasks')
def list_tasks():
    return jsonify(displayTasks())


@app.post('/api/tasks')
def create_task():
    fields, error = validate_payload()
    if error:
        return jsonify(error=error[0]), error[1]
    try:
        task_id = addTask(*fields)
    except sqlite3.IntegrityError:
        return jsonify(error='A task with that name already exists.'), 409
    return jsonify(id=task_id, name=fields[0], description=fields[1]), 201


@app.put('/api/tasks/<int:task_id>')
def update_task(task_id):
    fields, error = validate_payload()
    if error:
        return jsonify(error=error[0]), error[1]
    try:
        updated = editTask(task_id, *fields)
    except sqlite3.IntegrityError:
        return jsonify(error='A task with that name already exists.'), 409
    if not updated:
        return jsonify(error='Task not found.'), 404
    return jsonify(id=task_id, name=fields[0], description=fields[1])


@app.delete('/api/tasks/<int:task_id>')
def delete_task(task_id):
    if not removeTask(task_id):
        return jsonify(error='Task not found.'), 404
    return '', 204


init_db()
