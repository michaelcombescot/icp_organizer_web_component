import { GetUserDataResponse, Result_1 } from "../../../../../declarations/backend_todos/backend_todos.did";
import { actor } from "../../../components/auth/auth";

export let APIUser = {
    getUserData: async function () : Promise<{ ok: GetUserDataResponse; } | { err: Array<string>; }> {
        return actor.getuserData();
    },
}