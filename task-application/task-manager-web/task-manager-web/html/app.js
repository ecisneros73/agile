'use strict';
const STORAGE_KEY = 'hardened-nginx-task-manager-v1';
const form = document.getElementById('task-form');
const nameInput = document.getElementById('task-name');
const descriptionInput = document.getElementById('task-description');
const list = document.getElementById('task-list');
const emptyState = document.getElementById('empty-state');
const count = document.getElementById('task-count');
const searchInput = document.getElementById('search-tasks');
const submitButton = document.getElementById('submit-task');
const cancelButton = document.getElementById('cancel-edit');
const formTitle = document.getElementById('form-title');
const status = document.getElementById('status');
let tasks = loadTasks();
let editingId = null;

function loadTasks() {
  try {
    const stored = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    return Array.isArray(stored) ? stored.filter(t => t && typeof t.id === 'string' && typeof t.name === 'string' && typeof t.description === 'string') : [];
  } catch { return []; }
}
function persist() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks)); }
  catch { announce('Unable to save tasks. Check your browser storage settings.'); }
}
function announce(message) { status.textContent = message; }
function resetForm() {
  editingId = null;
  form.reset();
  formTitle.textContent = 'Add a task';
  submitButton.textContent = '+ Add task';
  cancelButton.classList.add('hidden');
}
function render() {
  const term = searchInput.value.trim().toLocaleLowerCase();
  const filtered = tasks.filter(t => (t.name + ' ' + t.description).toLocaleLowerCase().includes(term));
  count.textContent = `${tasks.length} ${tasks.length === 1 ? 'task' : 'tasks'}`;
  list.replaceChildren();
  emptyState.classList.toggle('hidden', filtered.length > 0);
  emptyState.textContent = tasks.length === 0 ? 'No tasks available. Add your first task above.' : 'No matching tasks found.';
  filtered.forEach(task => {
    const li = document.createElement('li');
    li.className = 'task-item';
    const body = document.createElement('div');
    body.className = 'task-body';
    const heading = document.createElement('h3');
    heading.className = 'task-name';
    heading.textContent = task.name;
    const description = document.createElement('p');
    description.className = 'task-description';
    description.textContent = task.description || 'No description';
    body.append(heading, description);
    const actions = document.createElement('div');
    actions.className = 'task-buttons';
    const edit = document.createElement('button');
    edit.type = 'button';
    edit.className = 'secondary';
    edit.textContent = 'Edit';
    edit.setAttribute('aria-label', `Edit ${task.name}`);
    edit.addEventListener('click', () => {
      editingId = task.id;
      nameInput.value = task.name;
      descriptionInput.value = task.description;
      formTitle.textContent = 'Edit task';
      submitButton.textContent = 'Save changes';
      cancelButton.classList.remove('hidden');
      form.scrollIntoView({ behavior: 'smooth', block: 'center' });
      nameInput.focus({ preventScroll: true });
    });
    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'danger';
    remove.textContent = 'Remove';
    remove.setAttribute('aria-label', `Remove ${task.name}`);
    remove.addEventListener('click', () => {
      if (!window.confirm(`Remove task "${task.name}"?`)) return;
      tasks = tasks.filter(t => t.id !== task.id);
      if (editingId === task.id) resetForm();
      persist();
      render();
      announce(`Task "${task.name}" removed.`);
    });
    actions.append(edit, remove);
    li.append(body, actions);
    list.append(li);
  });
}
form.addEventListener('submit', event => {
  event.preventDefault();
  const name = nameInput.value.trim();
  const description = descriptionInput.value.trim();
  if (!name) { nameInput.setCustomValidity('Task name cannot be empty.'); nameInput.reportValidity(); return; }
  const duplicate = tasks.some(task => task.name === name && task.id !== editingId);
  if (duplicate) { nameInput.setCustomValidity('A task with that name already exists.'); nameInput.reportValidity(); return; }
  if (editingId !== null) {
    const target = tasks.find(task => task.id === editingId);
    if (target) { target.name = name; target.description = description; announce(`Task "${name}" updated.`); }
  } else {
    tasks.push({ id: crypto.randomUUID(), name, description });
    announce(`Task "${name}" added.`);
  }
  persist();
  resetForm();
  render();
  nameInput.focus();
});
nameInput.addEventListener('input', () => nameInput.setCustomValidity(''));
cancelButton.addEventListener('click', resetForm);
searchInput.addEventListener('input', render);
render();
