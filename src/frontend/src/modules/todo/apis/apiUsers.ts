import { getIndexUser } from "./apiRegistry"
import { _SERVICE as _SERVICE_INDEX_TODOS_USERDATA } from '../../../../../declarations/organizerUsersIndex/organizerUsersIndex.did';
import { createActor as createActorIndexTodosUserData } from '../../../../../declarations/organizerUsersIndex';
import { _SERVICE as _SERVICE_BUCKET_TODOS_USERDATA } from '../../../../../declarations/organizerUsersBucket/organizerUsersBucket.did';
import { createActor as createActorBucketTodosUserData } from '../../../../../declarations/organizerUsersBucket';
import { ActorSubclass } from '@dfinity/agent';


export let APIUser = {
    async addUser() : Promise<void> {
        await getIndexUser().handlerAddUser()
    },
}