
tasks = []
description = {}


# Auxiliary function

def displayTasks(all_tasks, descriptions):
    print('\nYour tasks are:')

    if not all_tasks:
        print('No tasks available.')
        return

    for index, task in enumerate(all_tasks, start=1):
        print(f'{index}. {descriptions.get(task, "No description")}')



# Edit task function
def editTask(all_tasks, descriptions):
    displayTasks(all_tasks, descriptions)

    if not all_tasks:
        return

    try:
        task_index = int(input('Enter the number of the task to edit: ')) - 1
    except ValueError:
        print('Please enter a valid number.')
        return

    if 0 <= task_index < len(all_tasks):
        task_to_edit = all_tasks[task_index]

        new_task_name = input(
            f'Enter new name for "{task_to_edit}": '
        ).strip()

        if not new_task_name:
            print('Task name cannot be empty.')
            return

        if new_task_name != task_to_edit and new_task_name in all_tasks:
            print('A task with that name already exists.')
            return

        new_description = input(
            f'Enter new description for "{new_task_name}": '
        )

        all_tasks[task_index] = new_task_name

        descriptions.pop(task_to_edit, None)
        descriptions[new_task_name] = new_description

        print(f'Task "{task_to_edit}" updated to "{new_task_name}".')
    else:
        print('Invalid task number.')

    displayTasks(all_tasks, descriptions)


# Add task function
def addTask(all_tasks, descriptions):
    new_task = input('Add a task: ').strip()

    if not new_task:
        print('Task name cannot be empty.')
        return

    if new_task in all_tasks:
        print('This task already exists.')
        return

    new_description = input('Enter task description: ')

    all_tasks.append(new_task)
    descriptions[new_task] = new_description

    print(f'Task "{new_task}" added successfully.')

    displayTasks(all_tasks, descriptions)


# Remove task function
def removeTask(all_tasks, descriptions):
    displayTasks(all_tasks, descriptions)

    if not all_tasks:
        return

    try:
        task_index = int(input('Enter the number of the task to remove: ')) - 1
    except ValueError:
        print('Please enter a valid number.')
        return

    if 0 <= task_index < len(all_tasks):
        task_to_remove = all_tasks.pop(task_index)
        descriptions.pop(task_to_remove, None)

        print(f'Task "{task_to_remove}" removed.')
    else:
        print('Invalid task number.')

    displayTasks(all_tasks, descriptions)


# Main function to handle user operations
def newOperation(all_tasks, descriptions):
    while True:
        operation = input(
            '\nChoose A=Add, L=List, E=Edit, R=Remove, F=Quit: '
        ).strip().upper()

        if operation == 'A':
            addTask(all_tasks, descriptions)

        elif operation == 'L':
            displayTasks(all_tasks, descriptions)

        elif operation == 'E':
            editTask(all_tasks, descriptions)

        elif operation == 'R':
            removeTask(all_tasks, descriptions)

        elif operation == 'F':
            print('Exiting...')
            break

        else:
            print('Invalid operation. Please try again.')


# Start application
newOperation(tasks, description)
