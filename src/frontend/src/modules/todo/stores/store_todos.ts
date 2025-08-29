import { listStoreName, todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo, TodoList, TodoPriority } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { actor } from "../../../components/auth/auth";
import { format } from "path";

export interface TodoWithList extends Todo {
  todoList: TodoList | null
}

class StoreTodo {
    #updateBackend = true

    //
    // HELPERS
    //

    defTodoPriorities = ["low", "medium", "high"];

    helperSortTodosByPriority(todos: Todo[], currentListUUID: string | null): Todo[] {
        const priorityTodos = todos.filter( (todo) => todo.scheduledDate.length === 0 && (!currentListUUID || todo.todoListUUID[0] === currentListUUID) )

        return priorityTodos.sort((a, b) => {
            const aLevel = this.defTodoPriorities.indexOf(Object.keys(a.priority)[0] as keyof TodoPriority);
            const bLevel = this.defTodoPriorities.indexOf(Object.keys(b.priority)[0] as keyof TodoPriority);
            return bLevel - aLevel; // descending (high → low)
        })
    }

    helperSortTodosByScheduledDate(todos: Todo[], currentListUUID: string | null): Todo[] {
        const scheduledTodos = todos.filter( (todo) => todo.scheduledDate.length != 0 && (!currentListUUID || todo.todoListUUID[0] === currentListUUID) )
        return scheduledTodos.sort((a, b) => Number(a.scheduledDate) - Number(b.scheduledDate))
    }

    //
    // API CALLS
    //

    constructor() {}

    async apiGetTodos(): Promise<TodoWithList[]> {
        return new Promise(async (resolve, reject) => {
            let todos: TodoWithList[] = [];

            // get Todos from indexedDB
            const store = DB.transaction([todoStoreName], "readonly").objectStore(todoStoreName);
            const req = store.getAll();

            req.onsuccess = async () => {
                req.result.map((item) => todos.push(item))

                const reqList = DB.transaction([listStoreName], "readonly").objectStore(listStoreName);
                const reqListAll = reqList.getAll();
                reqListAll.onsuccess = async () => {
                    todos.forEach( (todo) => todo.todoList = reqListAll.result.find((list) => list.uuid == todo.todoListUUID[0]) )
                    
                    resolve(todos)
                }
                reqListAll.onerror = () => { reject(reqListAll.error) }
            }
            req.onerror = () => { reject(req.error) }
        })
    }

    async apiAddTodo(todo: Todo) : Promise<void> {
        return new Promise(async (resolve, reject) => {
            // save to backend
            if (this.#updateBackend) { await this.apiBackendAddTodo(todo) } 

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite");
            const req = transaction.objectStore(todoStoreName).add(todo);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) }  
        })
    }

    apiUpdateTodo = async (todo: Todo) : Promise<void> => {
        return new Promise(async (resolve, reject) => {
            // update in backend
            if (this.#updateBackend) { await this.apiBackendUpdateTodo(todo) }

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite");
            const req = transaction.objectStore(todoStoreName).put(todo);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) };  
        })
    }

    apiDeleteTodo = async (uuid: string) : Promise<void> => {
        return new Promise(async (resolve, reject) => {
            // delete from backend
            if (this.#updateBackend) { await this.apiBackendDeleteTodo(uuid) }

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite")
            const req = transaction.objectStore(todoStoreName).delete(uuid);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) };
        })
    }

    apiBackendGetTodos = async () => {
        try {
            return await actor.getTodos();
        } catch (error) {
            console.error("Failed to get todos:", error);
        }
    }

    apiBackendAddTodo = async (todo: Todo) => {
        try {
            await actor.addTodo(todo);
        } catch (error) {
            console.error("Failed to add todo:", error);
        }
    }

    apiBackendUpdateTodo = async (todo: Todo) => {
        try {
            await actor.updateTodo(todo);
        } catch (error) {
            console.error("Failed to update todo:", error);
        }
    }

    apiBackendDeleteTodo = async (uuid: string) => {
        try {
            await actor.removeTodo(uuid);
        } catch (error) {
            console.error("Failed to delete todo:", error);
        }
    }
}

export const storeTodo = new StoreTodo()