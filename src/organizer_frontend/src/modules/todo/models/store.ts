import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo } from "./todo";
import { ComponentTodoList } from "../components/component_todo_list";
import { organizer_backend } from "../../../../../declarations/organizer_backend";
import { TodoPriority } from "./todo";

class TodoStore {
    #dbConn: IDBDatabase

    #priorityOrder: Record<keyof TodoPriority, number> = {
        low: 0,
        medium: 1,
        high: 2,
    };

    #getComponentListPriority() { return document.querySelector("#todo-list-priority") as ComponentTodoList }
    #getComponentListScheduled() { return document.querySelector("#todo-list-scheduled") as ComponentTodoList }

    constructor(db: IDBDatabase) {
        this.#dbConn = db;
    }

    loadStore() {
        this.#updateUI();
    }

    async addTodo(todo: Todo) {
        // save to backend
        try {
            await organizer_backend.addTodo(todo);
        } catch (error) {
            console.error("Failed to add todo:", error);
            return; // Exit the function early
        }

        // add to db
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.add(todo);

        transaction.oncomplete = () => {
            this.#updateUI()
        };
        transaction.onerror = () => {
            console.error("IndexedDB error:", transaction.error);
        };
    }

    async deleteTodo(uuid: string) {
        // delete from backend
        try {
            await organizer_backend.removeTodo(uuid);
        } catch (error) {
            console.error("Failed to add todo:", error);
            return; // Exit the function early
        }

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

    async updateTodo(todo: Todo) {
        // delete from backend
        try {
            await organizer_backend.updateTodo(todo);
        } catch (error) {
            console.error("Failed to add todo:", error);
            return; // Exit the function early
        }

        // update db
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.put(todo);

        transaction.oncomplete = () => {
            this.#updateUI()
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
    // it can probably stay like this forever, I don't think there will be performances issues even whith hundreds of todos
    async #updateUI() {
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
        return todos.sort((a, b) => {
            const aLevel = this.#priorityOrder[Object.keys(a.priority)[0] as keyof TodoPriority];
            const bLevel = this.#priorityOrder[Object.keys(b.priority)[0] as keyof TodoPriority];
            return bLevel - aLevel; // descending (high → low)
        });
    }

    #sortTodoByDate(todos: Todo[]) {
        return todos.sort((a, b) => Number(a.scheduledDate) - Number(b.scheduledDate))
    }
}

export const todoStore = new TodoStore(await DB.getDB())