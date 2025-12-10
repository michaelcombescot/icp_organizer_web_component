// import { Result_1, UserDataSharable } from "../../../../../declarations/backend_todos/backend_todos.did";
import { Principal } from "@dfinity/principal";

import { getRandomUserIndex } from "./apiRegistry";

export let APIUser = {
    ///////////
    // INDEX //
    ///////////

    async addUser() {
        return createActorIndexTodosUserData( getRandomUserIndex() ).handlerAddUser()
    },

    ////////////
    // BUCKET //
    ////////////
}