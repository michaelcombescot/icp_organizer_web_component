import { _SERVICE as _SERVICE_INDEX } from '../../../../../declarations/organizerTodosIndex/organizerTodosIndex.did';
import { createActor as createActorIndex } from '../../../../../declarations/organizerTodosIndex';
import { _SERVICE as _SERVICE_BUCKET } from '../../../../../declarations/organizerTodosBucket/organizerTodosBucket.did';
import { createActor as createActorBucket } from '../../../../../declarations/organizerTodosBucket';

import { canisterId as registerID } from '../../../../../declarations/organizerTodosRegistry/index';
import { createActor as createActorTodosRegistry } from '../../../../../declarations/organizerTodosRegistry';

import { ActorSubclass } from '@dfinity/agent';
import { Principal } from '@dfinity/principal';

export let registry = createActorTodosRegistry(registerID);
export var indexesUsers: Principal[] = []

export async function fetchIndexes() {
    indexesUsers = await registry.handlerGetIndexes();
}

/////////////
// INDEXES //
/////////////

// users

export function getIndex() : ActorSubclass<_SERVICE_INDEX> {
    let id = indexesUsers[Math.floor(Math.random() * indexesUsers.length)];
    return createActorIndex(id);
}