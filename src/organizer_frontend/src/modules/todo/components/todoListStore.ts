import { defineStore } from 'pinia';
import { string } from 'simple-cbor/src/value';
import { TodoList } from '../../../../../declarations/organizer_backend/organizer_backend.did';
import { actor } from '../../../components/auth/auth';
import { listStoreName, todoStoreName } from '../../../db/store_names';
import { DB } from '../../../db/db';
import { useTodoStore } from './todoStore';

export const useTodoListStore = defineStore('modal', {
    state: () => ({
        currentListUUID: "" as string,
        lists: [] as TodoList[],
    }),

    actions: {
        async apiGetTodoLists (): Promise<TodoList[]> {
            return new Promise((resolve, reject) => {
                const store = DB.transaction([listStoreName], "readonly").objectStore(listStoreName);
                const req = store.getAll()
                req.onsuccess = () => resolve(req.result.map((item) => item))
                req.onerror = () => reject(req.error);
            })
        },

        async apiGetTodoList (uuid: string): Promise<TodoList> {
            return new Promise((resolve, reject) => {
                const store = DB.transaction([listStoreName], "readonly").objectStore(listStoreName);
                const req = store.get(uuid)
                req.onsuccess = () => resolve(req.result as TodoList)
                req.onerror = () => reject(req.error);
            })
        },

        async apiAddTodoList (list: TodoList): Promise<void> {
            return new Promise((resolve, reject) => {
                // save to backend
                // apiBackendAddList(list)

                // indexedDB
                const store = DB.transaction([listStoreName], "readwrite").objectStore(listStoreName);
                const req = store.add(list);
                req.onsuccess = () => { resolve() }
                req.onerror = () => { reject(req.error) }
            })
        },

        async apiUpdateTodoList (list: TodoList) : Promise<void> {
            return new Promise((resolve, reject) => {
                // save to backend
                // this.apiBackendUpdateList(list)

                // update db
                const store = DB.transaction([listStoreName], "readwrite").objectStore(listStoreName);
                const req = store.put(list);
                req.onsuccess = () => resolve()
                req.onerror = () => reject(req.error)
            })
        },

        async apiDeleteTodoList (uuid: string) : Promise<void> {
            return new Promise(async (resolve, reject) => {
                // delete from backend
                // this.apiBackendDeleteList(uuid)

                // delete from indexedDB, once a list is deleted, all related todos must be deleted
                const transaction = DB.transaction([listStoreName, todoStoreName], "readwrite")
                const listObjStore = transaction.objectStore(listStoreName);
                const todoObjStore = transaction.objectStore(todoStoreName);

                listObjStore.delete(uuid);

                const todos = await useTodoStore().apiGetTodos();
                todos.forEach(todo => {
                    if ( todo.todoListUUID[0] == todo.uuid ) {
                        todoObjStore.delete(todo.uuid);
                    }
                });
                
                transaction.oncomplete = () => resolve();
                transaction.onerror = () => reject(transaction.error);
            })
        },

        async apiBackendGetTodoLists () {
            try {
                return await actor.getTodoLists();
            } catch (error) {
                console.error("Failed to get todo lists:", error);
                return [];
            }
        },

        async apiBackendAddList (list: TodoList) {
            try {
                await actor.addTodoList(list);
            } catch (error) {
                console.error("Failed to add todo:", error);
            }
        },


        async apiBackendUpdateList (list: TodoList) {
            try {
                await actor.updateTodoList(list);
            } catch (error) {
                console.error("Failed to update todo:", error);
            }
        },

        async apiBackendDeleteList (uuid: string) {
            try {
                await actor.removeTodoList(uuid);
            } catch (error) {
                console.error("Failed to delete todo:", error);
            }
        },
    },
});