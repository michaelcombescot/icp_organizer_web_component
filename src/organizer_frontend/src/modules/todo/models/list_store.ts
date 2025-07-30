import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { actor } from "../../../components/auth/auth";
import { List } from "./list";
import { listStoreName } from "../../../db/store_names";
import { todoStore } from "./todo_store";

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

    async deleteList(uuid: string) : Promise<void> {
        const todos = await todoStore.getTodos();

        return new Promise(async (resolve, reject) => {
            // delete from backend
            // try {
            //     await actor.removeTodo(uuid);
            // } catch (error) {
            //     console.error("Failed to add todo:", error);
            //     return
            // }

            const transaction = DB.transaction([listStoreName, todoStoreName], "readwrite")
            const listObjStore = transaction.objectStore(listStoreName);
            const todoObjStore = transaction.objectStore(todoStoreName);

            listObjStore.delete(uuid);

            todos.forEach(todo => {
                if (todo.listUUID === uuid) {
                    todoObjStore.delete(todo.uuid);
                }
            });
            
            transaction.oncomplete = () => resolve();
            transaction.onerror = () => reject(transaction.error);
        })
    }

    async updateList(list: List) : Promise<void> {
        return new Promise((resolve, reject) => {
             // delete from backend
            // try {
            //     await actor.updateTodo(todo);
            // } catch (error) {
            //     console.error("Failed to add todo:", error);
            //     return
            // }

            // update db
            const store = DB.transaction([listStoreName], "readwrite").objectStore(listStoreName);
            const req = store.put(list);
            req.onsuccess = () => resolve()
            req.onerror = () => reject(req.error)
        })
    }
}

export const listStore = new ListStore()