const list = document.getElementById('task-list');
const form = document.getElementById('task-form');
const nameField = document.getElementById('name');
const descriptionField = document.getElementById('description');
const statusField = document.getElementById('status');
const cancel = document.getElementById('cancel');
const search = document.getElementById('search');
let tasks = [];
let editingId = null;
const notice = text => { statusField.textContent = text; };
async function api(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) {
    let data = {};
    try { data = await response.json(); } catch (_) {}
    throw new Error(data.error || `HTTP ${response.status}`);
  }
  return response.status === 204 ? null : response.json();
}
function resetForm() {
  editingId = null;
  form.reset();
  document.getElementById('form-title').textContent = 'Add a task';
  document.getElementById('save').textContent = 'Add task';
  cancel.hidden = true;
}
function render() {
  list.replaceChildren();
  document.getElementById('count').textContent = `(${tasks.length})`;
  const query = search.value.toLowerCase().trim();
  const visible = tasks.filter(t => `${t.name} ${t.description}`.toLowerCase().includes(query));
  if (!visible.length) {
    const li = document.createElement('li'); li.textContent = tasks.length ? 'No matching tasks.' : 'No tasks available.'; list.append(li); return;
  }
  for (const task of visible) {
    const li = document.createElement('li');
    const content = document.createElement('div');
    const title = document.createElement('strong'); title.textContent = task.name;
    const description = document.createElement('p'); description.textContent = task.description || 'No description';
    content.append(title, description);
    const controls = document.createElement('div'); controls.className = 'actions';
    const edit = document.createElement('button'); edit.className = 'secondary'; edit.textContent = 'Edit';
    edit.addEventListener('click', () => { editingId = task.id; nameField.value = task.name; descriptionField.value = task.description; document.getElementById('form-title').textContent = 'Edit task'; document.getElementById('save').textContent = 'Save changes'; cancel.hidden = false; nameField.focus(); });
    const remove = document.createElement('button'); remove.className = 'danger'; remove.textContent = 'Remove';
    remove.addEventListener('click', async () => { if (!confirm(`Remove "${task.name}"?`)) return; try { await api(`/api/tasks/${task.id}`, { method: 'DELETE' }); if (editingId === task.id) resetForm(); await load(); notice('Task removed.'); } catch (error) { notice(error.message); } });
    controls.append(edit, remove); li.append(content, controls); list.append(li);
  }
}
async function load() { tasks = await api('/api/tasks'); render(); }
form.addEventListener('submit', async event => {
  event.preventDefault();
  const name = nameField.value.trim(); if (!name) return;
  try {
    await api(editingId === null ? '/api/tasks' : `/api/tasks/${editingId}`, { method: editingId === null ? 'POST' : 'PUT', headers: {'Content-Type':'application/json'}, body: JSON.stringify({ name, description: descriptionField.value }) });
    resetForm(); await load(); notice('Task saved successfully.');
  } catch (error) { notice(error.message); }
});
cancel.addEventListener('click', resetForm);
search.addEventListener('input', render);
load().catch(error => notice(`Could not reach Python backend: ${error.message}`));
