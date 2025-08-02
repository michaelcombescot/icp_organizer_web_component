import { DB } from "../../db/db";
import { userDataStoreName } from "../../db/store_names";
import { userData } from "./user";

class UserDataStore {
    getUserData() : Promise<userData> {
        return new Promise((resolve, reject) => {
            const store = DB.transaction([userDataStoreName], "readonly").objectStore(userDataStoreName);
            const req = store.get(1);
            req.onsuccess = () => resolve(req.result as userData);
            req.onerror = () => reject(req.error);
        })
    }

    setUserData(userData: userData): Promise<void> {
        return new Promise((resolve, reject) => {
            const store = DB.transaction([userDataStoreName], "readwrite").objectStore(userDataStoreName);
            const req = store.put(userData, 1);
            req.onsuccess = () => resolve();
            req.onerror = () => reject(req.error);
        })
    }
}

export const listStore = new UserDataStore()