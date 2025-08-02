import { listStoreName, todoStoreName, updateListStoreName, userDataStoreName } from "./store_names";

class OrganizerDB {
    static #name: string = "organizerDB";

    static async init(): Promise<IDBDatabase> {
        return new Promise((resolve, reject) => {
            const req: IDBOpenDBRequest = indexedDB.open(this.#name, 1);
            let db: IDBDatabase

            req.onupgradeneeded = (event: IDBVersionChangeEvent) => {
                db = (event.target as IDBOpenDBRequest).result;
                db.createObjectStore(todoStoreName, { keyPath: "uuid" });
                db.createObjectStore(listStoreName, { keyPath: "uuid" });
                db.createObjectStore(updateListStoreName, { keyPath: "uuid" });
                db.createObjectStore(userDataStoreName, { keyPath: "uuid" });
            };

            req.onsuccess = (event: Event) => {
                db = (event.target as IDBOpenDBRequest).result;
                resolve(db);
            };

            req.onerror = (event: Event) => {
                console.error("IndexedDB error:", (event.target as IDBOpenDBRequest).error);
                reject((event.target as IDBOpenDBRequest).error);
            };
        });
    }
}

// indexedDB.deleteDatabase("organizerDB");

export const DB = await OrganizerDB.init();
