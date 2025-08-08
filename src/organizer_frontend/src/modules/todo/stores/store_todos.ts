import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo, TodoPriority } from "../../../../../declarations/organizer_backend/organizer_backend.did";
import { actor } from "../../../components/auth/auth";

class StoreTodo {
    //
    // HELPERS
    //

    defTodoPriorities = ["low", "medium", "high"];

    async helperGetTodosByPriority(currentListUUID: string | null): Promise<Todo[]> {
        const todos         = await this.apiGetTodos()
        const priorityTodos = todos.filter((todo) => todo.scheduledDate === BigInt(0) && todo.todoListUUID === currentListUUID)

        return priorityTodos.sort((a, b) => {
            const aLevel = this.defTodoPriorities.indexOf(Object.keys(a.priority)[0] as keyof TodoPriority);
            const bLevel = this.defTodoPriorities.indexOf(Object.keys(b.priority)[0] as keyof TodoPriority);
            return bLevel - aLevel; // descending (high → low)
        })
    }

    async helperGetTodosByScheduledDate(currentListUUID: string | null): Promise<Todo[]> {
        const todos = await this.apiGetTodos()
        const scheduledTodos = todos.filter((todo) => todo.scheduledDate !== BigInt(0) && todo.todoListUUID === currentListUUID)
        return scheduledTodos.sort((a, b) => Number(a.scheduledDate) - Number(b.scheduledDate))
    }

    //
    // API CALLS
    //

    constructor() {}

    async apiGetTodos(fromBackend = false): Promise<Todo[]> {
        return new Promise(async (resolve, reject) => {
            let todos: Todo[] = [];

            if (fromBackend) {
                // const todos = await getTodoFromBackend()
                resolve(todos)
                return
            }

            // get Todos from indexedDB
            const store = DB.transaction([todoStoreName], "readonly").objectStore(todoStoreName);
            const req = store.getAll();

            req.onsuccess = async () => {
                req.result.map((item) => todos.push(item))
                resolve(todos)
            }
            req.onerror = () => { reject(req.error) }
        })
    }

    async apiAddTodo(todo: Todo) : Promise<void> {
        return new Promise(async (resolve, reject) => {
            // save to backend
            await this.apiBackendAddTodo(todo)

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite");
            const req = transaction.objectStore(todoStoreName).add(todo);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) }  
        })
    }

    apiUpdateTodo = async (todo: Todo) : Promise<void> => {
        return new Promise(async (resolve, reject) => {
            // delete from backend
            await this.apiBackendUpdateTodo(todo)

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
            await this.apiBackendDeleteTodo(uuid)

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