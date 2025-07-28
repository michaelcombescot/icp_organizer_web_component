import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { ComponentTodoList } from "../components/component_todo_list";
import { TodoPriority } from "./todo";
import { actor } from "../../../components/auth/auth";
import { List } from "./list";
import { listStoreName } from "../../../db/store_names";

export class ListStore {
    constructor() {}

    async getLists(): Promise<List[]> {
        return new Promise((resolve, reject) => {
            const store = DB.transaction([listStoreName], "readonly").objectStore(listStoreName);
            const req = store.getAll()
            req.onsuccess = () => resolve(req.result.map((item) => new List(item)))
            req.onerror = () => reject(req.error);
        })
    }

    async addList(list: List): Promise<void> {
        return new Promise((resolve, reject) => {
            // save to backend
            // try {
            //     await actor.createTodoList(list);
            // } catch (error) {
            //     console.error("Failed to add todo:", error);
            //     return
            // }

            // indexedDB
            const store = DB.transaction([listStoreName], "readwrite").objectStore(listStoreName);
            const req = store.add(list);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) }
        })
    }

    // async deleteTodo(uuid: string) {
    //     // delete from backend
    //     try {
    //         await actor.removeTodo(uuid);
    //     } catch (error) {
    //         console.error("Failed to add todo:", error);
    //         return
    //     }

    //     const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
    //     const store = transaction.objectStore(todoStoreName);
    //     store.delete(uuid);

    //     transaction.oncomplete = () => {
    //         document.querySelector(`#todo-${uuid}`)!.remove();
    //     };
    //     transaction.onerror = () => {
    //         console.error("IndexedDB error:", transaction.error);
    //     };
    // }

    // async updateTodo(todo: Todo) {
    //     // delete from backend
    //     try {
    //         await actor.updateTodo(todo);
    //     } catch (error) {
    //         console.error("Failed to add todo:", error);
    //         return
    //     }

    //     // update db
    //     const transaction = this.#dbConn.transaction([todoStoreName], "readwrite");
    //     const store = transaction.objectStore(todoStoreName);
    //     store.put(todo);

    //     transaction.oncomplete = () => {
    //         this.#updateUI()
    //     };
    //     transaction.onerror = () => {
    //         console.error("IndexedDB error:", transaction.error);
    //     };
    // }
}

export const listStore = new ListStore()