// import { updateListStoreName } from "../../../db/store_names";
// import { DB } from "../../../db/db";
// import { Todo, TodoList } from "../../../../../declarations/organizer_backend/organizer_backend.did";

// export type SyncListType =  
//     {"addTodo": Todo} 
//     | {"deleteTodo": string}
//     | {"updateTodo": Todo} 
//     | {"addList": TodoList}
//     | {"deleteList": string} 
//     | {"updateList": TodoList}

// export let syncList: SyncListType[]

// export isConnected = false



// class syncStore {
//     async syncWithBackend() {
//         return new Promise((resolve, reject) => {
//             const store = DB.transaction([updateListStoreName], "readonly").objectStore(updateListStoreName);
//             const req = store.getAll()
//             req.onsuccess = () => resolve(req.result.map((item) => item as UpdateListType))
//             req.onerror = () => reject(req.error);
//         })
//     }

//     getUpdatesList() {
//         return new Promise((resolve, reject) => {
//             const store = DB.transaction([updateListStoreName], "readonly").objectStore(updateListStoreName);
//             const req = store.getAll()
//             req.onsuccess = () => resolve(req.result.map((item) => item as SyncListType))
//             req.onerror = () => reject(req.error);
//         })
//     }
// }

// export const syncStore = new UpdateListStore()

// window.addEventListener("online", () => {
//     listStore.syncWithBackend().then((res) => {
//         updateList = res
//     }).catch((err) => {
//         console.error(err)
//     })
// })