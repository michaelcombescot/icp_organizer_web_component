import { Result_1, UserDataSharable } from "../../../../../declarations/backend_todos/backend_todos.did";
import { actor } from "../../../components/auth/auth";

export let APIUser = {
    async getUserData() {
        return actor.getuserData()
    },
}