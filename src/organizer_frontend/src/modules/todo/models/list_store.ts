import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo } from "./todo";
import { ComponentTodoList } from "../components/component_todo_list";
import { TodoPriority } from "./todo";
import { actor } from "../../../components/auth/auth";
import { List } from "./list";
import { listStoreName } from "../../../db/store_names";
import { todoStore } from "./todo_store";

export class ListStore {
    #dbConn: IDBDatabase

    #priorityOrder: Record<keyof TodoPriority, number> = {
        low: 0,
        medium: 1,
        high: 2,
    };

    #getComponentList() { return document.querySelector("#todo-lists-list") as ComponentTodoList }

    constructor(db: IDBDatabase) {
        this.#dbConn = db;
    }

    loadList(listUUID: string) {
        this.#updateUILoadList(listUUID);
    }

    async getList(listUUID: string): Promise<List> {
        const store = this.#dbConn.transaction([listStoreName], "readonly").objectStore(todoStoreName);
        return new Promise((resolve, reject) => {
            // get List
            let reqList = store.get(listUUID);
            let list: List
            reqList.onsuccess = () => list = reqList.result as List;
            reqList.onerror = () => reject(reqList.error);

            // get todos
            todoStore.getTodos().then((todos: Todo[]) => {
                list.todos = todos.filter((todo: Todo) => list.todosUUIDs.includes(todo.uuid));
                resolve(list)
            }).catch((error) => {
                reject(`Failed to get todos in getList:${error}`);
            })
        })
    }

    async addList(todo: Todo) {
        // save to backend
        try {
            await actor.addList(todo);
        } catch (error) {
            console.error("Failed to add todo:", error);
            return
        }

        // add to db
        const store = this.#dbConn.transaction([todoStoreName], "readwrite").objectStore(todoStoreName);
        const req = store.add(todo);
        req.onsuccess = () => {}
        req.onerror = () => { console.error("IndexedDB error:", req.error); }
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

    async #updateUILoadList(listUUID: string) {
        const list = await this.#getList(listUUID)
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

export const listStore = new ListStore(await DB.getDB())