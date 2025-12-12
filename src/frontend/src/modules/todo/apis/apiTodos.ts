import { getIndex } from "./apiRegistry"
import { createActor as createActorBucket } from '../../../../../declarations/organizerTodosBucket';

export let APIUser = {
    async createUser() : Promise<void> {
        await getIndex().handlerCreateUser()
    },
}