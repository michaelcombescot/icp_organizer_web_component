import { getIndexGroup } from "./apiRegistry"
import { Result } from "../../../../../declarations/organizerGroupsIndex/organizerGroupsIndex.did";

export let APITodo = {
    async createNewUser(): Promise<Result> {
        return getIndexGroup().handlerCreateNewUser()
    },
}