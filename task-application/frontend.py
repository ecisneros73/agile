

tasks =[]

def addTask(all_tasks):
    new_task = input('Add a task: ')
    all_tasks.append(new_task)

    for task in all_tasks:
        print(task)

addTask(tasks)
