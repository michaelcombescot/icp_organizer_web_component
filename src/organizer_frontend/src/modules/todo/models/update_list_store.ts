import { updateListStoreName } from "../../../db/store_names";
import { DB } from "../../../db/db";
import { UpdateListType } from "./update_list";

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