import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { actor } from "../../../components/auth/auth";
import { TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { listStoreName } from "../../../db/store_names";
import { storeTodo } from "./store_todos";

export class StoreTodoList {
    //
    // Methods
    //

    constructor() {}

    static async create(): Promise<StoreTodoList> {
        const store = new StoreTodoList()
        return store
    }


    apiGetTodoLists =  async (): Promise<TodoList[]> => {
        return new Promise((resolve, reject) => {
            const store = DB.transaction([listStoreName], "readonly").objectStore(listStoreName);
            const req = store.getAll()
            req.onsuccess = () => resolve(req.result.map((item) => item))
            req.onerror = () => reject(req.error);
        })
    }

    apiGetTodoList = async (uuid: string): Promise<TodoList> => {
        return new Promise((resolve, reject) => {
            const store = DB.transaction([listStoreName], "readonly").objectStore(listStoreName);
            const req = store.get(uuid)
            req.onsuccess = () => resolve(req.result as TodoList)
            req.onerror = () => reject(req.error);
        })
    }

    apiAddTodoList = async (list: TodoList): Promise<void> => {
        return new Promise((resolve, reject) => {
            // save to backend
            this.apiBackendAddList(list)

            // indexedDB
            const store = DB.transaction([listStoreName], "readwrite").objectStore(listStoreName);
            const req = store.add(list);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) }
        })
    }

    apiUpdateTodoList =  async (list: TodoList) : Promise<void> => {
        return new Promise((resolve, reject) => {
            // save to backend
            this.apiBackendUpdateList(list)

            // update db
            const store = DB.transaction([listStoreName], "readwrite").objectStore(listStoreName);
            const req = store.put(list);
            req.onsuccess = () => resolve()
            req.onerror = () => reject(req.error)
        })
    }

    apiDeleteTodoList = async(uuid: string) : Promise<void>  => {
        return new Promise(async (resolve, reject) => {
            // delete from backend
            this.apiBackendDeleteList(uuid)

            // delete from indexedDB, once a list is deleted, all related todos must be deleted
            const transaction = DB.transaction([listStoreName, todoStoreName], "readwrite")
            const listObjStore = transaction.objectStore(listStoreName);
            const todoObjStore = transaction.objectStore(todoStoreName);

            listObjStore.delete(uuid);

            const todos = await storeTodo.apiGetTodos()
            todos.forEach(todo => {
                if (todo.todoListUUID === uuid) {
                    todoObjStore.delete(todo.uuid);
                }
            });
            
            transaction.oncomplete = () => resolve();
            transaction.onerror = () => reject(transaction.error);
        })
    }

    apiBackendGetTodoLists = async () => {
        try {
            return await actor.getTodoLists();
        } catch (error) {
            console.error("Failed to get todo lists:", error);
            return [];
        }
    }

    apiBackendAddList = async (list: TodoList) => {
        try {
            await actor.addTodoList(list);
        } catch (error) {
            console.error("Failed to add todo:", error);
        }
    }


    apiBackendUpdateList = async (list: TodoList) => {
        try {
            await actor.updateTodoList(list);
        } catch (error) {
            console.error("Failed to update todo:", error);
        }
    }

    apiBackendDeleteList = async (uuid: string) => {
        try {
            await actor.removeTodoList(uuid);
        } catch (error) {
            console.error("Failed to delete todo:", error);
        }
    }
}

export const storeList = await StoreTodoList.create()