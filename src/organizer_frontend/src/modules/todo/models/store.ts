import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo } from "./todo";
import { TodoListType } from "./todo";
import { ComponentTodoList } from "../components/component_todo_list";
import { ComponentTodo } from "../components/component_todo";

class TodoStore {
    #dbConn: IDBDatabase

    #getComponentListPriority() { return document.querySelector("#todo-list-priority") as ComponentTodoList }
    #getComponentListScheduled() { return document.querySelector("#todo-list-scheduled") as ComponentTodoList }

    constructor(db: IDBDatabase) {
        this.#dbConn = db;
    }

    loadStore() {
        this.#updateTodoUI();
    }

    addTodo(todo: Todo) {
        // add to db
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.add(todo);

        transaction.oncomplete = () => {
            this.#updateTodoUI()
        };
        transaction.onerror = () => {
            console.error("IndexedDB error:", transaction.error);
        };
    }

    deleteTodo(uuid: string) {
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.delete(uuid);

        transaction.oncomplete = () => {
            document.querySelector(`#todo-${uuid}`)!.remove();
        };
        transaction.onerror = () => {
            console.error("IndexedDB error:", transaction.error);
        };
    }

    updateTodo(todo: Todo) {
        // update db
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.put(todo);

        transaction.oncomplete = () => {
            this.#updateTodoUI()
        };
        transaction.onerror = () => {
            console.error("IndexedDB error:", transaction.error);
        };
    }

    async #getTodos(): Promise<Todo[]> {
        return new Promise((resolve, reject) => {
            const transaction = this.#dbConn.transaction([todoStoreName], "readonly");
            const store = transaction.objectStore(todoStoreName);
            const todos: Todo[] = [];

            store.openCursor().onsuccess = (event) => {
                const cursor = (event.target as IDBRequest).result
                if (cursor) {
                    const value = cursor.value as Todo;
                    todos.push(new Todo(cursor.value));
                    cursor.continue();
                }
            };

            transaction.onerror = () => {
                reject(transaction.error);
            };

            transaction.oncomplete = () => {
                resolve(todos);
            }
        });
    }


    // this function handle a reload of everything in the page
    // for a first version it's way easier for handling ordering/editing, especially when the priority or date is changed/removed
    async #updateTodoUI() {
        const todos = await this.#getTodos()
        let priorityTodos: Todo[] = []
        let scheduledTodos: Todo[] = []

        for ( const todo of todos ) {
            if (!todo.scheduledDate) {
                priorityTodos.push(todo)
            } else {
                scheduledTodos.push(todo)
            }
        }

        priorityTodos = this.#sortTodoBypriority(priorityTodos)
        scheduledTodos = this.#sortTodoByDate(scheduledTodos)

        this.#getComponentListPriority().list = priorityTodos
        this.#getComponentListScheduled().list = scheduledTodos
    }

    #sortTodoBypriority(todos: Todo[]) {
        return todos.sort((a, b) => b.priority.valueOf() - a.priority.valueOf())
    }

    #sortTodoByDate(todos: Todo[]) {
        return todos.sort((a, b) => new Date(a.scheduledDate).getTime() - new Date(b.scheduledDate).getTime())
    }
}

export const todoStore = new TodoStore(await DB.getDB())