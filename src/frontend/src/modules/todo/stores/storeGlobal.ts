import { GetUserDataResponse } from "../../../../../declarations/backend_todos/backend_todos.did";
import { actor } from "../../../components/auth/auth"
import { APIUser } from "../apis/apiUsers"

export class StoreGlobal {
    static currentSelectedListId: bigint | null = null

    static updateCurrentSelectedListId(listId: bigint | null) {
        this.currentSelectedListId = listId
    }

    static async loadUserData() {
        await APIUser.getUserData()
    }
}