import { todoStoreName } from "./store_names";

class OrganizerDB {
    #db!: IDBDatabase;
    #name: string = "organizerDB";

    async getDB(): Promise<IDBDatabase> {
        if (!this.#db) {
            await this.init();
        }

        return this.#db;
    }

    async init(): Promise<IDBDatabase> {
        return new Promise((resolve, reject) => {
            const request: IDBOpenDBRequest = indexedDB.open(this.#name, 1);

            request.onupgradeneeded = (event: IDBVersionChangeEvent) => {
                this.#db = (event.target as IDBOpenDBRequest).result;
                this.#db.createObjectStore(todoStoreName, { keyPath: "id" });
            };

            request.onsuccess = (event: Event) => {
                this.#db = (event.target as IDBOpenDBRequest).result;
                resolve(this.#db);
            };

            request.onerror = (event: Event) => {
                console.error("IndexedDB error:", (event.target as IDBOpenDBRequest).error);
                reject((event.target as IDBOpenDBRequest).error);
            };
        });
    }
}

export const DB = new OrganizerDB();
