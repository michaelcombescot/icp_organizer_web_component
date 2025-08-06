import { updateListStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";

export type UpdateListType =  
    {"addTodo": Todo} 
    | {"deleteTodo": string}
    | {"updateTodo": Todo} 
    | {"addList": TodoList}
    | {"deleteList": string} 
    | {"updateList": TodoList}

export let updateList: UpdateListType[]

class UpdateListStore {
    getUpdatesList() {
        return new Promise((resolve, reject) => {
            const store = DB.transaction([updateListStoreName], "readonly").objectStore(updateListStoreName);
            const req = store.getAll()
            req.onsuccess = () => resolve(req.result.map((item) => item as UpdateListType))
            req.onerror = () => reject(req.error);
        })
    }
}

export const listStore = new UpdateListStore()