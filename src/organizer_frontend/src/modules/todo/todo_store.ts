import { todoStoreName } from "../../db/store_names";
import { DB } from "../../db/db";
import { Todo } from "./todo";

class TodoStore {
    #dbConn: IDBDatabase;

    constructor(db: IDBDatabase) {
        this.#dbConn = db;
    }

    addTodo(todo: { id: string; resume: string; description: string; scheduledDate: string; priority: string }): void {
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.add(todo);

        transaction.oncomplete = () => {
            console.log("Todo added to IndexedDB");
        };
        transaction.onerror = () => {
            console.error("IndexedDB error:", transaction.error);
        };
    }

    async getTodos(): Promise<Todo[]> {
        return new Promise((resolve, reject) => {
            const transaction = this.#dbConn.transaction([todoStoreName], "readonly");
            const store = transaction.objectStore(todoStoreName);
            const todos: Todo[] = [];

            store.openCursor().onsuccess = (event) => {
                const cursor = (event.target as IDBRequest).result;
                if (cursor) {
                    todos.push(cursor.value);
                    cursor.continue();
                } else {
                    resolve(todos);
                }
            };

            transaction.onerror = () => {
                reject(transaction.error);
            };
        });
    }

    deleteTodo(id: string): void {
        const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
        const store = transaction.objectStore(todoStoreName);
        store.delete(id);

        transaction.oncomplete = () => {
            console.log("Todo deleted from IndexedDB");
        };
        transaction.onerror = () => {
            console.error("IndexedDB error:", transaction.error);
        };
    }
}

const db = await DB.getDB();
export const todoStore = new TodoStore(await DB.getDB());
