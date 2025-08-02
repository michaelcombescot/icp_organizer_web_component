import { todoStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo } from "./todo";
import { actor } from "../../../components/auth/auth";
import { listStore } from "./list_store";

class TodoStore {
    constructor() {}

    async getTodos(fromBackend = false): Promise<Todo[]> {
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
                req.result.map((item) => todos.push(new Todo(item)))

                const lists = await listStore.getLists()
                todos.forEach((todo) => todo.list = lists.find((list) => list.uuid === todo.listUUID));

                resolve(todos)
            }
            req.onerror = () => { reject(req.error) }
        })
    }

    async addTodo(todo: Todo) : Promise<void> {
        return new Promise(async (resolve, reject) => {
            // save to backend
            await addTodoTobackend(todo)

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite");
            const req = transaction.objectStore(todoStoreName).add(todo);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) }  
        })
    }

    async updateTodo(todo: Todo) : Promise<void> {
        return new Promise(async (resolve, reject) => {
            // delete from backend
            await updateTodoInBackend(todo)

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite");
            const req = transaction.objectStore(todoStoreName).put(todo);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) };  
        })
    }

    async deleteTodo(uuid: string) : Promise<void> {
        return new Promise(async (resolve, reject) => {
            // delete from backend
            await deleteTodoFromBackend(uuid)

            // indexedDB
            const transaction = DB.transaction([todoStoreName], "readwrite")
            const req = transaction.objectStore(todoStoreName).delete(uuid);
            req.onsuccess = () => { resolve() }
            req.onerror = () => { reject(req.error) };    
        })
    }
}

export const todoStore = new TodoStore()

export const addTodoTobackend = async (todo: Todo) => {
    try {
        await actor.addTodo(todo);
    } catch (error) {
        console.error("Failed to add todo:", error);
    }
}

export const updateTodoInBackend = async (todo: Todo) => {
    try {
        await actor.updateTodo(todo);
    } catch (error) {
        console.error("Failed to update todo:", error);
    }
}

// export const getTodoFromBackend = async (): Promise<Todo[]> => {
//     return new Promise(async (resolve, reject) => {
//         try {
//             const todos = await actor.getTodos();
//             resolve(todos)
//         } catch (error) {
//             console.error("Failed to get todos:", error);
//             reject(error)
//         }
//     })
// }

export const deleteTodoFromBackend = async (uuid: string) => {
    try {
        await actor.removeTodo(uuid);
    } catch (error) {
        console.error("Failed to delete todo:", error);
    }
}